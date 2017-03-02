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

// MARK: Protocol for other VC to implement
protocol bleDeviceControlDelegate{
    mutating func warnIncompatibleDevice()
    mutating func updateState(state: bleStatus)
    mutating func deviceConnectionUpdate(state: connectionStatus)
    mutating func foundService(success: Bool)
    mutating func foundCharacteristics(success: Bool)
    mutating func registeredCharacteristics()
    mutating func characteristicUpdated_HeartRate(beatcount: Int)
    mutating func characteristicUpdated_FootStep(stepcount: Int)
    mutating func fallDetectionProcessed()
    mutating func updateCalories(value: Float)
}


// MARK: - Business Logic of controlling our BLE watch
class bleDeviceControl: NSObject {
    
    // MARK: - Variable Declaration
    //core location things:
    let locationManager = CLLocationManager()
    //core bluetooth things:
    var manager: CBCentralManager?
    var peripheral: CBPeripheral?
    var deviceConnectionStatus = connectionStatus.disconnected
    //other local variables:
    var peripheralName: String?
    var status = bleStatus.Bluetooth_STRANGE
    var delegate: bleDeviceControlDelegate?
    var epochTimeChar :CBCharacteristic?        //for sync time
    var stepCountChar :CBCharacteristic?        //for step count
    var udobj = UserData();
    var location_lat: String?
    var location_long: String?
    
    // MARK: - Initialization
    func transferManagerPeripheral(manger: CBCentralManager, peripheral: CBPeripheral, peripheralName: String){
        self.manager = manger
        self.peripheral = peripheral
        self.peripheralName = peripheralName
        
    }
    
    // MARK: - Connect / Disconnect the peripheral
    func connectDevice(){
        manager!.delegate = self
        manager!.connect(peripheral!, options: nil)
        
        if(!((peripheralName?.contains("Sensation"))!)){
            delegate?.warnIncompatibleDevice()
        }
    }
    
    func disconnectDevice(){
        //disconnect the device:
        manager!.cancelPeripheralConnection(peripheral!)
        
        //notify the delegate:
        deviceConnectionStatus = connectionStatus.disconnected
        delegate?.deviceConnectionUpdate(state: connectionStatus.disconnected)
    }
    
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
                stepCountChar = characteristic          //remember the characteristic
                peripheral?.readValue(for: characteristic)     //read content inside footstep
                peripheral?.setNotifyValue(true, for: characteristic) //register footstep noti
                print("Reading footstep characteristic value");
                
            }else if(characteristic.uuid == CBUUID.init(string: "FFF7")){
                //Remeber the characteristic and enable timesync buttion:
                epochTimeChar = characteristic
                //synchronizeButton.isEnabled = true
                
            }else if(characteristic.uuid == CBUUID.init(string: "FFF8")){
                //register notification of the "communication handle" characteristic:
                peripheral?.setNotifyValue(true, for: characteristic) //register comm noti
                
            }else{
                print("Not Registered: \(characteristic)")
            }
        }
        
        //notify delegate that this function has run successfully
        delegate?.registeredCharacteristics()
        
    }
    
    // Read stepcount again
    func refreshStepCount(){
        if(stepCountChar != nil){
            peripheral?.readValue(for: stepCountChar!)
            print("Refreshing footstep characteristic value");
        }else{
            print("Cannot read footstep characteristic value");
        }
        
    }
    
    // MARK: - Epoch Time and Time Synchronization for Texas Instruments
    //Get epoch time and convert to 2000 (TI Version)
    func getTiEpochTime() -> UInt32{
        let systemTime = Int(Date().timeIntervalSince1970)
        let secondsDiffFromUTC = TimeZone.current.secondsFromGMT() //get device timezone
        return UInt32(systemTime - 946684800 + secondsDiffFromUTC)
    }
    
    //synchronize device time with device by writing a characteristic
    func syncTime(){
        if(epochTimeChar != nil){
            //convert the UTC time to NSData:
            let epochTimeData :Data = convertInt2NSData(value: getTiEpochTime())
            //write value to BLE device:
            peripheral!.writeValue(epochTimeData,
                                   for: epochTimeChar!,
                                   type: CBCharacteristicWriteType.withResponse)
        }
    }
    
    //call this when fall is triggered:
    func fallDetected(){
        //concat string:
        let link = "http://ihome.ust.hk/~mcchow/cgi-bin/sensation_server.php?username=\(udobj.username)&lat=\(location_lat!)&lng=\(location_long!)"
        print(link) //debug print
        
        //go to URL:
        let url = URL(string: link)
    
        let task = URLSession.shared.dataTask(with: url!)
        task.resume()
        
        //notify delegate:
        delegate?.fallDetectionProcessed()
        
    }
    
    //calculate calories
    func caloriesCalculation(weight: Float, stepCount: Int){
        var temp = 2.20462262 * weight * 0.57
        temp /= 2200;
        temp *= Float(stepCount);
        
        //calcuation is done, notify delegate:
        delegate?.updateCalories(value: temp)
    }
    
    
    // MARK: - Useful Functions for Manipulating NSData
    //Convert a 32-bit integer to NSData with default endianness in Apple (Little in ARM)
    func convertInt2NSData(value: UInt32) -> Data{
        //Convert double to NSData
        let size = MemoryLayout<UInt32>.size
        let intArray: [UInt32] = [value]
        let c = Data(bytes: intArray, count: size)
        
        //NSData to UInt8 array
        /*
         let returnValue = [UInt8](c)
         print("\(returnValue)");
         */
        
        return c
        
    }
    
    func convertNSData2UInt32(data: Data) -> UInt32 {
        return data.withUnsafeBytes { $0.pointee }
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
        deviceConnectionStatus = connectionStatus.connected
        delegate?.deviceConnectionUpdate(state: connectionStatus.connected)
        
        //save the device and put its delegate to this class:
        peripheral.delegate = self
        self.peripheral = peripheral
        
        //disconver service immediately:
        scanRequiredServices()
        
    }
    
    //When BLE device connection is failed, this would be triggered:
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral, error: Error?){
        //print error message:
        print("🙄 Something went wrong... Connection fails")
        print(error ?? "NULL Error String")
        
        //notify delegate:
        deviceConnectionStatus = connectionStatus.failToConnect
        delegate?.deviceConnectionUpdate(state: connectionStatus.failToConnect)
        
    }
    
    //When BLE device is disconnected, this would be triggered:
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?){
        //notify delegate:
        deviceConnectionStatus = connectionStatus.disconnected
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
            scanRequiredCharacteristicsForGivenServices(services: peripheral.services!)
            
            
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
            
            //register some characteristics for notifcations:
            registerSpecificCharacteristics(characteristics: service.characteristics!)

        }
        
    }
    
    //When characteristic is updated, this would be triggered:
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("👅Characheristic Update !")
        if(error == nil){
            //print debug:
            print(characteristic)
            
            //do different things for different characteristic:
            switch(characteristic.uuid){
            case CBUUID.init(string: "2A37"):   //if it is heart rate, update the screen
                let dataArray = [UInt8](characteristic.value!) //heart rate only got 2 bytes
                //notify the delegate about new value:
                delegate?.characteristicUpdated_HeartRate(beatcount: Int(dataArray[0]))
                
            case CBUUID.init(string: "FFF6"):
                let nsdata = characteristic.value!  //step count is uint32
                let stepCount = Int(convertNSData2UInt32(data: nsdata))
                //calculate calories:
                caloriesCalculation(weight: udobj.userweight, stepCount: stepCount)
                //notify the delegate about new value:
                delegate?.characteristicUpdated_FootStep(stepcount: stepCount)
            
            case CBUUID.init(string: "FFF8"):
                //this is notifying fall:
                fallDetected()
                
            default: break
                
            }
            
        }else{
            print("characteristic update error occured.")
        }
    }
    
    //When you register notification successfully, this would be triggered:
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("😎 NotificationState Update !")
        if((error) != nil){
            print("Error Occured: \(error)")
        }
    }
    
}

// MARK: - Implementing CLLocationManagerDelegate Delegates
extension bleDeviceControl: CLLocationManagerDelegate{
    
    //Enable location service:
    func enableLocation(){
        
        //Request Location always:
        self.locationManager.requestAlwaysAuthorization()
        //self.locationManager.requestWhenInUseAuthorization()
        
        //enable location update after enabled:
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }else{
            location_lat = "NA"
            location_long = "NA"
            print("Location Service is not enabled!")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        location_lat = "\(locValue.latitude)"
        location_long = "\(locValue.longitude)"
        print("locations = \(location_lat) \(location_long)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        location_lat = "NA"
        location_long = "NA"
        print("location error: \(error)")
    }
}

