//
//  DeviceMonitor.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

// https://github.com/Arti3DPlayer/USBDeviceSwift

import Foundation
import IOKit.hid

class HIDDeviceMonitor {
    public let vp:[HIDMonitorData]
    public let reportSize:Int
    
    public init(_ vp:[HIDMonitorData], reportSize:Int) {
        self.vp = vp
        self.reportSize = reportSize
    }
    
    @objc func start() {
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
        
        let matchingCallback: IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this:HIDDeviceMonitor = unsafeBitCast(inContext, to: HIDDeviceMonitor.self)
            this.rawDeviceAdded(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        
        let removalCallback: IOHIDDeviceCallback = { inContext, inResult, inSender, inIOHIDDeviceRef in
            let this:HIDDeviceMonitor = unsafeBitCast(inContext, to: HIDDeviceMonitor.self)
            this.rawDeviceRemoved(inResult, inSender: inSender!, inIOHIDDeviceRef: inIOHIDDeviceRef)
        }
        IOHIDManagerRegisterDeviceMatchingCallback(managerRef, matchingCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        IOHIDManagerRegisterDeviceRemovalCallback(managerRef, removalCallback, unsafeBitCast(self, to: UnsafeMutableRawPointer.self))
        
        
        RunLoop.current.run()
    }
      
    func rawDeviceAdded(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let device = HIDDevice(device:inIOHIDDeviceRef)
        device.registerInputReportCallback()
        NotificationCenter.default.post(name: .HIDDeviceConnected, object: device)
    }
    
    func rawDeviceRemoved(_ inResult: IOReturn, inSender: UnsafeMutableRawPointer, inIOHIDDeviceRef: IOHIDDevice!) {
        let device = HIDDevice(device:inIOHIDDeviceRef) // this should live enough to avoid remaking the whole struct (impossible)
        device.forget()
        NotificationCenter.default.post(name: .HIDDeviceDisconnected, object: device)
    }
}

extension HIDDevice {
//    public class ReportFilter {
//        static public let defaultFilter = ReportFilter()
//        public typealias ReportFilterClosure = (_ reportId: UInt32, _ report: Data) -> Bool
//        public let closure: ReportFilterClosure
//
//        fileprivate var extraData: Any? // Since we have a whole class just to pass through a closure, we might as well store some context
//
//        init() {
//            print("using blank closure")
//            self.closure = {_,_ in return true}
//        }
//
//        init(closure: @escaping ReportFilterClosure) {
//            print("using custom closure")
//            self.closure = closure
//        }
//    }
//
    private struct ReportStorage {
        static var input = [HIDDevice:UnsafeMutablePointer<UInt8>]()
//        static var filter = [HIDDevice:ReportFilter]()
    }
    
    struct Report {
        let reportData: Data
        let sourceDevice: HIDDevice
    }
    
    internal var inputReport: UnsafeMutablePointer<UInt8> {
        if ReportStorage.input[self] == nil {
            ReportStorage.input[self] = UnsafeMutablePointer<UInt8>.allocate(capacity: self.reportSizeIn)
        }
        return ReportStorage.input[self]!
    }
//
//    public var reportFilter: ReportFilter.ReportFilterClosure {
//        get {
//            return ReportStorage.filter[self]?.closure ?? {_,_ in return true}
//        }
//        set {
//            return ReportStorage.filter[self] = ReportFilter(closure: newValue)
//        }
//    }
    
    static func filter(_ reportId: UInt32, _ report: Data) -> Bool {
        return reportId == 17
    }
    
    func registerInputReportCallback() {
        let inputCallback: IOHIDReportCallback = { context, _, _, _, reportId, report, reportLength in
//            let filter = unsafeBitCast(selfPtr, to: ReportFilterClosure.self)
            let device = Unmanaged<IOHIDDevice>.fromOpaque(context!).takeUnretainedValue()
            let data = Data(bytes: UnsafePointer<UInt8>(report), count: reportLength)
            if HIDDevice.filter(reportId, data) {
                NotificationCenter.default.post(name: .HIDDeviceDataReceived, object: Report(reportData: data, sourceDevice: HIDDevice(device: device)))
            }
        }
        let filterPtr = Unmanaged.passUnretained(self.device).toOpaque() // i'm sorry
        IOHIDDeviceRegisterInputReportCallback(device, inputReport, self.reportSizeIn, inputCallback, filterPtr)
    }
    
    
}
