//
//  BLEManager.swift
//  BLEDemo
//
//  Created by Himanshu Sharma on 11/03/24.
//

import Foundation
import CoreBluetooth


enum DeviceInfoUUIDs: String, Codable, CaseIterable{
    case buildNumber = "E04B1734-C2E3-0001-0001-1A83C19C0D54"
    case internalProtocolVersion = "E04B1734-C2E3-0001-0002-1A83C19C0D54"
    case revisionInformation = "E04B1734-C2E3-0001-0003-1A83C19C0D54"
    case uniqueId = "E04B1734-C2E3-0001-0004-1A83C19C0D54"
    case deviceSettingInfo = "E04B1734-C2E3-0001-0005-1A83C19C0D54"
    
    var  Property: String {
        switch self {
        case .buildNumber: return "Build Number"
        case .deviceSettingInfo: return "Device Setting Info"
        case .internalProtocolVersion: return "Internal Protocol Version"
        case .revisionInformation: return "Revision Information"
        case .uniqueId: return "Unique ID"
        }
    }
}

// Stimulation Data
struct StimulationData {
    var treatmentTime: UInt32  // Total treatment time in seconds
    var elapsedTime: UInt32    // Elapsed time in seconds
    var targetCurrent: UInt16  // Target current in microamperes
    var ongoingCurrentChannel1: UInt16  // Ongoing current from channel 1 in microamperes
    var ongoingCurrentChannel2: UInt16  // Ongoing current from channel 2 in microamperes
    var currentStimulationStep: UInt8   // Current stimulation step
    var treatmentStatus: UInt8          // Device status
    
    var description: String {
            return """
            Stimulation Data:
            Treatment Time: \(treatmentTime) seconds
            Elapsed Time: \(elapsedTime) seconds
            Target Current: \(targetCurrent) µA
            Ongoing Current - Channel 1: \(ongoingCurrentChannel1) µA
            Ongoing Current - Channel 2: \(ongoingCurrentChannel2) µA
            Current Stimulation Step: \(currentStimulationStep)
            Treatment Status: \(treatmentStatus)
            """
        }
}

private enum CurrentStimulationUUIDs: String, Codable, CaseIterable {
    case deviceMonitoring = "E04B1734-C2E3-0002-0002-1A83C19C0D54"
    case controlRequest = "E04B1734-C2E3-0002-0001-1A83C19C0D54"
}

private enum BLEServicesUUID: String, Codable, CaseIterable {
    case deviceInformationServiceUUID = "E04B1734-C2E3-0001-0000-1A83C19C0D54"
    case currestStimulationServiceUUID = "E04B1734-C2E3-0002-0000-1A83C19C0D54"
}

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate,CBPeripheralDelegate {
    
    func testFramework() {
        print("This is BLEManager.from BLE_NUeyne Framework.")
    }
    
    public static let BLEManger = BLEManager()
    let modelName = "BB-60601"
    @Published var centralManager: CBCentralManager! // Bluetooth manager
    @Published var bleState:String = "Idle" // Bluetooth state
    @Published var deviceInfo:[String:String] = [:] // Dictionary to hold device information
    @Published var currentStimulationCharacters:[CBCharacteristic] = [] // Array to hold current stimulation characteristics, will be used to write characteristic later
    @Published var readyToSendCmd:Bool = false
    @Published var monitoringData: StimulationData? = nil
    var peripheral: CBPeripheral? = nil // Peripheral/device instance, will be used to write characteristic
    
    // Private data
    private let masterIntensityControl: UInt8 = 0x00
    private let masterOperatingControl: UInt8 = 0x02
    private let masterModeControl: UInt8 = 0x03
    
    // MARK: Function to initialize Bluetooth Manager
    func initBLE(){
        centralManager = CBCentralManager(delegate: self, queue: nil)
        print("BLE Manager initialised")
    }
    
    // MARK: Function to stop searching
    func stopScanning(){
        if centralManager.isScanning {
            centralManager.stopScan()
        }
    }
    
    
    // MARK: BLE Delegate Functions
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("BLE state updated")
        switch(central.state){
        case .poweredOn:
            print("BLE Powered on")
            bleState = BLEStates.poweredOn.rawValue
            centralManager.scanForPeripherals(withServices: nil,options: nil)
//            centralManager.scanForPeripherals(withServices: [CBUUID(string: BLEServicesUUID.deviceInformationServiceUUID.rawValue),CBUUID(string: BLEServicesUUID.currestStimulationServiceUUID.rawValue)],options: nil)
            print("BLE scanning for device information service uuid")
            break
        case .poweredOff:
            bleState = BLEStates.poweredOff.rawValue
            print("BLE Powered off")
            break
        case .unknown:
            bleState = BLEStates.unknown.rawValue
            print("BLE unknown")
            break
        case .resetting:
            
            bleState = BLEStates.resetting.rawValue
            print("BLE resetting")
            break
        case .unsupported:
            bleState = BLEStates.unsuppoorted.rawValue
            print("BLE unsupported")
            break
        case .unauthorized:
            bleState = BLEStates.unauthorized.rawValue
            print("BLE unauthorised")
            break
        @unknown default:
            break
        }
    }
    
    // MARK: Function that will be called, when a ble device is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("BLE discovered : \(String(describing: peripheral.name))")
        if peripheral.name == nil { return}
        if peripheral.name == modelName {
            // Save instance of peripheral, it will be used to write characteristic later
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            // Found our device, stop scanning
            centralManager.stopScan()
            centralManager.connect(peripheral,options: nil)
            bleState = "Elexir device found, trying to connect with it"
        }
    }
    
    // MARK: Function that will be called when device is connected
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral.name == modelName {
            self.peripheral?.discoverServices([CBUUID(string: BLEServicesUUID.deviceInformationServiceUUID.rawValue),CBUUID(string: BLEServicesUUID.currestStimulationServiceUUID.rawValue)])
//            self.peripheral?.discoverServices([CBUUID(string: BLEServicesUUID.deviceInformationServiceUUID.rawValue)])
            bleState = BLEConnectionState.connected.rawValue
        }
        
    }
    
    // MARK: Just trying device information services for now, later on we need to do it for currentStimilation as well
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
                // This is the Device Information Service, proceed to discover characteristics
                bleState = "Device Information service discovered"
                peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    // MARK: Function that will be called when characteristic for service are found
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        bleState = "Device Information characteristics discovered"
        for characteristic in characteristics {
            // Here you can check for specific characteristics you're interested in
            // If it's a current stimulation service
            if characteristic.service?.uuid == CBUUID(string: BLEServicesUUID.currestStimulationServiceUUID.rawValue){
                currentStimulationCharacters.append(characteristic) // Append characteristic
                if currentStimulationCharacters.count == 4 { // If count is 4 means all characteristics received, ready to send command
                    readyToSendCmd = true
                }
            }
            peripheral.readValue(for: characteristic)
        }
    }
    
    // MARK: Function that will be called when device is disconnected
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        readyToSendCmd = false
        self.peripheral = nil
        deviceInfo = [:]
        currentStimulationCharacters = []
        bleState = BLEConnectionState.disconnected.rawValue
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, timestamp: CFAbsoluteTime, isReconnecting: Bool, error: Error?) {
        if isReconnecting {
            // TODO:
        }else{
            readyToSendCmd = false
            self.peripheral = nil
            deviceInfo = [:]
            currentStimulationCharacters = []
            bleState = BLEConnectionState.disconnected.rawValue
        }
    }
    
    // MARK: Function that will be called when we receive a value for characteristic
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            // TODO: Decode value
            if characteristic.service?.uuid == CBUUID(string: BLEServicesUUID.deviceInformationServiceUUID.rawValue){
                switch (characteristic.uuid){
                case CBUUID(string:DeviceInfoUUIDs.buildNumber.rawValue):
                    deviceInfo[DeviceInfoUUIDs.buildNumber.Property] = String(data: value, encoding: .utf8)
                    break
                case CBUUID(string:DeviceInfoUUIDs.deviceSettingInfo.rawValue):
                    deviceInfo[DeviceInfoUUIDs.deviceSettingInfo.Property] = value.map { String(format: "%02x", $0) }.joined()
                    break
                case CBUUID(string:DeviceInfoUUIDs.internalProtocolVersion.rawValue):
                    deviceInfo[DeviceInfoUUIDs.internalProtocolVersion.Property] = String(data: value, encoding: .utf8)
                    break
                case CBUUID(string:DeviceInfoUUIDs.revisionInformation.rawValue):
                    deviceInfo[DeviceInfoUUIDs.revisionInformation.Property] = String(data: value, encoding: .utf8)
                    break
                case CBUUID(string:DeviceInfoUUIDs.uniqueId.rawValue):
                    deviceInfo[DeviceInfoUUIDs.uniqueId.Property] = String(data: value, encoding: .utf8)
                    break
                default:
                    break
                }
                if deviceInfo.count == characteristic.service?.characteristics?.count {
                    // Done getting info
                    bleState = DeviceState.deviceInfoReceived.rawValue
                }
            }else if characteristic.service?.uuid == CBUUID(string: BLEServicesUUID.currestStimulationServiceUUID.rawValue){
                // TODO: Monitor device
                switch (characteristic.uuid){
                case CBUUID(string: CurrentStimulationUUIDs.deviceMonitoring.rawValue):
                    monitoringData = parseStimulationData(from: value)
                    print(monitoringData?.description ?? "No real data found") // Printing in console
                default: break
                }
            }
        }
    }
    
    // MARK: Function to write command to device
    func writeCommand(toCharacteristic characteristic: CBCharacteristic, onPeripheral peripheral: CBPeripheral, withData data: Data) {
        // Check if the characteristic's properties include writing capability
        if characteristic.properties.contains(.write) {
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        } else if characteristic.properties.contains(.writeWithoutResponse) {
            peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        } else {
            print("Characteristic does not support writing.")
        }
    }
    
    private func parseStimulationData(from data: Data) -> StimulationData? {
        guard data.count >= 16 else {
            print("Data is too short.")
            return nil
        }

        let treatmentTime = data.subdata(in: 0..<4).withUnsafeBytes { $0.load(as: UInt32.self) }
        let elapsedTime = data.subdata(in: 4..<8).withUnsafeBytes { $0.load(as: UInt32.self) }
        let targetCurrent = data.subdata(in: 8..<10).withUnsafeBytes { $0.load(as: UInt16.self) }
        let ongoingCurrentChannel1 = data.subdata(in: 10..<12).withUnsafeBytes { $0.load(as: UInt16.self) }
        let ongoingCurrentChannel2 = data.subdata(in: 12..<14).withUnsafeBytes { $0.load(as: UInt16.self) }
        let currentStimulationStep = data[14]
        let treatmentStatus = data[15]
        
        return StimulationData(
            treatmentTime: UInt32(littleEndian: treatmentTime),
            elapsedTime: UInt32(littleEndian: elapsedTime),
            targetCurrent: UInt16(littleEndian: targetCurrent),
            ongoingCurrentChannel1: UInt16(littleEndian: ongoingCurrentChannel1),
            ongoingCurrentChannel2: UInt16(littleEndian: ongoingCurrentChannel2),
            currentStimulationStep: currentStimulationStep,
            treatmentStatus: treatmentStatus
        )
    }
}


extension BLEManager {
    
    private func sendDeviceCommand(withCommand command: [UInt16],andTwoByteCommand:[UInt8]? = nil, andSingleByteCommand singleByteCommand: UInt8? = nil,masterCommand:UInt8) {
        var commandData = Data()
        commandData.append(masterCommand)
        // Append UInt16 commands
        command.forEach { commandData.append(Data(uint16: $0)) }
        
        // Two byte commands
        if andTwoByteCommand != nil {
            andTwoByteCommand!.forEach{ commandData.append($0)}
        }
        // Append UInt8 command if provided
        if let singleByteCommand = singleByteCommand {
            commandData.append(singleByteCommand)
        }

        if let characteristic = currentStimulationCharacters.first(where: { $0.uuid == CBUUID(string: CurrentStimulationUUIDs.controlRequest.rawValue) }) {
            writeCommand(toCharacteristic: characteristic, onPeripheral: peripheral!, withData: commandData)
        }
    }
    
    func decreaseIntensity(){
        sendDeviceCommand(withCommand: [DeviceCommand.shared.decreaseIntensityCmd, DeviceCommand.shared.dummyByte],masterCommand: masterIntensityControl)
    }
    
    func increaseIntensity(){
        sendDeviceCommand(withCommand: [DeviceCommand.shared.increaseIntensityCmd, DeviceCommand.shared.dummyByte],masterCommand: masterIntensityControl)
    }
    
    func startDevice(mode: String){
        setMode(command: mode == TreatmentTypeTxts.acuteMode.rawValue ? DeviceCommand.shared.treatmentMode1 : DeviceCommand.shared.treatmentMode2) // Setting mode
        sleep(1) // Wait for one second
        sendDeviceCommand(withCommand: [], andSingleByteCommand: DeviceCommand.shared.startDevice,masterCommand: masterOperatingControl) // Start device
    }
    
    func shutdownDevice(){
        sendDeviceCommand(withCommand: [], andSingleByteCommand: DeviceCommand.shared.shutdownDevice,masterCommand: masterOperatingControl)
    }
    
    func setIntensity(value:Int){
        sendDeviceCommand(withCommand: [DeviceCommand.shared.setIntensity,  UInt16(value)],masterCommand: masterIntensityControl)
    }
    
    func setMode(command:UInt8){
        sendDeviceCommand(withCommand: [],andTwoByteCommand: [DeviceCommand.shared.treatmentPayload,command], masterCommand: masterModeControl)
    }
}
