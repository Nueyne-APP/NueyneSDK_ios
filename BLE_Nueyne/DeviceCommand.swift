
//
//  DeviceCommand.swift
//  BLEDemo
//
//  Created by Himanshu Sharma on 13/03/24.
//

import Foundation

private class DeviceCommand {
    public static let shared = DeviceCommand()
    public init(){}
    
    // Increase intensity command
    let increaseIntensityCmd: UInt16 = 0x0001
    let dummyByte: UInt16 = 0x0000
    
    // Decrease intensity command
    let decreaseIntensityCmd:UInt16 = 0x0002
    
    // Set Intensity command
    let setIntensityCmd: UInt16 = 0x0000
    
    // Start Device
    let startDevice: UInt8 = 0x00
    
    // Shutdown Device
    let shutdownDevice: UInt8 = 0x04
    
    // Set Intensity
    let setIntensity: UInt16 = 0x0000

    // TreatmentMode1
    let treatmentMode1: UInt8 = 0x00
    // TreatmentMode2
    let treatmentMode2: UInt8 = 0x01
    // TreatmentMode3
    let treatmentMode3: UInt8 = 0x02
    // Treatment modepayload
    let treatmentPayload: UInt8 = 0x00
}

extension Data {
    init(uint16: UInt16) {
        var bigEndianValue = uint16.bigEndian
        self.init(bytes: &bigEndianValue, count: MemoryLayout<UInt16>.size)
    }
}
