//
//  ContentView.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/26/21.
//

import Foundation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var model : Model
    
    init() {
        // reset user changed window size
        #if false
        for key in UserDefaults.standard.dictionaryRepresentation().keys {
            if key.hasPrefix("NSWindow Frame") {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
        #endif
    }
    
    var body: some View {
        VStack (spacing: 2){
            ScreenView()
            // StatusView()
        }
        .padding()
        .fixedSize()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var model = Model()
    static var previews: some View {
        Group {
            ContentView()
                .environmentObject(model)
        }
    }
}
