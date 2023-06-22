//
//  HID++.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation

struct HIDPP {
    struct CustomReport {
        private var d: Data
        var isError: Bool { !(CheckError10() == .Success && CheckError20() == .Success) }
        
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
        
        var subID: UInt8 {
            get { d[2] }
            set { d[2] = newValue }
        }
        
        var feature: FeatureIndex {
            get { FeatureIndex(d[2]) }
            set { d[2] = newValue.rawValue }
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
            self.feature = feat
            self.function = fun
            self.swId = swId ?? 1 // seems to always be 1
        }
        
    }

    struct Device : Hashable {
        public let hid: HIDDevice
        public let devIndex: UInt8
        public var isStandalone: Bool { devIndex == 0 || devIndex == 255 }
        public lazy var name: String = {
            if isStandalone { return hid.name }
            return GetName() ?? "1.0 Device"
        }()
        public lazy var transport: TransportType = {
            if devIndex == 0xff {
                return hid.transport == kIOHIDTransportUSBValue ? .Wired : .Bluetooth
            }
            if case .Receiver(let t) = RemasterDevice(fromMonitorData: hid.idPair) {
                return .Receiver(t)
            }
            return .Wired
        }()
        
        internal var opQueue: OperationQueue
        public let notifier: EventNotifier
        
        var funcReportType: HIDPP.CustomReport.RType? = nil       // this is done manually, i can't seem to figure it out from the reportdescriptor
        
        // swId defaults to 1 because apparently that's how it's done
        func MakeReport(_ t: HIDPP.CustomReport.RType, _ feat: FeatureIndex, _ fun: FunctionID, _ swId: UInt8 = 1) -> HIDPP.CustomReport {
            HIDPP.CustomReport(t, feat, fun, swId, devIndex)
        }
        
        func SendCommand(_ report: HIDPP.CustomReport, timeout: TimeInterval = .infinity) -> HIDPP.CustomReport? {
            var result: HIDPP.CustomReport? = nil
            let receiveLock = NSLock()
            let obs = NotificationCenter.default.addObserver(forName: hid.notificationNameExtra, object: nil, queue: opQueue) { n in
                DispatchQueue.global().async {
                    let recv = n.object as! HIDDevice.Report
                    //                print("()<--------", recv.reportData.hexDescription)
                    let ppReport = HIDPP.CustomReport(withData: recv.reportData)
                    
                    guard ppReport.deviceIndex == devIndex else { return }
                    
                    let e = ppReport.CheckError20()
                    if e != .Success {
                        // Make sure this is for us
                        //                    guard ppReport.swId == report.swId else { return }
                        //                    guard ppReport.function == report.function else { return }
                        // Nevermind it doesn't really work
//                        print(" -- Got 2.0 error from HID device")
                    } else if ppReport.CheckError10() != .Success {
//                        print(" -- Got 1.0 error from HID device")
                    } else {
                        guard ppReport.subID == report.subID else { return }
                        guard ppReport.address == report.address else { return }
                    }
                    
                    result = ppReport
                    receiveLock.unlock()
                }
            }
            defer { NotificationCenter.default.removeObserver(obs) }
            receiveLock.lock()
            _ = hid.writeReport(withData: report.unwrap())
            guard receiveLock.lock(before: .init(timeIntervalSinceNow: timeout)) else { return nil }
            receiveLock.unlock()
            return result
        }
        
        public func hash(into hasher: inout Hasher) {
            hasher.combine(hid)
            hasher.combine(devIndex)
        }
        
        init?(dev: HIDDevice, devIndex: UInt8) {
            self.hid = dev
            self.devIndex = devIndex
            opQueue = OperationQueue()
            opQueue.name = hid.notificationName.rawValue
            opQueue.maxConcurrentOperationCount = 4
            opQueue.underlyingQueue = DispatchQueue.global(qos: .utility)
            self.notifier = EventNotifier(forHID: dev, forIndex: devIndex)
            if protocolVersion == nil {
                return nil
            }
        }
    }
    
}
