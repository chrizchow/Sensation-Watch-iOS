//
//  bleScanner.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/25/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

import Foundation
import CoreBluetooth

// MARK: Protocol for other VC to implement
protocol bleScannerDelegate {
    mutating func updateState(state: bleScanner.ScannerStatus)
    mutating func updateDeviceTable()
    
}

// MARK: Model of BLE scanner
class bleScanner: NSObject, CBCentralManagerDelegate {
    
    // MARK: Properties Declaration
    var manager: CBCentralManager?
    var devices = [bleDevice]()
    var status = ScannerStatus.Bluetooth_STRANGE
    var delegate: bleScannerDelegate?
    
    // MARK: Initialization
    func startScanner(){
        manager = CBCentralManager.init(delegate:self, queue:nil, options: nil)
    }
    
    // MARK: - Device Class for Internal Use
    class bleDevice {
        var peripheral: CBPeripheral
        var advertisementData: [String : AnyObject]
        var RSSI: NSNumber
        
        init(peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber){
            self.peripheral = peripheral
            self.advertisementData = advertisementData
            self.RSSI = RSSI
        }
    }
    
    // MARK: Types of status
    enum ScannerStatus {
        case Bluetooth_ON, Bluetooth_OFF, Bluetooth_UNSUPPORTED, Bluetooth_STRANGE
    }
    
    
    // MARK: - Overriding CoreBluetooth Functions
    //When Bluetooth is switched on/off etc, this would be triggered:
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch manager!.state {
        case CBManagerState.poweredOn:
            status = ScannerStatus.Bluetooth_ON
            delegate?.updateState(state: status)
            
        case CBManagerState.poweredOff:
            status = ScannerStatus.Bluetooth_OFF
            delegate?.updateState(state: status)
            
        case CBManagerState.unsupported:
            status = ScannerStatus.Bluetooth_UNSUPPORTED
            delegate?.updateState(state: status)
            
        default:
            status = ScannerStatus.Bluetooth_STRANGE
            delegate?.updateState(state: status)
        }
        
    }
    
    //When BLE device is found, this would be triggered:
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber){
        
        //for debug usage:
        print(peripheral.name ?? "Unknown Device");
        print(advertisementData)
        print(RSSI);
        
        //find its local name instead of default name:
        let localName = advertisementData["kCBAdvDataLocalName"] as? String
        
        //Checking if there's same device inside:
        for device in devices{
            if device.peripheral.isEqual(peripheral){
                device.RSSI = RSSI
                return
            }
        }
        
        //If there's no same device, add it into the devices array
        //only add it if it has local name (not nil)
        if(localName != nil){
            let newDevice =
                bleScanner.bleDevice(peripheral: peripheral, advertisementData: advertisementData as [String : AnyObject], RSSI: RSSI)
            devices.append(newDevice)
        }
        
        //Call the update table delegate:
        delegate?.updateDeviceTable()
        
    }
    
    // MARK: - Encapsulating Device Scan and Stop Scanning
    func startDeviceScanning(){
        if((manager) != nil){
            devices.removeAll() //Clear old record before scanning
            delegate?.updateDeviceTable()
            manager!.scanForPeripherals(withServices: nil, options: nil)
            print("Start Scanning...")
        }
    }
    
    func stopScanning(){
        if((manager) != nil){
            manager!.stopScan()
            devices.removeAll() //clear record when scanning is stopped somehow
            delegate?.updateDeviceTable()
            print("Scanning is stopped...")
        }
    }
    
    
    func clearDevicesTable(){
        devices.removeAll()
        delegate?.updateDeviceTable()
    }
    
    
    
}
