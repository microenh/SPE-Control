//
//  SPEProtocolState.swift
//  SPE Control
//
//  Created by Mark Erbaugh on 9/27/21.
//

import Foundation

enum Protocol: Int {
    case wait0xaa1 = 0
    case wait0xaa2
    case wait0xaa3
    case waitLength
    
    // --------------- ack packet
    case waitACK
    case waitACKCheck
    // --------------- end ack packet

    // --------------- status packet
    // (67 bytes of data)
    case waitStatusCheck1
    case waitStatusCheck2
    // ------------------ end status packet

    // ------------------ screen display packet
    case waitLength2
    case waitLength3
    case waitLength4
    case waitDiscriminator
    // (361 bytes of data)
    case waitDisplayCheck1
    case waitDisplayCheck2
    // ------------------
}
