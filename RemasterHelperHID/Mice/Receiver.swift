//
//  Receiver.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 22/06/23.
//

import Foundation



enum ReceiverType : CaseIterable {
    case Bolt
    case Unifying
    
    func getIconName() -> String {
        switch self {
        case .Bolt: return "bolt"
        case .Unifying: return "rays"
        }
    }
    
    func getDriver() -> (any Receiver.Type) {
        switch self {
        case .Bolt: return BoltReceiver.self
        case .Unifying: return UnifyingReceiver.self
        }
    }
}

protocol Receiver {
    var type: ReceiverType { get }
    var hid: HIDDevice { get }
    
    var Serial: String { get }
    var MaxDevices: Int { get }
    
    init?(withHIDDevice d: HIDDevice)
}

class UnifyingReceiver : Receiver {
    let type = ReceiverType.Unifying
    let hid: HIDDevice
    
    let backingDevice: HIDPP.Device
    
    var Serial: String { abort() }
    var MaxDevices: Int { abort () }
    
    required init?(withHIDDevice d: HIDDevice) {
        guard let dev = HIDPP.Device(dev: d, devIndex: 0xff) else { return nil }
        self.hid = d
        self.backingDevice = dev
    }
}
    
class BoltReceiver : Receiver {
    typealias Proto = HIDPP.v10
    let type = ReceiverType.Bolt
    let hid: HIDDevice
    let backingDevice: HIDPP.Device
    
    private var observers: [NSObjectProtocol] = []
    
    let Serial: String
    let MaxDevices: Int = 6
    
    // TODO: make this a sequential queue
    var ReceiverConnectedHandler: EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError20 == false {
            let data = ppReport.parameters
            let connected = (data[0] & 0x40 == 0)
            let prodId = UInt16([UInt8](data[1..<3])) ?? 0
            let index = ppReport.deviceIndex
            
            Task {
                if connected {
                    await self.TryConnectDevice(productId: prodId, index: index)
                } else {
                    await MouseTracker.global.removeMouse(withHid: self.backingDevice.hid, index: index)
                }
                
                print("[I] Device with product id \(String(format:"%02X", prodId))", connected ? "connected" : "disconnected")
            }
        }
    }}
    
    private func TryConnectDevice(productId pid: UInt16, index: UInt8) async {
        guard let deviceDescriptor =  RemasterDevice(fromMonitorData: HIDMonitorData(
            vendorId: self.backingDevice.hid.vendorId,
            productId: Int(pid)) )
        else { return }
        guard let driver = deviceDescriptor.getDriver() else { return }
        if let m = MouseInterface(driver: driver, device: self.backingDevice.hid, index: index) {
            await MouseTracker.global.addMouse(m)
        }
    }
    
    required init?(withHIDDevice d: HIDDevice) {
        guard let dev = HIDPP.Device(dev: d, devIndex: 0xff) else { return nil }
        self.hid = d
        self.backingDevice = dev
        
        // Read serial
        let rSerial = Proto.Register.BoltUID.Read(onDevice: backingDevice)
        guard let pSerial = rSerial?.parameters else { return nil }
        guard let serial = String(bytes: pSerial, encoding: .utf8) else { return nil }
        self.Serial = serial
        
        // This enables reporting                                         // Wireless, Software, Battery
        let r = Proto.Register.Notifications.Write(onDevice: backingDevice, parameters: [0x10, 0x09, 0x00])
        if r?.CheckError10() != .Success { return nil }
        
        // Bolt apparently just uses this subID for both disconnection and connection events
        observers.append(backingDevice.notifier.newObserver(forSubID: .DeviceConnection, using: ReceiverConnectedHandler))
//        ConnectAll()
        
        
        // Forces refresh of connected devices
        _ = HIDPP.v10.Register.ReceiverConnection.Write(onDevice: self.backingDevice, parameters: [2])
    }
    
    deinit {
        for obs in observers {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}


//        NOTIFICATION_FLAG = _NamedInts(
//            numpad_numerical_keys=0x800000,
//            f_lock_status=0x400000,
//            roller_H=0x200000,
//            battery_status=0x100000,  # send battery charge notifications (0x07 or 0x0D)
//            mouse_extra_buttons=0x080000,
//            roller_V=0x040000,
//            keyboard_sleep_raw=0x020000,  # system control keys such as Sleep
//            keyboard_multimedia_raw=0x010000,  # consumer controls such as Mute and Calculator
//            # reserved_r1b4=        0x001000,  # unknown, seen on a unifying receiver
//            reserved5=0x008000,
//            reserved4=0x004000,
//            reserved3=0x002000,
//            reserved2=0x001000,
//            software_present=0x000800,  # .. no idea
//            reserved1=0x000400,
//            keyboard_illumination=0x000200,  # illumination brightness level changes (by pressing keys)
//            wireless=0x000100,  # notify when the device wireless goes on/off-line
//            mx_air_3d_gesture=0x000001,
//        )
        
