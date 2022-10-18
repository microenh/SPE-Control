//
//  StatusView.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/28/21.
//

import Foundation
import SwiftUI

struct StatusView: View {
    @EnvironmentObject var ampModel: Model
    
    var body: some View {
        VStack {
            Text("Amp: \(ampModel.ampName)")
            Text(ampModel.standbyOperateBool ? "Operate" : "Standby")
            Text(ampModel.receiveTransmitBool ? "Transmit" : "Receive")
            // Text("Memory Bank: \(ampModel.memoryBankString)")
            Text("Band: \(Model.bands[Int(ampModel.band)])")
            // Text("Output power: \(ampModel.outputPower)")
            Text("Warning: \(Model.warningText[ampModel.warning]!)")
            Text("Alarm: \(Model.alarmText[ampModel.alarm]!)")
            Text("iPA: \(Float(ampModel.iPA) * 0.1)")
            Level(value: Int(ampModel.iPA / 2))
            Level(value: Int(ampModel.tempUpper / 5))
        }
    }
}

struct StatusView_Previews: PreviewProvider {
    static var model = Model()
    static var previews: some View {
        StatusView()
            .environmentObject(model)
    }
}
