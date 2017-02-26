//
//  bleStatus.swift
//  Sensation Watch
//
//  Created by Chriz Chow on 2/26/17.
//  Copyright © 2017 Sensation. All rights reserved.
//

// MARK: Types of BLE status in the iDevice
enum bleStatus {
    case Bluetooth_ON, Bluetooth_OFF, Bluetooth_UNSUPPORTED, Bluetooth_STRANGE
}

// MARKL Types of connection status of the watch
enum connectionStatus {
    case connected, failToConnect, disconnected
}
