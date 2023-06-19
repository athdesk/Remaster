//
//  GenericV20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

extension HIDPP.Device.HIDAddress : MouseIdentifier {
    static func == (lhs: HIDPP.Device.HIDAddress, rhs: HIDPP.Device.HIDAddress) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.device)
        hasher.combine(self.index)
    }
}

class GenericV20Device : Mouse {
    
    typealias Proto = HIDPP.v20
    internal var backingDevice: HIDPP.Device
    public var identifier: any MouseIdentifier { backingDevice.identifier }
    public var name: String { backingDevice.name }
    public var view: ViewData = ViewData()

    func getBattery() -> UInt {
        let report = Proto.BatteryStatus.GetBatteryLevelStatus.Call(onDevice: backingDevice)
        if report?.isError == false {
            let b = UInt(report!.parameters[0])
            CallbackBattery(b)
            return b
        }
        CallbackBattery(0)
        return 0
    }
    
    /// Wheel management
    internal var EventWheel: EventCallback {{_ in }}
    
    // Assume not supported
    func getSmartShift() -> UInt? { CallbackSmartShift(nil); return nil }
    func setSmartShift(to: UInt) { CallbackSmartShift(nil) }
    func getRatchet() -> Bool? { CallbackRatchet(nil); return nil }
    func setRatchet(to: Bool) { CallbackRatchet(nil) }
    func toggleRatchet() { CallbackRatchet(nil) }
    
    /// DPI Management
    
    func getSupportedDPI() -> (UInt, UInt, UInt)? {
        let p: [UInt8] = [0]
        let report = Proto.AdjustableDPI.GetSensorDPIList.Call(onDevice: backingDevice, parameters: p)
        if report?.isError == false {
            let d = report!.parameters
            let min = UInt(UInt16([UInt8](d[1..<3]))?.bigEndian ?? 0)
            var step = UInt(UInt16([UInt8](d[3..<5]))?.bigEndian ?? 0)
            var max = UInt(UInt16([UInt8](d[5..<7]))?.bigEndian ?? 0)
            if (step & 0xE000) != 0 {
                step -= 0xE000
            } else { // in this case, there are just min/max and the 3rd param is junk
                max = step
                step = 0
            }
            return (min, max, step)
        }
        return nil
    }
    
    func getDPI() -> UInt {
        let p: [UInt8] = [0] // 0 is sensorId
        let report = Proto.AdjustableDPI.GetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        if report?.isError == false {
            let data = report!.parameters
            let dpiBuf = [UInt8](data[1..<3])
            let r = UInt(UInt16(dpiBuf)?.bigEndian ?? 0)
            CallbackDPI(r)
            return r
        }
        return 0
    }
    
    func setDPI(to n: UInt) {
        var p: [UInt8] = [0] // 0 is sensorId
        let n16 = UInt16(n)
        p.append(contentsOf: n16.bigEndian.bytes)
        let r = Proto.AdjustableDPI.SetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        if r?.CheckError20() != .Success {
            _ = getDPI()
        } else {
            CallbackDPI(n)
        }
    }
    
    internal var EventDPI: EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError == false {
            let data = ppReport.parameters
            switch ppReport.function {
            case Proto.AdjustableDPI.SetSensorDPI.rawValue: break
            case Proto.AdjustableDPI.GetSensorDPI.rawValue:
                    let dpiBuf = [UInt8](data[1..<3])
                    let r = UInt(UInt16(dpiBuf)?.bigEndian ?? 0)
                    self.CallbackDPI(r)
            case Proto.AdjustableDPI.GetSensorDPIList.rawValue:
                let min = UInt(UInt16([UInt8](data[1..<3]))?.bigEndian ?? 0)
                var step = UInt(UInt16([UInt8](data[3..<5]))?.bigEndian ?? 0)
                var max = UInt(UInt16([UInt8](data[5..<7]))?.bigEndian ?? 0)
                if (step & 0xE000) != 0 {
                    step -= 0xE000
                } else { // in this case, there are just min/max and the 3rd param is junk
                    max = step
                    step = 0
                }
                self.CallbackDPISupport(min, max, step)
            default:
                break
            }
        }
    }}
    
    required init?(withHIDDevice d: HIDDevice, index i: UInt8) {
        guard let dev = HIDPP.Device(dev: d, devIndex: i) else { return nil }
        let v = dev.protocolVersion
        if (v ?? "1.0" == "1.0") {
            print(" -- protocol version of device \(i) is \(v ?? "Unknown"), skipping")
            return nil
        }
        backingDevice = dev

        if let i = dev.GetFeatureIndex(forID: Proto.AdjustableDPI.ID) {
            _ = backingDevice.notifier.newObserver(forIndex: i, using: EventDPI)
        }
        
        if let i = dev.GetFeatureIndex(forID: Proto.HiResWheel.ID) {
            _ = backingDevice.notifier.newObserver(forIndex: i, using: EventWheel)
        }
        
    }
}
