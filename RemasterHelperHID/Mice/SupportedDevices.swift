//
//  SupportedDevices.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

enum RemasterDevice : CaseIterable {
    case MxMaster3S
    case G502HSE
    
    func getDriver() -> Mouse.Type {
        switch self {
        case .MxMaster3S:
            return GenericV20Device.self
        default:
            return GenericV20Device.self
        }
    }

    func getMonitorData() -> HIDMonitorData {
        switch self {
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
