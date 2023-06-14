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
    static let HIDDeviceDataReceived = Notification.Name("HIDDeviceDataReceived")
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
    public let id: Int
    public let vendorId: Int
    public let productId: Int
    public let reportSizeIn: Int
    public let reportSizeOut: Int
    public let device: IOHIDDevice
    public let name: String
    
    private static var knownDevices = [IOHIDDevice:Self]()

    public func forget() { // better for this to be manual
        HIDDevice.knownDevices.removeValue(forKey: self.device)
    }

    public func getStringProperty(key: String) -> String {
        let value = IOHIDDeviceGetProperty(self.device, key as CFString)
        return value as? String ?? ""
    }
    
    public func getIntProperty(key: String) -> Int {
        let value = IOHIDDeviceGetProperty(self.device, key as CFString)
        return value as? Int ?? 0
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
        HIDDevice.knownDevices[device] = self
    }
}
