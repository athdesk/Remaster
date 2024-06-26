//
//  HID++10.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation

//enum RegisterAddress: uint8_t {
//    EnableNotifications = 0x00,
//    EnableIndividualFeatures = 0x01,
//    ConnectionState = 0x02,
//    BatteryStatus = 0x07,
//    BatteryMileage = 0x0D,
//    CurrentProfile = 0x0F,
//    LEDStatus = 0x51,
//    LEDIntensity = 0x54,
//    LEDColor = 0x57,
//    SensorSettings = 0x61,
//    SensorResolution = 0x63,
//    USBPollRate = 0x64,
//    MemoryOperation = 0xA0,
//    ResetSeqNum = 0xA1,
//    MemoryRead = 0xA2,
//    DevicePairing = 0xB2,
//    DeviceActivity = 0xB3,
//    DevicePairingInfo = 0xB5,
//    FirmwareInfo = 0xF1,
//};
//
//constexpr std::size_t PageSize = 512;
//constexpr std::size_t RAMSize = 400;

extension HIDPP {
    struct v10 {
        enum Register: UInt16 {
            // Long Registers are (0x0200 | regNum), so we can do subId = 0x81 | .hiByte and address = .loByte
            case ReceiverConnection = 0x02
            case ReceiverPairing = 0xB2
            case ReceiverDevActivity = 0x2B3
            case ReceiverInfo = 0x2B5
            case BoltDevDiscovery = 0xC0
            case BoltPairing = 0x2C1
            case BoltUID = 0x02FB

            case Notifications = 0x00
            case Firmware = 0xF1
            
            func Read(onDevice dev: HIDPP.Device, parameters: [UInt8] = [],  timeout: TimeInterval = 2) -> HIDPP.CustomReport? {
                let t = HIDPP.CustomReport.RType.Short // TODO: choose it based on size
                let request: UInt16 = 0x8100 | self.rawValue
                var call = HIDPP.CustomReport(withType: t)
                call.deviceIndex = dev.devIndex
                call.subID = UInt8(request >> 8)
                call.address = UInt8(request & 0xff)
                call.parameters = parameters
                let r = dev.SendCommand(call, timeout: timeout)
                return r
            }
            
            func Write(onDevice dev: HIDPP.Device, parameters: [UInt8] = [],  timeout: TimeInterval = 2) -> HIDPP.CustomReport? {
                let t = HIDPP.CustomReport.RType.Short // TODO: choose it based on size
                let request: UInt16 = 0x8000 | self.rawValue
                var call = HIDPP.CustomReport(withType: t)
                call.deviceIndex = dev.devIndex
                call.subID = UInt8(request >> 8)
                call.address = UInt8(request & 0xff)
                call.parameters = parameters
                let r = dev.SendCommand(call, timeout: timeout)
                return r
            }
        }
        
        enum SubID: UInt8 {
            case DeviceDisconnection = 0x40
            case DeviceConnection = 0x41
            case SendDataAcknowledgement = 0x50
            case SetRegisterShort = 0x80
            case GetRegisterShort = 0x81
            case SetRegisterLong = 0x82
            case GetRegisterLong = 0x83
            case ErrorMessage = 0x8F
            case SendDataBegin = 0x90
            case SendDataContinue = 0x91
            case SendDataBeginAck = 0x92
            case SendDataContinueAck = 0x93
            
            static public func ==(lhs: UInt8, rhs: SubID) -> Bool {
                return lhs == rhs.rawValue
            }
        }
        
        enum ErrorCode : UInt8 {
            case Success = 0x00
            case InvalidSubID = 0x01
            case InvalidAddress = 0x02
            case InvalidValue = 0x03
            case ConnectFail = 0x04
            case TooManyDevices = 0x05
            case AlreadyExists = 0x06
            case Busy = 0x07
            case UnknownDevice = 0x08
            case ResourceError = 0x09
            case RequestUnavailable = 0x0A
            case InvalidParamValue = 0x0B
            case WrongPINCode = 0x0C
            case Invalid
        }
    }
}

extension HIDPP.CustomReport {
    func CheckError10() -> HIDPP.v10.ErrorCode {
        guard self.type == .Short else { return .Success }
        guard self.subID == HIDPP.v10.SubID.ErrorMessage else { return .Success }
        
        return HIDPP.v10.ErrorCode(rawValue: self.parameters[1]) ?? .Invalid
    }
}
