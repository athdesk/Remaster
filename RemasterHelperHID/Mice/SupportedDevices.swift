//
//  SupportedDevices.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation
import SwiftUI

enum RemasterDevice : CaseIterable {
    static var allCases: [RemasterDevice] = [
        Receiver(.Bolt),
        Receiver(.Unifying),
        MxMaster2S,
        MxMaster3S,
        G502HSE
    ]
    
    static var SupportedDevices: [HIDMonitorData] {
        var devs: [HIDMonitorData] = []
        for kind in allCases {
            devs.append(kind.getMonitorData())
        }
        return devs
    }

    case Receiver(ReceiverType)
    case MxMaster2S
    case MxMaster3S
    case G502HSE
    
    
    func getDriver() -> (any Mouse.Type)? {
        switch self {
        case .Receiver(_): return nil
        case .MxMaster2S: return MxMaster2SDevice.self
        case .MxMaster3S: return MxMaster3SDevice.self
        default: return GenericV20Device.self
        }
    }

    func getMonitorData() -> HIDMonitorData {
        switch self {
        case .Receiver(let rt):
            switch rt {
            case .Bolt:
                return HIDMonitorData(vendorId: 0x046d, productId: 0xc548, usagePage: 0xff00, usage: 1)
            case .Unifying:
                return HIDMonitorData(vendorId: 0x046d, productId: 0xc52b, usagePage: 1, usage: 6)
            }
        case .MxMaster2S: return HIDMonitorData(vendorId: 0x046d, productId: 0xb019)
        case .MxMaster3S: return HIDMonitorData(vendorId: 0x046d, productId: 0xb034)
            // G502 SE seems to make 2 IOHIDDevices; there should be no difference in picking one or the other
        case .G502HSE: return HIDMonitorData(vendorId: 0x46d, productId: 0xc08b, usagePage: 1, usage: 6)
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

extension HIDMonitorData {
    var stripped: HIDMonitorData {
        HIDMonitorData(vendorId: self.vendorId, productId: self.productId)
    }
}
