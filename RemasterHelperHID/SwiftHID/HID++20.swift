//
//  HID++20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

typealias FeatureID = UInt16
typealias FunctionID = UInt8

struct FeatureIndex : RawRepresentable, Hashable {
    typealias RawValue = UInt8
    var rawValue: UInt8
    
    static func ==(lhs: FeatureIndex, rhs: UInt8) -> Bool {
        lhs.rawValue == rhs
    }
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    init(_ value: UInt8) {
        self.rawValue = value
    }
}

enum Err : Error {
    case FeatureIndexError
}

protocol IFeature : RawRepresentable where RawValue == FunctionID {
    static var ID: FeatureID { get }
    static var _index: FeatureIndex? { get }
}

// Ugly hack time ^ _ ^
// I regret not having done a real Device class

fileprivate var StoredFeatureIndexes: Dictionary<HIDPP.Device, Dictionary<FeatureID, FeatureIndex>> = .init()
fileprivate var StoredFeatureIndexesLock = NSLock()

// It's meant to make it possible to parallelize calls without destroying coherency
fileprivate var callSeq: [FeatureIndex:UInt] = [:]

extension IFeature {
    static internal var _index: FeatureIndex? { nil }
    
    static func getIndex(_ dev: HIDPP.Device) throws -> FeatureIndex {
        if self._index != nil { return self._index! }
        var dict = StoredFeatureIndexes[dev] ?? .init()
        StoredFeatureIndexesLock.lock()
        defer { StoredFeatureIndexesLock.unlock() }
        let f = dict[self.ID] ?? {
            let e = dev.GetFeatureIndex(forID: self.ID)
            if e != nil {
                dict[self.ID] = e!
                StoredFeatureIndexes[dev] = dict
            }
            return e
        }()
        
        guard f != nil else { throw Err.FeatureIndexError }
        return f!
    }
    
    
    func Call(onDevice dev: HIDPP.Device, parameters: [UInt8] = [], timeout: TimeInterval = 1) -> HIDPP.CustomReport? {
        // TODO: make an exception to the default for longer reports
        let t = dev.funcReportType ?? HIDPP.CustomReport.RType.Long
        do {
            let featIndex = try Self.getIndex(dev)
            let curSeq = callSeq[featIndex] ?? 0
            var call = HIDPP.CustomReport(t, featIndex, self.rawValue, UInt8(curSeq & 0xf), dev.devIndex)
            callSeq[featIndex] = curSeq + 1
            call.parameters = parameters
//            DebugPrint("[>] \(call.unwrap().hexDescription)")
            let r = dev.SendCommand(call, timeout: timeout)
//            if r != nil { DebugPrint("[<] \(r!.unwrap().hexDescription)") }
            return r
        } catch {
            print("Feature \(self) not supported by \(dev.hid.name)")
            return nil
        }
    }
}

extension HIDPP {
    struct v20 {
        enum IRoot : FunctionID, IFeature {
            static internal let ID: FeatureID = 0x0000
            static internal var _index: FeatureIndex? = FeatureIndex(0)
            
            case GetFeature = 0x0
            case Ping = 0x1
        }
        
        // Each IFeature can support being called with the stored function ids, and setting events relating to itself.
        // For now we don't include event descriptors in the enums
        // (except for battery, where it doesn't alias with any other function id)
        // It would make sense to include an `Event` property, but for now I just left event descriptors as comments
        
        enum FwVersion: FunctionID, IFeature {
            static let ID: FeatureID = 0x0003
            
            case GetInfoID = 0x00
            case GetInfoVer = 0x01
        }
        
        enum ReprogControls4: FunctionID, IFeature {
            static let ID: FeatureID = 0x1b04

            enum Flags: UInt8 {
                case TemporaryDiverted = 0x1
                case ChangeTemporaryDivert = 0x2
                case PersistentDiverted = 0x4
                case ChangePersistentDivert = 0x8
                case RawXYDiverted = 0x10
                case ChangeRawXYDivert = 0x20
            }
            
//            enum Event {
//                case DivertedButtonEvent = 0
//                case DivertedRawXYEvent = 1
//            };
            
            case GetControlCount = 0x0
            case GetControlInfo = 0x1
            case GetControlReporting = 0x2
            case SetControlReporting = 0x3
        }
        
        enum OnboardProfiles: FunctionID, IFeature {
            static let ID: FeatureID = 0x8100
            
//            enum Event {
//                case CurrentProfileChanged = 0
//                case CurrentDPIIndexChanged = 1
//            }
            
            case GetDescription = 0x0
            case SetMode = 0x1
            case GetMode = 0x2
            case SetCurrentProfile = 0x3
            case GetCurrentProfile = 0x4
            case MemoryRead = 0x5
            case MemoryAddrWrite = 0x6
            case MemoryWrite = 0x7
            case MemoryWriteEnd = 0x8
            case GetCurrentDPIIndex = 0xb
            case SetCurrentDPIIndex = 0xc
        }
        
        enum FriendlyName: FunctionID, IFeature {
            static let ID: FeatureID = 0x0007
            
            case GetNameLength = 0x00
            case GetName = 0x01
        }
        
        enum SmartShift: FunctionID, IFeature {
            static let ID: FeatureID = 0x2110
            
            case Read = 0x00
            case Write = 0x1
        }
        
        enum ThumbWheel: FunctionID, IFeature {
            static let ID: FeatureID = 0x2150
            
            case GetCapability = 0x00
            case GetMode = 0x1
            case SetMode = 0x2
        }
        
        enum HiResWheel: FunctionID, IFeature {
            static let ID: FeatureID = 0x2121
            
            case GetCapability = 0x00
            case GetMode = 0x1
            case SetMode = 0x2
            case GetRatchet = 0x03
        }

        enum BatteryStatus : FunctionID, IFeature {
            static let ID: FeatureID = 0x1004
            case StatusEvent = 0x00
            case GetBatteryLevelStatus = 0x01
        }
        
        enum BatteryStatusAlt : FunctionID, IFeature {
            static let ID: FeatureID = 0x1000

            case GetBatteryLevelStatus = 0x00
            case GetBatteryCapability = 0x01
        }
        
        enum AdjustableDPI : FunctionID, IFeature {
            static let ID: FeatureID = 0x2201

            case GetSensorCount = 0x00
            case GetSensorDPIList = 0x01
            case GetSensorDPI = 0x02
            case SetSensorDPI = 0x03
        }
        
        enum ErrorCode : UInt8 {
            case Success = 0x00
            case Unknown = 0x01
            case InvalidArgument = 0x02
            case OutOfRange = 0x03
            case HWError = 0x04
            case LogitechInternal = 0x05
            case InvalidFeatureIndex = 0x06
            case InvalidFunctionID = 0x07
            case Busy = 0x08
            case Unsupported = 0x09
            case UnknownDevice = 0x0A
            case Invalid
            
            init(fromRawValue v: UInt8) {
                self = ErrorCode(rawValue: v) ?? ErrorCode.Invalid
            }
        }
        
        static public let Features: [any IFeature.Type] = [
            IRoot.self,
            FriendlyName.self,
            HiResWheel.self,
            BatteryStatus.self,
            AdjustableDPI.self
        ]
    }
}

extension HIDPP.CustomReport {
    init<T : RawRepresentable>(_ t: RType,
                               _ feat: FeatureIndex,
                               _ fun: T,
                               _ swId: UInt8? = nil,
                               _ dev: UInt8? = nil) where T.RawValue == FunctionID {
        self.init(t, feat, fun.rawValue, swId, dev)
    }
    
    func CheckError20() -> HIDPP.v20.ErrorCode {
        guard self.subID == 0xFF else { return .Success }
        return HIDPP.v20.ErrorCode(fromRawValue: self.parameters[1])
    }
}

extension HIDPP.Device {
    typealias Proto = HIDPP.v20

    var protocolVersion: String? { GetProtocolVersion() }
    
    private func GetProtocolVersion() -> String? {
        let response = Proto.IRoot.Ping.Call(onDevice: self)
        if response != nil {
            let errCode = response!.CheckError10()
            if errCode == .InvalidSubID { return "1.0" }
            if errCode == .Success { return "\(response!.parameters[0]).\(response!.parameters[1])" }
        }
        return nil
    }
    
    func GetName() -> String? {
        if protocolVersion == nil || protocolVersion == "1.0" { return nil }
        let r = Proto.FriendlyName.GetNameLength.Call(onDevice: self)
        guard let length = r?.parameters[0] else { return nil }
        if r?.isError20 == true { return nil }
        
        var nameArray: [UInt8] = []
        while nameArray.count < length {
            let p = [UInt8(nameArray.count)]
            let r = Proto.FriendlyName.GetName.Call(onDevice: self, parameters: p)
            if r?.isError20 == true { return nil }
            guard let nameBuf = r?.parameters else { return nil }
            if nameBuf[0] == 0x00 {
                nameArray.append(contentsOf: nameBuf[1...])
            } else {
                nameArray.append(contentsOf: nameBuf)
            }
        }
        nameArray.append(0x00)
        return String(cString: nameArray)
    }
    
    func GetFeatureIndex(forID f: FeatureID) -> FeatureIndex? {
        let p = f.bigEndian.bytes
        if let report = Proto.IRoot.GetFeature.Call(onDevice: self, parameters: p) {
            if report.parameters[0] == 0 || report.isError20 { return nil }
            return FeatureIndex(report.parameters[0])
        }
        return nil
    }
    
    func GetFeature(forIndex i: FeatureIndex) -> (any IFeature.Type)? {
        if let dict = StoredFeatureIndexes[self] {
            if let res = dict.first(where: { pair in pair.value == i }) {
                // Already have it. Yay!
                for t in Proto.Features {
                    if t.ID == res.key { return t }
                }
            }
        }
        // Don't have it. Have to enumerate :(
        for t in Proto.Features {
            if (try? t.getIndex(self) == i) == true {
                return t
            }
        }
        return nil
    }
}

