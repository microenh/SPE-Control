//
//  SPE_ControlApp.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/26/21.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct SPE_ControlApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate  // close app when last window closed

    var model = Model(host: "usb.local", port: 50000)
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
