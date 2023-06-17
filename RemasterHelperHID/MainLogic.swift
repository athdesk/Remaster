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

extension IOHIDDevice : MouseIdentifier { }

func start() {
    let hidMonitor = HIDDeviceMonitor(SupportedDevices, reportSize: 64)

    NotificationCenter.default.addObserver(forName: .HIDDeviceConnected, object: nil, queue: nil) { n in
        let device = n.object as! HIDDevice
        print(device.device)
        guard let driver = RemasterDevice(fromMonitorData: device.idPair)?.getDriver() else { return }
        guard let m = driver.init(withHIDDevice: device, index: 0xff) else { return } // TODO: index hardcoded for now
        MouseFactory.addMouse(withIdentifier: device.device, device: m)
    }
    
    NotificationCenter.default.addObserver(forName: .HIDDeviceDisconnected, object: nil, queue: nil) { n in
        let device = n.object as! HIDDevice
        MouseFactory.removeMouse(withIdentifier: device.device)
    }
      
    DispatchQueue.global(qos: .utility).async {
        hidMonitor.start()
    }
 
    sleep(500)
//    let x = MouseFactory.defaultInstance as! DriverMxMaster3
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
