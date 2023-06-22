//
//  DeviceMonitor.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

// https://github.com/Arti3DPlayer/USBDeviceSwift

import Foundation
import IOKit.hid

actor HIDDeviceMonitor {
    public let vp:[HIDMonitorData]
    public let reportSize:Int
    
    public init(_ vp:[HIDMonitorData], reportSize:Int) {
        self.vp = vp
        self.reportSize = reportSize
    }
    
    func start() {
        let managerRef = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        var deviceMatches:[[String:Any]] = []
        for vp in self.vp {
            var match = [kIOHIDProductIDKey: vp.productId, kIOHIDVendorIDKey: vp.vendorId]
            if let usagePage = vp.usagePage {
                match[kIOHIDDeviceUsagePageKey] = usagePage
            }
            if let usage = vp.usage {
                match[kIOHIDDeviceUsageKey] = usage
            }
            deviceMatches.append(match)
        }
        IOHIDManagerSetDeviceMatchingMultiple(managerRef, deviceMatches as CFArray)
        IOHIDManagerScheduleWithRunLoop(managerRef, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue);
        IOHIDManagerOpen(managerRef, IOOptionBits(kIOHIDOptionsTypeNone));
        
        let matchingCallback: IOHIDDeviceCallback = { _, _, _, inIOHIDDeviceRef in
            let device = HIDDevice(device:inIOHIDDeviceRef)
            device.enableNotifications()
            Task { NotificationCenter.default.post(name: .HIDDeviceConnected, object: device) }
        }
        
        let removalCallback: IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let device = HIDDevice(device:inIOHIDDeviceRef)
            Task { NotificationCenter.default.post(name: .HIDDeviceDisconnected, object: device) }
        }
        
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        
        
        RunLoop.current.run()
    }
}

extension HIDDevice {
    // It's better for this to be only called once so it's in an extension
    fileprivate func enableNotifications() {
        let inputCallback: IOHIDReportCallback = { context, _, _, _, reportId, report, reportLength in
            let device = Unmanaged<IOHIDDevice>.fromOpaque(context!).takeUnretainedValue()
            let data = Data(bytes: UnsafePointer<UInt8>(report), count: reportLength)
            if HIDDevice.filter(reportId, data) {
                NotificationCenter.default.post(name: .HIDDeviceExtraDataReceived(device), object: Report(reportData: data, sourceDevice: HIDDevice(device: device)))
            } else {
                NotificationCenter.default.post(name: .HIDDeviceDataReceived(device), object: Report(reportData: data, sourceDevice: HIDDevice(device: device)))
            }
        }
        let filterPtr = Unmanaged.passUnretained(self.device).toOpaque()
        IOHIDDeviceRegisterInputReportCallback(device, inputReport, self.reportSizeIn, inputCallback, filterPtr)
    }
}
