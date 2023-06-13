//
//  MainLogic.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation

var bridge = HIDBridge()
var CurrentMXDevice: SwiftMxDevice? = nil

var wantedDPI: UInt32 = 1200


func start() {
    bridge.setDeviceAddedHandler({path, index in
        let stPath = String(cString: path)
        print("Device connected: \(stPath)@\(index)")
        if (index != 255 && CurrentMXDevice == nil) {
            CurrentMXDevice = try? SwiftMxDevice(devPath: stPath, devIndex: index)
            print("Found a new device to handle")
        }
    })
    
    bridge.setDeviceRemovedHandler { path, index in
        let stPath = String(cString: path)
        print("Device disconnected: \(stPath)")
        if CurrentMXDevice?.devPath == stPath {
            print("Active device has disconnected :(")
            CurrentMXDevice = nil
        }
    }

    DispatchQueue.global(qos: .background).async {
        bridge.bringup() // This blocks
    }

    sleep(1)

    if (CurrentMXDevice != nil) {
        CurrentMXDevice!.checkDPIAndReport()
    }
    
}
