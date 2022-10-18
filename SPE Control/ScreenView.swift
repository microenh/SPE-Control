//
//  ScreenView.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/28/21.
//

import SwiftUI

struct ScreenView: View {
    var body: some View {
        VStack (spacing: 10) {
            HStack () {
                LeftButtonView()
                ScreenLineView()
                RightButtonView()
            }
        }
    }
}

let buttonWidth = CGFloat(60)

struct LeftButtonView: View {

    @EnvironmentObject var model: Model
    
    var body: some View {
        VStack (alignment: .trailing) {
            HStack {
                ForEach([
                    (text: "INPUT", cmd: SPECommandCode.input),
                    ("ANT", .antenna),
                    ("◁ L", .lDown),
                    ("L ▷", .lUp)], id: \.text) {(text, cmd) in
                        Button(action: {model.command(cmd: cmd)}) {
                            Text(text).frame(width: buttonWidth)
                        }
                    }
            }
            HStack {
                ForEach([
                    (text: "◁ BAND", cmd: SPECommandCode.bandDown),
                    ("BAND ▷", .bandUp),
                    ("◁ C", .cDown),
                    ("C ▷", .cUp)], id: \.text) {(text, cmd) in
                        Button(action: {model.command(cmd: cmd)}) {
                            Text(text).frame(width: buttonWidth)
                        }
                    }
            }
            HStack {
                HStack {
                    ForEach([
                        (text: "AL", flag: model.alarmLED, color: Color.red),
                        ("TUN", model.tuneLED, Color.orange),
                        ("SET", model.setLED, Color.green)
                    ], id: \.text) {(text, flag, color) in
                        VStack {
                            Text(flag ? "􀾜" : "􀲞").foregroundColor(color)
                            Text(text)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                ForEach([
                    (text: "TUNE", cmd: SPECommandCode.tune)], id: \.text) {(text, cmd) in
                        Button(action: {model.command(cmd: cmd)}) {
                            Text(text).frame(width: buttonWidth)
                        }
                    }
            }
        }
        .padding()
        .border(Color.yellow)
    }
}
    

struct RightButtonView: View {
    @EnvironmentObject var model: Model
    @State private var showModal = false
    @State private var shutDown = false
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                ForEach([
                    (text: "DISPLAY", cmd: SPECommandCode.display),
                    ("◁ △", .leftArrow),
                    ("▽ ▷", .rightArrow),
                    ("ON", .switchOn)], id: \.text) {(text, cmd) in
                        Button(action: {model.command(cmd: cmd)}) {
                            Text(text).frame(width: buttonWidth)
                        }
                    }
            }
            HStack {
                ForEach([
                    (text: "POWER", cmd: SPECommandCode.power),
                    ("CAT", .cat),
                    ("SET", .set)], id: \.text) {(text, cmd) in
                        Button(action: {model.command(cmd: cmd)}) {
                            Text(text).frame(width: buttonWidth)
                        }
                    }
                Button(action: {showModal = true}) {
                    Text("OFF").frame(width: buttonWidth)
                }
            }
            HStack {
                ForEach([
                    (text:"OPERATE", cmd: SPECommandCode.operate)], id: \.text) {(text, cmd) in
                        Button(action: {model.command(cmd: cmd)}) {
                            Text(text).frame(width: buttonWidth)
                        }
                    }
                HStack {
                    ForEach([
                        (text: "PWR", flag: model.pwrLED, color: Color.green),
                        ("OP", model.opLED, Color.orange),
                        ("TX", model.txLED, Color.red)
                    ], id: \.text) {(text, flag, color) in
                        VStack {
                            Text(flag ? "􀾜" : "􀲞").foregroundColor(color)
                            Text(text)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .border(Color.yellow)
        .sheet(isPresented: $showModal, onDismiss: {
            if shutDown {
                model.command(cmd: .switchOff)
            }
        }) {
            ModalView(message: "Power off amplifier?", shutDown: $shutDown)
        }
    }
}

struct ModalView: View {
    @Environment(\.presentationMode) var presentation
    let message: String
    @Binding var shutDown: Bool

    var body: some View {
        VStack {
            Text(message)
            Button("Yes") {
                shutDown = true
                self.presentation.wrappedValue.dismiss()
            }
            Button("No") {
                shutDown = false
                self.presentation.wrappedValue.dismiss()
            }
        }
        .padding()
    }
}

/// draw a line from the SPE display.
///
/// model.screenLine is a 8 element array, one for each line of the display screen.
/// Each element is an array of partial lines. The partial lines alternate between
/// normal and inverted text. The first partial line is normal text, although it can
/// be an empty String.

struct ScreenLineView: View {
    @EnvironmentObject var model : Model
    @Environment(\.colorScheme) var colorScheme  // [mee] 11/20/21: added dark/light mode detection
    
    var body: some View {
        VStack (spacing: 0) {
            ForEach(0..<8) {i in
                HStack (spacing: 0){
                    ForEach(0..<model.screenLine[i].count, id: \.self) {j in
                        partialLine(content: model.screenLine[i][j], drawInverted: j % 2 == 1)
                    }
                }
            }
        }
        .frame(width: 300)
        .padding()
        .border(Color.blue)
        .preferredColorScheme(.dark)
    }
    
    func partialLine(content: String, drawInverted: Bool) -> some View {
        return Text(content)
            .font(Font.system(size: 12, design: .monospaced))
            .background(drawInverted != (colorScheme == .light) ? Color.white : Color.clear)
            .foregroundColor(drawInverted != (colorScheme == .light) ? .black : .white)
    }
}

struct ScreenView_Previews: PreviewProvider {
    static var model = Model()
    static var previews: some View {
        ScreenView()
            .environmentObject(model)
    }
}
