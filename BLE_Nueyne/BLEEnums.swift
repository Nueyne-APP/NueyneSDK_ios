//
//  BLEEnums.swift
//  BLEDemo
//
//  Created by Himanshu Sharma on 13/03/24.
//

import Foundation

public enum BLEError: Error {
    case bluetoothPoweredOff
    case deviceNotFound
    case unauthorized
    case unknown
}

enum BLEStates: String , Codable, CaseIterable {
    case poweredOn = "Bluetooth is on, searching for device."
    case poweredOff = "Bluetooth is off."
    case unknown = "Bluetooth state is unknown."
    case resetting = "Bluetooth is resetting"
    case unsuppoorted = "Bluetooth is unsupported."
    case unauthorized = "Bluetooth is not authorised."
}

enum BLEConnectionState: String, Codable, CaseIterable {
    case connected = "Device is connected"
    case disconnected = "Device got disconnected"
}

enum DeviceState: String, Codable, CaseIterable {
    case deviceInfoReceived
    case deviceSelected
}

enum TreatmentTypeTxts: String, Codable, CaseIterable {
    case acuteMode = "Acute Mode"
    case acuteSubtitle = "Strong Pain"
    case preventionMode = "Prevention Mode"
    case preventionSubtitle = "Mild Pain"
}


