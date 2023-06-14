//
//  HID++.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation

struct HIDPP {
    enum RType: UInt8 {
        case Short = 0x10
        case Long = 0x11
        case Huge = 0x12
        case Invalid
    }
    
    struct CustomReport {
        private var d: Data
        
        var type: HIDPP.RType {
            get {
                switch d[0] {
                case 0x10:
                    return .Short
                case 0x11:
                    return .Long
                case 0x12:
                    return .Huge
                default:
                    return .Invalid
                }
            }
            set { d[0] = newValue.rawValue }
        }
        
        var deviceIndex: UInt8 {
            get { d[1] }
            set { d[1] = newValue}
        }
        
        var subID: UInt8 {
            get { d[2] }
            set { d[2] = newValue}
        }
        
        var address: UInt8 {
            get { d[3] }
            set { d[3] = newValue}
        }
        
        var parameters: [UInt8] {
            get { [UInt8](d.suffix(from: 4)) }
            set {
                for (index, val) in newValue.enumerated() {
                    if d.count == 4 + index { break }
                    d[4+index] = val
                }
            }
        }
        
        
        private static func len(fromType t: RType) -> Int {
            switch t {
            case .Short:
                return 7
            case .Long:
                return 20
            case .Huge:
                return 64
            case .Invalid:
                return 64
            }
        }

        public func unwrap() -> Data {
            return d
        }
        
        init(withData data: Data) {
            d = data
        }
        
        init(withType type: RType) {
            d = Data(count: CustomReport.len(fromType: type))
            self.type = type
        }
    }
    
    static func MakeReport(_ t: RType, _ dev: UInt8, _ feat: UInt8, _ fun: UInt8, _ swId: UInt8) -> CustomReport {
        var report = CustomReport(withType: t)
        report.deviceIndex = dev
        report.subID = feat
        report.address = fun << 4 | swId & 0x0f
        return report
    }
}

struct HIDPPDevice {
    private let hid: HIDDevice
    private let devIndex: UInt8
    
    var protocolVersion: String { GetProtocolVersion() } // should not be expensive enough to warrant doing it lazily
    
    private func GetProtocolVersion() -> String {
        let call = MakeReport(.Long, 0, 1, 1) // TODO: use enums
        let response = SendCommand(call, timeout: 1)
        if response != nil {
            let errCode = response!.CheckError10()
            if errCode == .InvalidSubID { return "1.0" }
            if errCode == .Success { return "\(response!.parameters[0]).\(response!.parameters[1])" }
        }
        return "Invalid"
    }
    
    func MakeReport(_ t: HIDPP.RType, _ feat: UInt8, _ fun: UInt8, _ swId: UInt8) -> HIDPP.CustomReport {
        HIDPP.MakeReport(t, devIndex, feat, fun, swId)
    }

    func SendCommand(_ report: HIDPP.CustomReport, timeout: TimeInterval = .infinity) -> HIDPP.CustomReport? {
        let s = hid.writeReport(withData: report.unwrap())
        guard s == true else { return nil }
        let receiveLock = NSLock()
        receiveLock.lock()
        
        var result: HIDPP.CustomReport? = nil
        
        let obs = NotificationCenter.default.addObserver(forName: hid.notificationNameExtra, object: nil, queue: nil) { n in
            let recv = n.object as! HIDDevice.Report
            let ppReport = HIDPP.CustomReport(withData: recv.reportData)

            guard ppReport.deviceIndex == devIndex else { return }
            guard ppReport.subID == report.subID else { return }
            guard ppReport.address == report.address else { return }
            result = ppReport
            receiveLock.unlock()
        }
        
        defer { NotificationCenter.default.removeObserver(obs) }
        
        guard receiveLock.lock(before: .init(timeIntervalSinceNow: timeout)) else { return nil }
        receiveLock.unlock()
        return result
    }

    init(dev: HIDDevice, devIndex: UInt8) {
        self.hid = dev
        self.devIndex = devIndex
    }
}
