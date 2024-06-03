//
//  BluetoothManager.swift
//  BLE_Nueyne
//
//  Created by Nueyne devloper on 6/3/24.
//

import Foundation
import CoreBluetooth

public protocol BluetoothManageable {
    
    func startDevice(mode: String)
    func shutdownDevice()
    func decreaseIntensity()
    func increaseIntensity()
    func setMode(command:UInt8)
    var delegate: BluetoothManagerDelegate? { get set }
    
    // Is it essesntial in protocol under 2 things?
    func sendDeviceCommand(withCommand command: [UInt16],andTwoByteCommand:[UInt8], andSingleByteCommand singleByteCommand: UInt8,masterCommand:UInt8)
    func initBLE()
}

public protocol BluetoothManagerDelegate: AnyObject {
    func didDiscoverPeripheral(peripheral: CBPeripheral, advertisementData: [String: Any], rssi: NSNumber)
        func didConnectToPeripheral(peripheral: CBPeripheral)
        func didFailToConnectPeripheral(peripheral: CBPeripheral, error: Error?)
        func didDiscoverServices(peripheral: CBPeripheral)
        func didDiscoverCharacteristics(peripheral: CBPeripheral, service: CBService)
        func didUpdateValueForCharacteristic(peripheral: CBPeripheral, characteristic: CBCharacteristic, value: Data?)
}

