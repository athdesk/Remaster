//
//  MxMaster3S.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 17/06/23.
//

import Foundation

class MxMaster3SDevice : GenericV20Device {
    
    // Invert, Ratchet, Diverted, HiRes
    private func getWheelInfo() -> (Bool?, Bool?, Bool?, Bool?) {
        var inv: Bool?
        var rat: Bool? = false
        var div: Bool?
        var res: Bool?
        let rMode = Proto.HiResWheel.GetMode.Call(onDevice: backingDevice)
        if rMode?.CheckError20() == .Success {
            let flags = rMode!.parameters[0]
            div = (flags & 0x01) != 0
            res = (flags & 0x02) != 0
            inv = (flags & 0x04) != 0
        }
        
        let rCap = Proto.HiResWheel.GetCapability.Call(onDevice: backingDevice)
        if rCap?.CheckError20() == .Success {
            let flags = rCap!.parameters[0]
            rat = (flags & 0x04) != 0 ? rat : nil
            inv = (flags & 0x08) != 0 ? inv : nil
        }
        if rat != nil {
            let rRat = Proto.HiResWheel.GetRatchet.Call(onDevice: backingDevice)
            if rRat?.CheckError20() == .Success {
                let flags = rRat!.parameters[0]
                rat = (flags & 0x01) != 0
            }
        }
        print((inv, rat, div, res))
        return (inv, rat, div, res)
    }
    
    override func setDPI(to n: UInt) {
        var p: [UInt8] = [0] // 0 is sensorId
        let n16 = UInt16(n)
        p.append(contentsOf: n16.bigEndian.bytes)
        _ = Proto.AdjustableDPI.SetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        _ = getDPI()
    }

}
