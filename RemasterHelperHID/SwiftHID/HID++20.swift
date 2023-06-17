//
//  HID++20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

typealias FeatureID = UInt16

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

extension IFeature {
    static internal var _index: FeatureIndex? { nil }
    static internal func getIndex(_ dev: HIDPP.Device) throws -> FeatureIndex {
        if self._index != nil { return self._index! }
        var dict = StoredFeatureIndexes[dev] ?? .init()
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
            var call = try HIDPP.CustomReport(t, Self.getIndex(dev), self.rawValue, nil, dev.devIndex)
            call.parameters = parameters
            print("making call @\(self): \(call.unwrap().hexDescription)")
            let r = dev.SendCommand(call, timeout: timeout)
            print("response @\(self): \(r?.unwrap().hexDescription ?? "bad")")
            return r
        } catch {
            print("Error getting FeatureIndex")
            return nil
        }
    }
}

extension HIDPP {
    struct v20 {
        enum IRoot : FunctionID, IFeature {
            static internal let ID: FeatureID = 0x0000
            static internal var _index: FeatureIndex? = 0

            case GetFeature = 0
            case Ping = 1
        }
        
        enum AdjustableDPI : FunctionID, IFeature {
            static let ID: FeatureID = 0x2201

            case GetSensorCount = 0
            case GetSensorDPIList = 1
            case GetSensorDPI = 2
            case SetSensorDPI = 3
        }
        enum SubID: UInt8 {
            case ErrorMessage = 0xFF

            static public func ==(lhs: UInt8, rhs: SubID) -> Bool {
                return lhs == rhs.rawValue
            }
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
        guard self.subID == HIDPP.v20.SubID.ErrorMessage else { return .Success }
        return HIDPP.v20.ErrorCode(fromRawValue: self.parameters[1])
    }
}

extension HIDPP.Device {
    typealias Proto = HIDPP.v20
    var protocolVersion: String { GetProtocolVersion() } // should not be expensive enough to warrant doing it lazily
    
    private func GetProtocolVersion() -> String {
        let response = Proto.IRoot.Ping.Call(onDevice: self)
        if response != nil {
            let errCode = response!.CheckError10()
            if errCode == .InvalidSubID { return "1.0" }
            if errCode == .Success { return "\(response!.parameters[0]).\(response!.parameters[1])" }
        }
        return "Invalid"
    }
    
    // Min, Step, Max on my devices, idk it may be different so better to return Data()
    func GetSupportedDPI(sensorId: UInt8 = 0) -> [UInt8]? {
        var p: [UInt8] = [sensorId]
        let report = Proto.AdjustableDPI.GetSensorDPIList.Call(onDevice: self, parameters: p)
        if report?.CheckError20() == .Success {
            return report?.parameters
        } else {
            print("Error reading DPI")
            return nil
        }
    }
    
    func GetSensorDPI(sensorId: UInt8 = 0) -> UInt16 {
        let p: [UInt8] = [sensorId]
        let report = Proto.AdjustableDPI.GetSensorDPI.Call(onDevice: self, parameters: p)
        if report?.CheckError20() == .Success {
            let data = report?.parameters
            let dpiBuf = [UInt8](data?[1..<3] ?? .init())
            return UInt16(dpiBuf)?.bigEndian ?? 0
        } else {
            print("Error reading DPI")
            return 0
        }
    }
    
    func SetSensorDPI(to n: UInt16, sensorId: UInt8 = 0) {
        var p: [UInt8] = [sensorId]
        p.append(contentsOf: n.bigEndian.bytes)
        _ = Proto.AdjustableDPI.SetSensorDPI.Call(onDevice: self, parameters: p)
    }
    
    func GetFeatureIndex(forID f: FeatureID) -> FeatureIndex? {
        let p = f.bigEndian.bytes
        let r = Proto.IRoot.GetFeature.Call(onDevice: self, parameters: p)
//        print(r?.parameters[0])
        return r?.parameters[0]
    }
}

