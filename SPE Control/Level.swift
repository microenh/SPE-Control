//
//  Level.swift
//  LevelMeter2
//
//  Created by Mark Erbaugh on 9/29/21.
//

import SwiftUI

struct Level: View {
    static let segments = 20
    static let maxGreen = 10
    static let maxYellow = 15
    static let segmentSize = CGFloat(12)
    static let cornerSize = CGFloat(2)
    static let opacityOff = 0.1
    static let opacityOn = 0.75
    static let spacing = CGFloat(1)
    
    @State private var segmentsOn = Array(repeating: false, count: segments)
    var value: Int

    private static func getColor(index: Int) -> Color {
        switch index {
        case 0..<maxGreen:
            return .green
        case maxGreen..<maxYellow:
            return .yellow
        default:
            return .red
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: Level.spacing) {
            ForEach(0..<Level.segments) {i in
                Segment(segmentOn: segmentsOn[i], color: Level.getColor(index: i))
            }
        }
        .onChange(of: value) {newValue in
            let intValue = Int(newValue)
            
            for i in 0..<Level.segments {
                segmentsOn[i] = intValue > i
            }
        }
    }
    
    struct Segment: View {
        var segmentOn: Bool
        let color: Color
        
        var body: some View {
            RoundedRectangle(cornerSize: CGSize(width: Level.cornerSize, height: Level.cornerSize))
                .opacity(segmentOn ? Level.opacityOn : Level.opacityOff)
                .foregroundColor(color)
                .frame(width:Level.segmentSize, height:Level.segmentSize)
        }
    }
}

