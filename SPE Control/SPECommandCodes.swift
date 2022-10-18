//
//  SPECommandCodes.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/27/21.
//

import Foundation

enum SPECommandCode: UInt8 {
    case input = 0x01
    case bandDown = 0x02
    case bandUp = 0x03
    case antenna = 0x04
    case lDown = 0x05
    case lUp = 0x06
    case cDown = 0x07
    case cUp = 0x08
    case tune = 0x09
    case switchOff = 0x0a
    case power = 0x0b
    case display = 0x0c
    case operate = 0x0d
    case cat = 0x0e
    case leftArrow = 0x0f
    case rightArrow = 0x10
    case set = 0x11
    case screenDump = 0x80
    case backlightOn = 0x82
    case backlightOff = 0x83
    case status = 0x90
    
    case switchOn = 0x12   // added, controled by Python code on Raspberry Pi
}
