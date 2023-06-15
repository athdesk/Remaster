//
//  HID++20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

//protocol Feature : Equatable {
//    var ID: Int16 { get }
//    associatedtype Func: RawRepresentable where Func.RawValue == UInt8
//}

extension HIDPP {
    struct v20 {
//        struct DPI: Feature {
//            let ID: Int16 = 0x2201
//            enum Func: UInt8 {
//                case GetSensorCount = 0
//                case GetSensorDPIList = 1
//                case GetSensorDPI = 2
//                case SetSensorDPI = 3
//            }
//        }
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
    func CheckError20() -> HIDPP.v20.ErrorCode {
        guard self.subID == HIDPP.v20.SubID.ErrorMessage else { return .Success }
        return HIDPP.v20.ErrorCode(rawValue: self.parameters[1]) ?? .Invalid
    }
}

extension HIDPPDevice {
    func CallFunction(featureIndex: UInt8, function: UInt8, parameters: [UInt8], timeout: TimeInterval = 1) -> HIDPP.CustomReport? {
        //TODO: check if device supports receiving parameters (size)
        let t = HIDPP.CustomReport.type(fromLen: parameters.count + 4)
        var call = MakeReport(t, featureIndex, function)
        call.parameters = parameters
        return SendCommand(call, timeout: timeout)
    }
}

