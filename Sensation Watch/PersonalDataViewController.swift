//
//  PersonalDataViewController.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/27/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

import Foundation
import UIKit

class PersonalDataViewController: UIViewController {
    
    var udObj = UserData()
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var weightField: UITextField!
    let str_SAVE_TITLE = NSLocalizedString("Saved", comment: "save title")
    let str_SAVE_MSG = NSLocalizedString("Your data will be used for notification sending and calories calculation", comment: "save msg")
    
    @IBAction func onClick_save(_ sender: UIButton) {
        udObj.username = usernameField.text!
        udObj.userweight = Float(weightField.text!)!
        showAlertDialog(title: str_SAVE_TITLE, message: str_SAVE_MSG)
    }
    
    override func viewDidLoad() {
        usernameField.text = udObj.username
        weightField.text = "\(udObj.userweight)"
    }
    
    // MARK: Show Message
    func showAlertDialog(title: String, message: String){
        let localOK = NSLocalizedString("OK", comment: "okay for alertbox")
        let alert = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let alertAction = UIAlertAction.init(title: localOK, style: .default, handler: nil)
        alert.addAction(alertAction)
        present(alert, animated: true, completion: nil)
    }
    
    
}
