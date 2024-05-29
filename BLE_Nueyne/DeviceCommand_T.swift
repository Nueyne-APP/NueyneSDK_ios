////
////  DeviceCommand_T.swift
////  BLE_Nueyne
////
////  Created by Nueyne devloper on 5/29/24.
////
//
//public enum DeviceCommandType: UInt16 {
//    case increaseIntensity = 0x0001
//    case decreaseIntensity = 0x0002
//    case setIntensity = 0x0000
//}
//
//let startDevice = 0x00
//let treatmentPayload = 0x00
//
//public enum ModeCommandType: UInt8 {
//    case shutdownDevice = 0x04
//    case treatmentMode1 = 0x00
//    case treatmentMode2 = 0x01
//    case treatmentMode3 = 0x02
//}
//
//public protocol DeviceCommandProtocol {
//    static func commandData(for command: DeviceCommandType) -> Data
//    static func modeCommandData(for command: ModeCommandType) -> Data
//}
//
//public final class DeviceCommand: DeviceCommandProtocol {
//    private init() {}
//
//    // Function to return command data
//    public static func commandData(for command: DeviceCommandType) -> Data {
//        return Data(uint16: command.rawValue)
//    }
//
//    // Function to return mode command data
//    public static func modeCommandData(for command: ModeCommandType) -> Data {
//        return Data([command.rawValue])
//    }
//}
//
//extension Data {
//    init(uint16: UInt16) {
//        var bigEndianValue = uint16.bigEndian
//        self.init(bytes: &bigEndianValue, count: MemoryLayout<UInt16>.size)
//    }
//}
