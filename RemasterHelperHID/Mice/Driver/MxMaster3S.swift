//
//  MxMaster3S.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 17/06/23.
//

import Foundation

class MxMaster3SDevice : GenericV20Device {
    @Published private var _Ratchet: Bool? = nil
    @Published private var _SmartShift: UInt? = nil
        
    override var Ratchet: Bool? {
        get { return _Ratchet }
        set { setRatchet(to: newValue ?? false)}
    }
    
    override var SmartShift: UInt? {
        get { return _SmartShift }
        set { setSmartShift(to: newValue ?? 0) }
    }
    
    override internal var EventWheel: EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError == false {
            let data = ppReport.parameters
            switch ppReport.function {
            case 0x1:
                if ppReport.swId == 1 { return } // not an event, may contain false data
                let ratchetStatus = (data[0] & 0x01) != 0
                self._Ratchet = ratchetStatus
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
        _Ratchet = rat
        return (inv, rat, div, res)
    }
    
    func getSmartShift() -> UInt? {
        let report = Proto.SmartShift.Read.Call(onDevice: backingDevice)
        if report?.isError == false {
            let data = report!.parameters
            let r = UInt(data[1])
            return r
        }
        return nil
    }
    
    func setSmartShift(to: UInt) {
        var p: [UInt8] = [to > 0 ? 2 : 1]
        p.append(UInt8(to))
        _SmartShift = to
        _ = Proto.SmartShift.Write.Call(onDevice: backingDevice, parameters: p)
    }
    
    private func getRatchet() -> Bool? {
        return getWheelInfo().1
    }

    private func setRatchet(to: Bool) {
        // TODO: get a default instead of 45
        // save this now, it will get clobbered, restore it later
        let x = _SmartShift ?? getSmartShift()
        setSmartShift(to: to ? _SmartShift ?? 45: 0)
        _SmartShift = x
    }
    
    private func toggleRatchet() {
        if let cur = getRatchet() {
            setRatchet(to: !cur)
        }
    }

    override func refreshData() {
        super.refreshData()
        _ = getWheelInfo()
        _ = getSmartShift()
    }
    
}
