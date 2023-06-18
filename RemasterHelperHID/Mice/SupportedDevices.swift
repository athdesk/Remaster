//
//  SupportedDevices.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

enum RemasterDevice : CaseIterable {
    // Receivers
    case Unifying
    case Bolt
    
    case MxMaster2S
    case MxMaster3S
    case G502HSE
    
    func isReceiver() -> Bool {
        switch self {
        case .Unifying: fallthrough
        case .Bolt:
            return true
        default:
            return false
        }
    }
    
    func getDriver() -> Mouse.Type? {
        if isReceiver() { return nil }
        switch self {
        case .MxMaster2S:
            return MxMaster2SDevice.self
        case .MxMaster3S:
            return MxMaster3SDevice.self
        default:
            return GenericV20Device.self
        }
    }

    func getMonitorData() -> HIDMonitorData {
        switch self {
        case .Unifying:
            return HIDMonitorData(vendorId: 0x046d, productId: 0xc52b, usagePage: 1, usage: 6)
        case .Bolt:
            return HIDMonitorData(vendorId: 0x046d, productId: 0xc548, usagePage: 0xff00, usage: 1)
        case .MxMaster2S:
            return HIDMonitorData(vendorId: 0x046d, productId: 0xb019)
        case .MxMaster3S:
            return HIDMonitorData(vendorId: 0x046d, productId: 0xb034)
        case .G502HSE:
            // G502 SE seems to make 2 IOHIDDevices; there should be no difference in picking one or the other
            return HIDMonitorData(vendorId: 0x46d, productId: 0xc08b, usagePage: 1, usage: 6)
            
        }
    }
    
    init?(fromMonitorData d: HIDMonitorData) {
        let s = Self.allCases.first { dev in
            dev.getMonitorData().stripped == d.stripped
        }
        if s != nil {
            self = s!
        } else {
            return nil
        }
    }
}

var SupportedDevices: [HIDMonitorData] {
    var devs: [HIDMonitorData] = []
    for kind in RemasterDevice.allCases {
        devs.append(kind.getMonitorData())
    }
    return devs
}

extension HIDMonitorData {
    var stripped: HIDMonitorData {
        HIDMonitorData(vendorId: self.vendorId, productId: self.productId)
    }
}
