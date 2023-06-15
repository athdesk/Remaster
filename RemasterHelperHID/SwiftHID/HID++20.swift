//
//  HID++20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

typealias FeatureID = UInt16

protocol IFeature : RawRepresentable where RawValue == FunctionID {
    static var ID: FeatureID { get }
    static var index: FeatureIndex { get }
}

extension IFeature {
    func Call(parameters: [UInt8] = [], timeout: TimeInterval = 1) -> HIDPP.CustomReport {
        let t = HIDPP.CustomReport.type(fromLen: parameters.count + 4)
        var call = HIDPP.CustomReport(t, Self.index, self.rawValue)
        call.parameters = parameters
        return call
    }
}

extension HIDPP {

    struct v20 {
        enum IRoot : FunctionID, IFeature {
            static let ID: FeatureID = 0x0000
            static let index: FeatureIndex = 0x00

            case GetFeature = 0
            case Ping = 1
        }
        
//        struct DPI : IFeature {
//            static let ID: FeatureID = 0x2201
//            static let index: FeatureIndex = 0
//            enum Function: FunctionID {
//                case GetSensorCount = 0
//                case GetSensorDPIList = 1
//                case GetSensorDPI = 2
//                case SetSensorDPI = 3
//            }
//        }
//
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
        return HIDPP.v20.ErrorCode(rawValue: self.parameters[1]) ?? .Invalid
    }
}

extension HIDPP.Device {
    typealias Proto = HIDPP.v20
    var protocolVersion: String { GetProtocolVersion() } // should not be expensive enough to warrant doing it lazily
    
    private func GetProtocolVersion() -> String {
        let call = Proto.IRoot.Ping.Call(parameters: .init(repeating: 0, count: 8))
        let response = SendCommand(call, timeout: 1)
        if response != nil {
            let errCode = response!.CheckError10()
            if errCode == .InvalidSubID { return "1.0" }
            if errCode == .Success { return "\(response!.parameters[0]).\(response!.parameters[1])" }
        }
        return "Invalid"
    }
    
    func GetFeatureIndex(forID f: FeatureID) -> FeatureIndex? {
        let p = f.bigEndian.bytes
        let call = Proto.IRoot.GetFeature.Call(parameters: p)
        let r = SendCommand(call)
        return r?.unwrap()[0]
    }
}

