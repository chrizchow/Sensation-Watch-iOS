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
    mutating func updateState(state: bleStatus)
    mutating func updateDeviceTable()
    
}

// MARK: Model of BLE scanner
class bleScanner: NSObject, CBCentralManagerDelegate {
    
    // MARK: Properties Declaration
    var manager: CBCentralManager?
    var devices = [bleDevice]()
    var status = bleStatus.Bluetooth_STRANGE
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
    
    
    // MARK: - Overriding CoreBluetooth Functions
    //When Bluetooth is switched on/off etc, this would be triggered:
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch manager!.state {
        case CBManagerState.poweredOn:
            status = bleStatus.Bluetooth_ON
            delegate?.updateState(state: status)
            
        case CBManagerState.poweredOff:
            status = bleStatus.Bluetooth_OFF
            delegate?.updateState(state: status)
            
        case CBManagerState.unsupported:
            status = bleStatus.Bluetooth_UNSUPPORTED
            delegate?.updateState(state: status)
            
        default:
            status = bleStatus.Bluetooth_STRANGE
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
                //update RSSI value:
                device.RSSI = RSSI
                //update table:
                delegate?.updateDeviceTable();
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
    
    
    // Calculate the signal percentage of the device
    // we use -30dBm as 100%, and -90dBm as 0%
    static func signalPercentage(device: bleDevice) -> Int{
        // if larger than -30, returns 100:
        if(device.RSSI.intValue > -30){
            return 100
        }
        
        // if smaller than -90, returns 0:
        if(device.RSSI.intValue < -90){
            return 0
        }
        
        // otherwise, do calculation:
        // for example, -30dBm = 100% and -90dBm = 0%
        // their difference is 90-30 = 60
        // this 60 steps will be converted to base of 100
        let baseNumber = -(device.RSSI.intValue + 30)
        return 100 - Int((Float(baseNumber)/(90-30))*100)
    }
    
    
    
}
