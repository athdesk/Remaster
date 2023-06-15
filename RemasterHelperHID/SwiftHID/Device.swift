//
//  Device.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

// https://github.com/Arti3DPlayer/USBDeviceSwift

import Foundation
import IOKit.hid

public extension Notification.Name {
    static func HIDDeviceDataReceived(_ id: IOHIDDevice? = nil) -> Notification.Name {
        Notification.Name("HIDDeviceDataReceived@\(String(id.hashValue ?? 0))")
    }
    static func HIDDeviceExtraDataReceived(_ id: IOHIDDevice? = nil) -> Notification.Name {
        Notification.Name("HIDDeviceExtraDataReceived@\(String(id.hashValue ?? 0))")
    }

    static let HIDDeviceConnected = Notification.Name("HIDDeviceConnected")
    static let HIDDeviceDisconnected = Notification.Name("HIDDeviceDisconnected")
}

public struct HIDMonitorData {
    public let vendorId: Int
    public let productId: Int
    public var usagePage: Int?
    public var usage: Int?

    public init (vendorId:Int, productId:Int) {
        self.vendorId = vendorId
        self.productId = productId
    }

    public init (vendorId:Int, productId:Int, usagePage:Int?, usage:Int?) {
        self.vendorId = vendorId
        self.productId = productId
        self.usagePage = usagePage
        self.usage = usage
    }
}

private func GenericDeviceGetStringProperty(device: IOHIDDevice, key: String) -> String {
    let value = IOHIDDeviceGetProperty(device, key as CFString)
    return value as? String ?? ""
}

private func GenericDeviceGetIntProperty(device: IOHIDDevice, key: String) -> Int {
    let value = IOHIDDeviceGetProperty(device, key as CFString)
    return value as? Int ?? 0
}

public struct HIDDevice : Hashable {
    static func filter(_ reportId: UInt32, _ report: Data) -> Bool { // doing custom filters is a pain
        return reportId == 17
    }
    struct Report {
        let reportData: Data
        let sourceDevice: HIDDevice
    }
    public let id: Int
    public let vendorId: Int
    public let productId: Int
    public let reportSizeIn: Int
    public let reportSizeOut: Int
    public let device: IOHIDDevice
    public let name: String
    public let notificationName: Notification.Name
    public let notificationNameExtra: Notification.Name
    
    private static var knownDevices = [IOHIDDevice:Self]()

    
    // TODO: make this not static, it's not needed anymore
    private struct ReportStorage {
        static var input = [HIDDevice:UnsafeMutablePointer<UInt8>]()
        static var output = [HIDDevice:UnsafeMutablePointer<UInt8>]()
    }
    
    internal var inputReport: UnsafeMutablePointer<UInt8> {
        if ReportStorage.input[self] == nil {
            ReportStorage.input[self] = UnsafeMutablePointer<UInt8>.allocate(capacity: self.reportSizeIn)
        }
        return ReportStorage.input[self]!
    }
    
    internal var outputReport: UnsafeMutablePointer<UInt8> {
        if ReportStorage.output[self] == nil {
            ReportStorage.output[self] = UnsafeMutablePointer<UInt8>.allocate(capacity: self.reportSizeOut)
        }
        return ReportStorage.output[self]!
    }
    
    public func forget() { // better for this to be manual
        HIDDevice.knownDevices.removeValue(forKey: self.device)
    }
    
    public func writeReport(withData d: Data) -> Bool {
        if d.count > reportSizeOut {
            print("Report size has to be at most \(reportSizeOut) bytes")
            return false
        }
        
        d.copyBytes(to: outputReport, count: min(reportSizeOut, d.count))
        
        let res = IOHIDDeviceSetReport(device,
                             kIOHIDReportTypeOutput,
                             CFIndex(d[0]),
                             outputReport,
                             d.count);
        return res == kIOReturnSuccess
    }

    static public func ==(lhs: HIDDevice, rhs: HIDDevice) -> Bool {
        return lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public init(device: IOHIDDevice) {
        if let instance = HIDDevice.knownDevices[device] {
            self = instance
            return
        }
        self.device = device
        self.id = GenericDeviceGetIntProperty(device: self.device, key: kIOHIDLocationIDKey)
        self.name = GenericDeviceGetStringProperty(device: self.device, key: kIOHIDProductKey)
        self.vendorId = GenericDeviceGetIntProperty(device: self.device, key: kIOHIDVendorIDKey)
        self.productId = GenericDeviceGetIntProperty(device: self.device, key: kIOHIDProductIDKey)
        self.reportSizeIn = GenericDeviceGetIntProperty(device: self.device, key: kIOHIDMaxInputReportSizeKey)
        self.reportSizeOut = GenericDeviceGetIntProperty(device: self.device, key: kIOHIDMaxOutputReportSizeKey)
        self.notificationName =  Notification.Name.HIDDeviceDataReceived(device)
        self.notificationNameExtra = Notification.Name.HIDDeviceExtraDataReceived(device)
        HIDDevice.knownDevices[device] = self
    }
}
