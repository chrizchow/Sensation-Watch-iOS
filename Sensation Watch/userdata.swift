//
//  userdata.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/27/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

import Foundation

class UserData{
    
    private let defaults = UserDefaults.standard
    
    //Computed Property using UserDefault to store Username:
    var username: String {
        get{
            let value = defaults.string(forKey: "name")
            if(value==nil){
                defaults.set("chriz", forKey: "name")
                return "chriz"
            }
            return value!
            
        }
        set(newName){
            let defaults = UserDefaults.standard
            defaults.set(newName, forKey: "name")
            
        }
    }
    
    //Computed Property using UserDefault to store weight:
    var userweight: Float {
        get{
            let value = defaults.float(forKey: "weight")
            if(value==0){
                defaults.set(65.00, forKey: "weight")
                return 65.00
            }
            return value
        }
        
        set(newWeight){
            let defaults = UserDefaults.standard
            defaults.set(newWeight, forKey: "name")
        }
    }
}
