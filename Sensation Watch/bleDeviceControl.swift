//
//  bleDeviceControl.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/25/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

import Foundation
import CoreLocation
import CoreBluetooth

protocol bleDeviceControlDelegate{
    mutating func updateState(state: bleStatus)
    mutating func deviceConnectionUpdate(state: connectionStatus)
    mutating func foundService(success: Bool)
    mutating func foundCharacteristics(success: Bool)
    mutating func registeredCharacteristics()
    
}


// MARK: - Business Logic of controlling our BLE watch
class bleDeviceControl: NSObject, CLLocationManagerDelegate {
    
    // MARK: - Variable Declaration
    //core location things:
    let locationManager = CLLocationManager()
    //core bluetooth things:
    var manager: CBCentralManager?
    var peripheral: CBPeripheral?
    //other local variables:
    var status = bleStatus.Bluetooth_STRANGE
    var delegate: bleDeviceControlDelegate?
    
    // MARK: - Scanning of services and characteristics
    
    // Scan some required specific services:
    func scanRequiredServices(){
        let uuid_fff0 = CBUUID.init(string: "FFF0")
        let uuid_heart = CBUUID.init(string: "180D")
        let desiredServices = [uuid_fff0, uuid_heart]
        peripheral?.discoverServices(desiredServices)
    }
    
    // Scan some required specific characteristics:
    func scanRequiredCharacteristicsForGivenServices(services: [CBService]){
        for service in services {
            //define a list containing characteristics:
            var desiredChars: [CBUUID] = []
            
            //If it is FFF0, find footstep and utc time:
            if(service.uuid == CBUUID.init(string: "FFF0")){
                //find footstep char here
                let uuid_footstep = CBUUID.init(string: "FFF6")
                desiredChars.append(uuid_footstep)
                //find utc time char here
                let uuid_utctime = CBUUID.init(string: "FFF7")
                desiredChars.append(uuid_utctime)
                
            }
            //If it is heart rate, find heart rate measurement:
            if(service.uuid == CBUUID.init(string: "180D")){
                //find heart rate char here
                let uuid_hrmeasurement = CBUUID.init(string: "2A37")
                desiredChars.append(uuid_hrmeasurement)
                
            }
            //Only fetch the desired characteristics:
            peripheral?.discoverCharacteristics(desiredChars, for: service)
        }
    }
    
    
    // Register notifications for some specific characteristics:
    func registerSpecificCharacteristics(characteristics: [CBCharacteristic]){
        for characteristic in characteristics {
            if(characteristic.uuid == CBUUID.init(string: "2A37")){
                peripheral?.setNotifyValue(true, for: characteristic) //register heart rate noti
                print("Registered: \(characteristic)")
                
            }else if(characteristic.uuid == CBUUID.init(string: "FFF6")){
                peripheral?.readValue(for: characteristic)           //read content inside footstep
                peripheral?.setNotifyValue(true, for: characteristic) //register footstep noti
                print("Reading footstep characteristic value");
                
            }else if(characteristic.uuid == CBUUID.init(string: "FFF7")){
                //Remeber the characteristic and enable timesync buttion:
                //epochTimeChar = characteristic
                //synchronizeButton.isEnabled = true
                
            }else{
                print("Not Registered: \(characteristic)")
            }
        }
    }
    
    
    
    
}

// MARK: - Implementing CBCentralManagerDelegate Delegates
extension bleDeviceControl: CBCentralManagerDelegate{
    
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
    
    //When BLE device is connected, this would be triggered:
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        //Show connected message:
        print("☺️☺️☺️ Connection Established...")
        
        //notify delegate:
        delegate?.deviceConnectionUpdate(state: connectionStatus.connected)
        
        //save the device and put its delegate to this class:
        peripheral.delegate = self
        self.peripheral = peripheral
        
        //disconver service immediately:
        //scanRequiredServices() //TODO: this should be put in elsewhere
        
    }
    
    //When BLE device connection is failed, this would be triggered:
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?){
        //print error message:
        print("🙄 Something went wrong... Connection fails")
        print(error ?? "NULL Error String")
        
        //notify delegate:
        delegate?.deviceConnectionUpdate(state: connectionStatus.failToConnect)
        
    }
    
    //When BLE device is disconnected, this would be triggered:
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?){
        //notify delegate:
        delegate?.deviceConnectionUpdate(state: connectionStatus.disconnected)
    }
    
}


// MARK: - Implementing CBPeripheralDelegate Delegates
extension bleDeviceControl: CBPeripheralDelegate{
    
    //When service is discovered, this would be triggered:
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        print("😍 Discovered Service!")
        if (error == nil) {
            //print debug and notify delegate:
            print(peripheral.services ?? "NULL")
            delegate?.foundService(success: true)
            
            //Try to discover all characteristics in all services
            //scanRequiredCharacteristicsForGivenServices(services: peripheral.services!)
            //TODO: This should be put elsewhere
            
            
        }else{
            //print debug:
            print("🙄 Looks like there're something wrong...")
            print(error ?? "NULL Error String")
            //notify delegate:
            delegate?.foundService(success: false)
        }
    }
    
    //When charactieristic is discovered, this would be triggered:
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        //print debug:
        print("🤓 Oh, Characteristic Found: \(service.uuid)")
        
        if(error == nil){
            //notify delegate:
            delegate?.foundCharacteristics(success: true)
            
            //register:
            registerSpecificCharacteristics(characteristics: service.characteristics!)
        }
        
    }
}

