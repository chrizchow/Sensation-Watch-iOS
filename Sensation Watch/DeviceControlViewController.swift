//
//  DeviceControlViewController.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/26/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

import Foundation
import UIKit

class DeviceControlViewController: UIViewController, bleDeviceControlDelegate {
    
    // MARK: - i18n Strings for displaying on UI:
    let str_OK = NSLocalizedString("OK", comment: "okay")
    
    
    override func viewDidLoad() {
        
    }
    
    func updateState(state: bleStatus){
        
    }
    
    func deviceConnectionUpdate(state: connectionStatus){
        
    }
    
    func foundService(success: Bool){
        
    }
    
    func foundCharacteristics(success: Bool){
        
    }
    
    func registeredCharacteristics(){
        
    }
    
    func characteristicUpdated_HeartRate(beatcount: Int){
        
    }
    
    func characteristicUpdated_FootStep(stepcount: Int){
        
    }
    
    
    
}
