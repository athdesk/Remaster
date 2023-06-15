//
//  HID++.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation

typealias FeatureIndex = UInt8
typealias FunctionID = UInt8

struct HIDPP {
    struct CustomReport {
        private var d: Data
        
        enum RType: UInt8 {
            case Short = 0x10
            case Long = 0x11
            case Huge = 0x12
            case Invalid
        }
        
        var type: RType {
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
        
        var subID: FeatureIndex {
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
        
        var function: FunctionID {
            get { d[3] >> 4 }
            set { d[3] = newValue << 4 | d[3] & 0x0F}
        }
        
        var swId: UInt8 {
            get { d[3] & 0x0F }
            set { d[3] = d[3] & 0xF0 | newValue & 0x0F}
        }
        
        public static func type(fromLen l: Int) -> RType {
            if l <= 7 { return .Short }
            if l <= 20 { return .Long }
            if l <= 64 { return .Huge }
            return .Invalid
        }
        
        public static func len(fromType t: RType) -> Int {
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
        
        init(_ t: RType,
                               _ feat: FeatureIndex,
                               _ fun: FunctionID,
                               _ swId: UInt8? = nil,
                               _ dev: UInt8? = nil) {
            d = Data(count: CustomReport.len(fromType: t))
            self.type = t
            self.deviceIndex = dev ?? 0 // this is to make it possible to manually populate
            self.subID = feat
            self.function = fun
            self.swId = swId ?? 1 // seems to always be 1
        }
        
    }

    struct Device {
        private let hid: HIDDevice
        private let devIndex: UInt8
               
        // swId defaults to 1 because apparently that's how it's done
        func MakeReport(_ t: HIDPP.CustomReport.RType, _ feat: FeatureIndex, _ fun: FunctionID, _ swId: UInt8 = 1) -> HIDPP.CustomReport {
            HIDPP.CustomReport(t, feat, fun, swId, devIndex)
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
    
}
