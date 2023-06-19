//
//  MxMaster3S.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 17/06/23.
//

import Foundation

class MxMaster3SDevice : GenericV20Device {
    var ratchetSaved: Bool? = nil
    var ssSaved: UInt? = nil
    
    internal var CallbackRatchet: BoolOptCallback {{ arg in
        self.ratchetSaved = arg
        self.view.DefaultRatchetCallback(arg)
    }}
    
    override internal var EventWheel: EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError == false {
            let data = ppReport.parameters
            switch ppReport.function {
            case 0x1:
                if ppReport.swId == 1 { return } // not an event, may contain false data
                let ratchetStatus = (data[0] & 0x01) != 0
                self.CallbackRatchet(ratchetStatus)
            default: break
            }
        }
    }}
    
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
//        print((inv, rat, div, res))
        self.CallbackRatchet(rat)
        return (inv, rat, div, res)
    }
    
    override func getSmartShift() -> UInt? {
        let report = Proto.SmartShift.Read.Call(onDevice: backingDevice)
        if report?.isError == false {
            let data = report!.parameters
            let r = UInt(data[1])
            CallbackSmartShift(r)
            return r
        }
        return nil
    }
    
    override func setSmartShift(to: UInt) {
        print("\(#function) \(String(describing: to))")
        var p: [UInt8] = [to > 0 ? 2 : 1]
        p.append(UInt8(to))
        _ = Proto.SmartShift.Write.Call(onDevice: backingDevice, parameters: p)
    }
    
    override func getRatchet() -> Bool? {
        let s = ratchetSaved ?? getWheelInfo().1
        self.CallbackRatchet(s)
        return s
    }

    override func setRatchet(to: Bool) {
        setSmartShift(to: to ? 45: 0)
    }
    
    override func toggleRatchet() {
        if let cur = getRatchet() {
            setRatchet(to: !cur)
        }
    }
    
    // Does not support granular DPI
    override func setDPI(to n: UInt) {
        var p: [UInt8] = [0] // 0 is sensorId
        let n16 = UInt16(n)
        p.append(contentsOf: n16.bigEndian.bytes)
        _ = Proto.AdjustableDPI.SetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        _ = getDPI()
    }

}
