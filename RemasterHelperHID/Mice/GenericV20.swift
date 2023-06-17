//
//  GenericV20.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

class GenericV20Device : Mouse {
    //TODO: private this after debugging
    public var backingDevice: HIDPP.Device
    
    func getSupportedDPI() -> (UInt, UInt, UInt) {
        guard let d = backingDevice.GetSupportedDPI() else { return (0, 0, 0) }
        let min = UInt16([UInt8](d[1..<3]))?.bigEndian ?? 0
        var step = UInt16([UInt8](d[3..<5]))?.bigEndian ?? 0
        var max = UInt16([UInt8](d[5..<7]))?.bigEndian ?? 0
        
        if (step & 0xE000) != 0 {
            step -= 0xE000
        } else { // in this case, there are just min/max and the 3rd param is junk
            max = step
            step = 0
        }
        
        CallbackDPISupport(UInt(min), UInt(max), UInt(step))
        return (UInt(min), UInt(max), UInt(step))
    }
    
    func getDPI() -> UInt {
        let r = UInt(backingDevice.GetSensorDPI())
        CallbackDPI(r)
        return r
    }
    
    func setDPI(to: UInt) {
        let to16 = UInt16(to)
        backingDevice.SetSensorDPI(to: to16)
        _ = getDPI()
    }
    
    required init(withHIDDevice d: HIDDevice, index i: UInt8) {
        backingDevice = HIDPP.Device(dev: d, devIndex: i)
    }
}
