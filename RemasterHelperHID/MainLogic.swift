//
//  MainLogic.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation
import IOKit.hid

//var bridge = HIDBridge()
//var CurrentMXDevice: SwiftMxDevice? = nil
//
//func OnDeviceConnected(dev: SwiftMxDevice) {
//    dev.restoreDesiredDPI()
//}
//
//func ConnectDevice(devPath: String, devIndex: Int32) {
//    CurrentMXDevice = nil // this is needed due to a bug, maybe I should fix the memory corruption lol
//                          // if we create a new instance of SwiftMxDevice, the old one doesn't get
//                          // destroyed before the new one is initialized, so we end up with two Dispatchers
//
//    CurrentMXDevice = try? SwiftMxDevice(devPath: devPath, devIndex: devIndex, callback: { dev in
//        OnDeviceConnected(dev: dev)
//        print("Found a new device to handle")
//    })
//}

//extension IOHIDDevice : MouseIdentifier { }

func start() {
    let hidMonitor = HIDDeviceMonitor(RemasterDevice.SupportedDevices, reportSize: 64)
    
    let opQueue = OperationQueue()
    opQueue.name = "Main Monitor Queue"
    opQueue.maxConcurrentOperationCount = 4
    opQueue.underlyingQueue = DispatchQueue.global(qos: .userInitiated)
    
    NotificationCenter.default.addObserver(forName: .HIDDeviceConnected, object: nil, queue: opQueue) { n in
        let device = n.object as! HIDDevice
        print(device.device)
        guard let rawDevice = RemasterDevice(fromMonitorData: device.idPair) else { return }
        if case .Receiver(let type) = rawDevice {
            if let receiver = type.getDriver().init(withHIDDevice: device) {
                print("Receiver: \(receiver.Serial)")
                for i in 0...6 {
                    // this works surprisingly well
                    // but I should implement receiver communication anyway
                    // to make it possible to pair/unpair devices
                    print("receiver, trying index \(i)")
                    guard let m = MxMaster3SDevice(withHIDDevice: device, index: UInt8(i)) else { continue }
                    MouseFactory.sharedInstance.addMouse(m)
                }
            }
        } else {
            guard let driver = rawDevice.getDriver() else { return }
            guard let m = driver.init(withHIDDevice: device, index: 0xff) else { return }
            MouseFactory.sharedInstance.addMouse(m)
        }
    }
    
    NotificationCenter.default.addObserver(forName: .HIDDeviceDisconnected, object: nil, queue: opQueue) { n in
        let device = n.object as! HIDDevice
        for i in [UInt8]([0, 1, 2, 3, 4, 5, 6, 255]) {
            MouseFactory.sharedInstance.removeMouse(withIdentifier: HIDPP.Device.HIDAddress(device: device.device, index: i))
        }
    }
      
    DispatchQueue.global(qos: .utility).async {
        hidMonitor.start()
    }
 
    sleep(500)
//    let x = MouseFactory.mainMouse as! DriverMxMaster3
//    let iodev = x.backingDevice!.hid.device
//
//    let cfElements = IOHIDDeviceCopyMatchingElements(iodev, nil, IOOptionBits(kIOHIDOptionsTypeNone))!
//    
//    let supports0: Bool = false
//    let supports1: Bool = false
//    let supports2: Bool = false
//    
//    func hasReport(r: Int) {
//        
//    }
//    
//    for el in cfElements as! Array<IOHIDElement> {
//        let u = IOHIDElementGetUsagePage(el)
//        if u == 0xff00 || u == 0xff43  {
//            let marker = UInt8(IOHIDElementGetUsage(el) & 0xff)
//        
////            switch marker {
////            case 0:
////
////            case 1: break
////            case 2: break
////            default: break
////            }
//            print()
//        }
//    }

    
}

extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x ", $1)}
    }
}
