//
//  GenericV20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation
import Combine

func getThumbName(fromName name: String) -> String {
    switch name {
    case "MX Master 3S": return "MX Master 3S"
    case "MX Master 2S": return "MX Master 3S"
    case "G502 HERO SE": return "G502"
    case "G502 HERO": return "G502"
    case "G502": return "G502"
    default: return "Generic"
    }
}

//extension HIDPP.Device.HIDAddress : MouseIdentifier {
//    static func == (lhs: HIDPP.Device.HIDAddress, rhs: HIDPP.Device.HIDAddress) -> Bool {
//        return lhs.hashValue == rhs.hashValue
//    }
//    
//    func hash(into hasher: inout Hasher) {
//        hasher.combine(self.device)
//        hasher.combine(self.index)
//    }
//}

class GenericV20Device : Mouse {
    typealias Proto = HIDPP.v20
    internal var backingDevice: HIDPP.Device
    
    public var name: String { backingDevice.name }
    var transport: TransportType { backingDevice.transport }
    var thumbnailName: String {getThumbName(fromName: name)}
    var hid: HIDDevice { backingDevice.hid }
    var index: UInt8 { backingDevice.devIndex }
    
    @Published var Battery: Battery? = nil
    
    /// Getters / Setters
    
    // Assume these are not supported
    // TODO: eventually implement software fallbacks for these in the basic driver
    var Ratchet: Bool? { get { nil } set { } }
    var SmartShift: UInt? { get { nil } set { } }
    var WheelInvert: Bool? { get { nil } set { } }
    var WheelHiRes: Bool? { get { nil } set { } }
    var WheelDiversion: Bool? { get { nil } set { } }

    @Published var _DPI: UInt?
    var DPI: UInt { get { _DPI ?? getDPI() } set { setDPI(to: newValue) } }
    // TODO: fix this
    var SupportedDPI: DPISupport { DPISupport(min: 600, max: 4000, step: nil) }
        
    /// Battery
    
    func getBattery() -> Battery? {
        let report = Proto.BatteryStatus.GetBatteryLevelStatus.Call(onDevice: backingDevice)
        if report?.isError20 == false {
            let percent = UInt(report!.parameters[0])
            let charging = report!.parameters[2]
            let b = RemasterHelperHID.Battery(Percent: percent,
                               Charging: charging == 0 ? false : true)
            self.Battery = b
            return b
        }
        Battery = nil
        return nil
    }
    
    /// Events
    
    internal var EventBattery : EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError20 == false {
            let data = ppReport.parameters
            switch ppReport.function {
            case Proto.BatteryStatus.StatusEvent.rawValue:
                let percent = UInt(data[0])
                let charging = data[2]
                self.Battery = RemasterHelperHID.Battery(Percent: percent,
                                                       Charging: charging == 0 ? false : true)
            default:
                break
            }
        }
    }}
    
    // TODO: Add real support for reading stored profiles, if we ever want to support them
    // For now, we just refresh data to pickup DPI and other stuff that may be contained in the profile
    internal var EventProfile: EventCallback {{ n in
        self.refreshData()
    }}
    
    internal var EventDPI: EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError20 == false {
            let data = ppReport.parameters
            switch ppReport.function {
            case Proto.AdjustableDPI.SetSensorDPI.rawValue: break
            case Proto.AdjustableDPI.GetSensorDPI.rawValue:
                let dpiBuf = [UInt8](data[1..<3])
                let r = UInt(UInt16(dpiBuf)?.bigEndian ?? 0)
                self._DPI = r
            default:
                break
            }
        }
    }}
    
    internal var EventWheel: EventCallback {{_ in }}
    
    /// DPI Management
    
    private func getSupportedDPI() -> (UInt, UInt, UInt)? {
        let p: [UInt8] = [0]
        let report = Proto.AdjustableDPI.GetSensorDPIList.Call(onDevice: backingDevice, parameters: p)
        if report?.isError20 == false {
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
    
    private func getDPI() -> UInt {
        let p: [UInt8] = [0] // 0 is sensorId
        let report = Proto.AdjustableDPI.GetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        if report?.isError20 == false {
            let data = report!.parameters
            let dpiBuf = [UInt8](data[1..<3])
            let r = UInt(UInt16(dpiBuf)?.bigEndian ?? 0)
            _DPI = r
            DebugPrint("DPI is \(_DPI ?? 0)")
            return r
        }
        return 0
    }
    
    private func setDPI(to n: UInt) {
        var p: [UInt8] = [0] // 0 is sensorId
        let n16 = UInt16(n)
        p.append(contentsOf: n16.bigEndian.bytes)
        let r = Proto.AdjustableDPI.SetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        if r?.CheckError20() != .Success {
            _ = getDPI()
        } else {
            _DPI = n
        }
    }
    
    /// Initializer and refresh function
    
    func refreshData() {
        _ = getDPI()
        _ = getBattery()
        _ = getSupportedDPI()
    }
    
    private var observers: [NSObjectProtocol] = []
    
    required init?(withHIDDevice d: HIDDevice, index i: UInt8) {
        guard let dev = HIDPP.Device(dev: d, devIndex: i) else { return nil }
        let v = dev.protocolVersion
        if (v ?? "1.0" == "1.0") {
            print(" -- protocol version of device \(i) is \(v ?? "Unknown"), skipping")
            return nil
        }
        backingDevice = dev
        
        if let i = dev.GetFeatureIndex(forID: Proto.AdjustableDPI.ID) {
            observers.append(backingDevice.notifier.newObserver(forIndex: i, using: EventDPI))
        }
        
        if let i = dev.GetFeatureIndex(forID: Proto.HiResWheel.ID) {
            observers.append(backingDevice.notifier.newObserver(forIndex: i, using: EventWheel))
        }
        
        if let i = dev.GetFeatureIndex(forID: Proto.BatteryStatus.ID) {
            observers.append(backingDevice.notifier.newObserver(forIndex: i, using: EventBattery))
        }
        
        if let i = dev.GetFeatureIndex(forID: Proto.OnboardProfiles.ID) {
            observers.append(backingDevice.notifier.newObserver(forIndex: i, using: EventProfile))
        }
    }
    
    deinit {
        for obs in observers {
            NotificationCenter.default.removeObserver(obs)
        }
    }
}
