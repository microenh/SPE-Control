//
//  AmpData.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/27/21.
//

import Foundation
import Network
import SwiftUI

@available(macOS 10.14, *)
final class Model: ObservableObject {
    
    // used for preview
    init() {
        nwConnection = nil
    }
        
    /// initializes model with connection to amplifier.    ///
    /// - parameter host:
    /// name or IP address of the network host.
    /// - parameter port: number of the TCP port.
    init(host: String, port: UInt16) {
        let host = NWEndpoint.Host(host)
        let port = NWEndpoint.Port(rawValue: port)!
        nwConnection = NWConnection(host: host, port: port, using: .tcp)
        nwConnection.stateUpdateHandler = stateDidChange(to:)
        heartBeatTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {timer in
            self.heartBeat()
        }
        setupReceive()
        nwConnection.start(queue: queue)
        clearScreen()
    }
    
    

    // Heartbeat timer
    
    var heartBeatTimer: Timer!
    
    static let toMax = 10
    var toCounter =  toMax
    var screenStatus = false

    @objc func heartBeat() {
        if toCounter == 0 {
            clearScreen()
        } else {
            toCounter -= 1
        }
        command(cmd: screenStatus ? .status : .screenDump)
        // screenStatus = !screenStatus
    }
    
    // Networking
    
    let nwConnection: NWConnection!
    let queue = DispatchQueue(label: "Client connection Q")

    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            break
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    private func setupReceive() {
        nwConnection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                DispatchQueue.main.async {
                    self.process(data: data)
                }
            }
            if isComplete {
                self.connectionDidEnd()
            } else if let error = error {
                self.connectionDidFail(error: error)
            } else {
                self.setupReceive()
            }
        }
    }
    
    private func connectionDidFail(error: Error) {
        // print("connection did fail, error: \(error)")
        stop(error: error)
    }
    
    private func connectionDidEnd() {
        // print("connection did end")
        stop(error: nil)
    }
    
    private func stop(error: Error?) {
        nwConnection.stateUpdateHandler = nil
        nwConnection.cancel()
        if error == nil {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }
    

    
    /// send data to the amplifier
    /// - parameter data: the data to be sent
    func send(data: Data) {
        nwConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
            // print("connection did send, data: \(data as NSData)")
        }))
    }
    
    func command(cmd: SPECommandCode) {
        send(data: Data([0x55, 0x55, 0x55, 0x01, cmd.rawValue, cmd.rawValue]))
    }

    var protocolState = Protocol.wait0xaa1

    var dataBuffer = Array(repeating: UInt8(0), count: 361)
    var bufferIndex = 0
    var totalCheck = UInt16(0)
    var calcCheck1 = UInt8(0)
    
    func process(data: Data) {
        toCounter = Model.toMax
        var nextProtocolState: Protocol
        
        func restart() {
            if nextProtocolState != .wait0xaa1 {
                // print ("Protocol issue: restarting...")
                nextProtocolState = .wait0xaa1
            }
        }
        
        func validAckReceived() {
            // print ("valid ACK: \(dataBuffer[0])")
            nextProtocolState = .wait0xaa1
        }
        
        func validStatusReceived() {
            nextProtocolState = .wait0xaa1
            setStatusData(dataBuffer: dataBuffer)
        }
        
        func validScreenReceived() {
            nextProtocolState = .wait0xaa1
            setScreenData(dataBuffer: dataBuffer)
        }
        
        for c in data {
            if let n = Protocol(rawValue: protocolState.rawValue + 1) {
                nextProtocolState = n
            } else {
                nextProtocolState = .wait0xaa1
            }
            
            switch (protocolState) {
            case .wait0xaa1, .wait0xaa2, .wait0xaa3:
                if c != 0xaa {
                    restart()
                }
            case .waitLength:
                switch (c) {
                case 0x01:
                    nextProtocolState = .waitACK
                case 0x43:
                    nextProtocolState = .waitStatusCheck1
                    totalCheck = 0
                    bufferIndex = 0
                case 0x6a:
                    nextProtocolState = .waitLength2
                default:
                    restart()
                }
            case .waitACK:
                dataBuffer[0] = c
            case .waitACKCheck:
                if c == dataBuffer[0] {
                    validAckReceived()
                } else {
                    restart()
                }
            case .waitStatusCheck1:
                if bufferIndex < 67 {
                    totalCheck += UInt16(c)
                    dataBuffer[bufferIndex] = c
                    bufferIndex += 1
                    nextProtocolState = .waitStatusCheck1
                } else {
                    calcCheck1 = c
                }
            case .waitStatusCheck2:
                if UInt16(calcCheck1) + UInt16(c) << 8 == totalCheck {
                    validStatusReceived()
                } else {
                    restart()
                }
            case .waitLength2:
                if c != 0x01 {
                    restart()
                }
            case .waitLength3:
                if c != 0x95 {
                    restart()
                }
            case .waitLength4:
                if c != 0xfe {  // length = 0x16a, negative length = 0xfe96
                    restart()
                }
            case .waitDiscriminator:
                if c != 0x01 {
                    restart()   // discriminator 0x01
                }
                totalCheck = UInt16(c)
                bufferIndex = 0
            case .waitDisplayCheck1:
                if bufferIndex < 361 {
                    totalCheck += UInt16(c)
                    dataBuffer[bufferIndex] = c
                    bufferIndex += 1
                    nextProtocolState = .waitDisplayCheck1
                } else {
                    calcCheck1 = c
                }
            case .waitDisplayCheck2:
                if UInt16(calcCheck1) + UInt16(c) << 8 == totalCheck {
                    validScreenReceived()
                } else {
                    restart()
                }
            }
            protocolState = nextProtocolState
        }
    }

    
    // Model
    
    static let ampNames = [
        Character("3").asciiValue! : "1.3K",
        Character("5").asciiValue! : "1.5K",
        Character("0").asciiValue! : "2K"
    ]
    
    static let bands = [UInt8(160), 80, 60, 40, 30, 20, 17, 15, 12, 10, 6, 4]
    
    static let warningText = [
        Character("M").asciiValue! : "Alarm Amplifier",
        Character("A").asciiValue! : "No Selected Antenna",
        Character("S").asciiValue! : "SWR Antenna",
        Character("B").asciiValue! : "No Valid Band",
        Character("P").asciiValue! : "Power Limit Exceeded",
        Character("O").asciiValue! : "Overheating",
        Character("Y").asciiValue! : "ATU Not Available",
        Character("W").asciiValue! : "Tuning with No Power",
        Character("K").asciiValue! : "ATU Bypassed",
        Character("R").asciiValue! : "Power Switch Held by Remote",
        Character("T").asciiValue! : "Combiner Overheating",
        Character("C").asciiValue! : "Combiner Fault",
        Character("N").asciiValue! : "No Warnings"
    ]
    
    static let alarmText = [
        Character("S").asciiValue! : "SWR Exceeding Limits",
        Character("A").asciiValue! : "Amplifier Protection",
        Character("D").asciiValue! : "Input Overdriving",
        Character("H").asciiValue! : "Excess Overheating",
        Character("C").asciiValue! : "Combiner Fault",
        Character("N").asciiValue! : "No Alarms"
    ]

    // amplifier screen
    
    @Published var ledStatus = UInt8(0xff)
    @Published var screenLine = [[String()],[String()],[String()],[String()],
                                 [String()],[String()],[String()],[String()]]
    
    /// Clears the screen with default "Waiting for Amplifier" message.
    func clearScreen() {
        ledStatus = 0xff
        for i in 0..<8 {
            screenLine[i] = ["",""]
        }
        screenLine[3] = ["Waiting for amplifier..."]
//        screenLine[3] = ["Waiting ", "for", " amplifier..."]
    }
    
    func setScreenData(dataBuffer: [UInt8]) {
        func convertChar(char: UInt8) -> String {
            switch char {
            case 1..<0x5f:
                return String(UnicodeScalar(char + 0x20))
            case 0x80:
                return "μ"
            case 0x81:
                return "╘"
            case 0x82:
                return "═"
            case 0x83:
                return "╧"
            case 0x84:
                return "╛"
            case 0x85, 0x88, 0x8b:
                return "█"
            case 0x89:
                return "▌"
            case 0x8e:
                return "┬"
            case 0x8f, 0xa1, 0xa4, 0xbb, 0xc7, 0xd1:
                return "│"
            case 0x99, 0x9d:
                return "◁"
            case 0x8d, 0x92, 0x93, 0x9f, 0xa0, 0xb1...0xba, 0xbe, 0xdd...0xdf:
                return "─"
            case 0x9a:
                return "△"
            case 0x9b:
                return "▽"
            case 0x95...0x98:
                return "╫"
            case 0x9c, 0x9e:
                return "▷"
            case 0xa2:
                return "┐"
            case 0xa3:
                return "┘"
            case 0xaa:
                return "°"
            case 0xa5, 0xb0:
                return "┌"
            case 0xa6, 0xdc:
                return "└"
            case 0xae:
                return "✓"
            default:
                return " "
            }
        }
        
        ledStatus = dataBuffer[0]
        
        #if false
        // numeric dump of screen character values
        var output = ""
        for i in 0..<8 {
            output.setString(String(format: "%02x", dataBuffer[40 * i + 1]))
            for j in 0..<40 {
                output.append(" " +  String(format: "%02x", dataBuffer[40 * i + j + 1]))
            }
            print (output)
        }
        #endif
        
        var mask = UInt8(0x01)
        for line in 0..<8 {
            screenLine[line] = []
            var workString = ""
            var prevReverse = false
            
            for j in 0..<40 {
                let doReverse = dataBuffer[j + 321] & mask > 0
                if doReverse != prevReverse {
                    prevReverse = doReverse
                    screenLine[line].append(workString)
                    workString = ""
                }
                workString.append(convertChar(char: dataBuffer[40 * line + j + 1]))
            }
            screenLine[line].append(workString)
            
            mask = mask << 1
        }
    }
    
    var alarmLED : Bool {
        ledStatus & 0x80 == 0
    }
    
    var tuneLED : Bool {
        ledStatus & 0x40 == 0
    }
    
    var setLED : Bool {
        ledStatus & 0x20 == 0
    }
    
    var opLED : Bool {
        ledStatus & 0x10 == 0
    }
    
    var txLED : Bool {
        ledStatus & 0x08 == 0
    }
    
    var pwrLED : Bool {
        ledStatus & 0x04 == 0
    }
    
    // ----------
    // amplifier status
    @Published var ampID = Character("0").asciiValue!
    @Published var standbyOperate = Character("S").asciiValue!
    @Published var receiveTransmit = Character("R").asciiValue!
    @Published var memoryBank = Character("x").asciiValue!
    @Published var input = Character("1").asciiValue!
    @Published var band = UInt8(0)
    @Published var txAntenna = Character("1").asciiValue!
    @Published var atuStatus = Character("a").asciiValue!
    @Published var rxAntenna = Character("0").asciiValue!
    @Published var powerLevel = Character("L").asciiValue!
    @Published var outputPower = UInt16(0)
    @Published var swrATU = UInt16(1)
    @Published var swrAnt = UInt16(1)
    @Published var vPA = UInt16(0)
    @Published var iPA = UInt16(0)
    @Published var tempUpper = UInt8(0)
    @Published var tempLower = UInt8(0)
    @Published var tempCombiner = UInt8(0)
    @Published var warning = Character("N").asciiValue!
    @Published var alarm = Character("N").asciiValue!

    func setStatusData(dataBuffer: [UInt8]) {
        
        func calcUInt(start: Int, length: Int) -> UInt16 {
            var sum = UInt16(0)
            
            for i in start..<start+length {
                let x = dataBuffer[i]
                if x != 32 && x != 46 {  // ignore <space> and "."
                    sum = sum * 10 + UInt16(x - 48)
                }
            }
            return sum
        }
        
        ampID = dataBuffer[2]
        standbyOperate = dataBuffer[5]
        receiveTransmit = dataBuffer[7]
        memoryBank = dataBuffer[9]
        input = dataBuffer[11]
        band = UInt8(calcUInt(start: 13, length: 2))
        txAntenna = dataBuffer[16]
        atuStatus = dataBuffer[17]
        rxAntenna = dataBuffer[19]
        powerLevel = dataBuffer[22]
        outputPower = calcUInt(start: 24, length: 4)
        swrATU = calcUInt(start: 29, length: 5)
        swrAnt = calcUInt(start: 35, length: 5)
        vPA = calcUInt(start: 41, length: 4)
        iPA = calcUInt(start: 46, length: 4)
        // ---
        tempUpper = UInt8(calcUInt(start: 51, length: 3))
        tempLower = UInt8(calcUInt(start: 55, length: 3))
        tempCombiner = UInt8(calcUInt(start: 59, length: 3))
        warning = dataBuffer[63]
        alarm = dataBuffer[65]
    }
    
    var ampName: String {
        "\(Model.ampNames[ampID]!)-FA"
    }
    
    var standbyOperateBool: Bool {
        standbyOperate == Character("O").asciiValue!
    }
    
    var receiveTransmitBool: Bool {
        receiveTransmit == Character("T").asciiValue!
    }
    
    var memoryBankString: String {
        String(bytes: [memoryBank], encoding: .utf8)!
    }
    
    var atuStatusString: String {
        String(bytes: [atuStatus], encoding: .utf8)!
    }
    
    var powerLevelString: String {
        String(bytes: [powerLevel], encoding: .utf8)!
    }
    
}
