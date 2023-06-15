//
//  MainLogic.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation
import IOKit.hid

var bridge = HIDBridge()
var CurrentMXDevice: SwiftMxDevice? = nil

func OnDeviceConnected(dev: SwiftMxDevice) {
    dev.restoreDesiredDPI()
}

func ConnectDevice(devPath: String, devIndex: Int32) {
    CurrentMXDevice = nil // this is needed due to a bug, maybe I should fix the memory corruption lol
                          // if we create a new instance of SwiftMxDevice, the old one doesn't get
                          // destroyed before the new one is initialized, so we end up with two Dispatchers
    
    CurrentMXDevice = try? SwiftMxDevice(devPath: devPath, devIndex: devIndex, callback: { dev in
        OnDeviceConnected(dev: dev)
        print("Found a new device to handle")
    })
}

func start() {
    bridge.setDeviceAddedHandler({path, index in
        let stPath = String(cString: path)
        print("Device connected: \(stPath)@\(index)")
        if (index == 255) { return }
        if (stPath == CurrentMXDevice?.devPath) { return } // this will happen at startup
        ConnectDevice(devPath: stPath, devIndex: index)
    })
    
    bridge.setDeviceRemovedHandler { path, index in
        let stPath = String(cString: path)
        print("Device disconnected: \(stPath), ours is \(CurrentMXDevice?.devPath ?? "nil")")
        if CurrentMXDevice?.devPath == stPath {
            print("Active device has disconnected :(")
            CurrentMXDevice = nil
        }
    }

    DispatchQueue.global(qos: .background).async {
        bridge.bringup() // This blocks
    }

    sleep(1)
    
    print("---------------------- playground")
    
    let SupportedDevices: [HIDMonitorData] = [
        HIDMonitorData(vendorId: 0x046d, productId: 0xb034)
    ]
    let x = HIDDeviceMonitor(SupportedDevices, reportSize: 10)
    
    var y: HIDDevice?
    
    NotificationCenter.default.addObserver(forName: .HIDDeviceConnected, object: nil, queue: nil) { n in
        let device = n.object as! HIDDevice
        y = device
        print("Device Connected (Swift) \(device)")
    }
    
    NotificationCenter.default.addObserver(forName: .HIDDeviceDisconnected, object: nil, queue: nil) { n in
        let device = n.object as! HIDDevice
        print("Device Disconnected (Swift) \(device)")
    }
    
    NotificationCenter.default.addObserver(forName: .HIDDeviceExtraDataReceived(), object: nil, queue: nil) { n in
        let device = n.object as! HIDDevice.Report
        print(device.reportData.base64EncodedString())
    }
    
    DispatchQueue.global(qos: .utility).async {
        x.start()
    }
    
    
    sleep(3)
    print("eee")

    
    if y != nil {
        var hppdev = HIDPP.Device(dev: y!, devIndex: 0)
        print(hppdev.protocolVersion)
    }
    
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
}
