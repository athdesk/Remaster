//
//  MxMaster3S.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 17/06/23.
//

import Foundation

class MxMaster3SDevice : GenericV20Device {
    @Published private var _Ratchet: Bool? = nil
    private var _SmartShift: UInt? = nil // This is not published due to a UI bug caused by it (double refresh)
    @Published private var _WheelInvert: Bool? = nil
    @Published private var _WheelHiRes: Bool? = nil
    @Published private var _WheelDiversion: Bool? = nil
    @Published private var _HWheelInvert: Bool? = nil
    @Published private var _HWheelDiversion: Bool? = nil
    
    override var Ratchet: Bool? {
        get { return _Ratchet }
        set { setRatchet(to: newValue ?? false)}
    }
    
    override var SmartShift: UInt? {
        get { return _SmartShift }
        set { setSmartShift(to: newValue ?? 0) }
    }
    
    override var WheelInvert: Bool? {
        get { return _WheelInvert }
        set { setWheelInvert(to: newValue ?? false) }
    }

    override var WheelHiRes: Bool? {
        get { return _WheelHiRes }
        set { setWheelHiRes(to: newValue ?? false) }
    }

    override var WheelDiversion: Bool? {
        get { return _WheelDiversion }
        set { setWheelDiversion(to: newValue ?? false) }
    }
    
    override var HWheelInvert: Bool? {
        get { return _HWheelInvert }
        set { setHWheelInvert(to: newValue ?? false) }
    }
    
    override var HWheelDiversion: Bool? {
        get { return _HWheelDiversion }
        set { setHWheelDiversion(to: newValue ?? false) }
    }
    
    override internal var EventWheel: EventCallback {{ n in
        let ppReport = n.object as! HIDPP.CustomReport
        if ppReport.isError20 == false {
            let data = ppReport.parameters
            switch ppReport.function {
            case 0x1: // Ratchet status
                if ppReport.swId == 1 { return } // not an event, may contain false data
                let ratchetStatus = (data[0] & 0x01) != 0
                self._Ratchet = ratchetStatus
            default: break
            }
        }
    }}
    
    private func setHWheelMode(diversion: Bool, invert: Bool) {
        var params: [UInt8] = []
        params.append(diversion ? 1 : 0)
        params.append(invert ? 1 : 0)
        _ = Proto.ThumbWheel.SetMode.Call(onDevice: backingDevice, parameters: params)
        _ = getHWheelInfo()
    }
    
    private func setHWheelInvert(to: Bool) {
        guard _HWheelInvert != nil || getHWheelInfo().0 != nil else { return }
        setHWheelMode(diversion: _HWheelDiversion ?? false,
                     invert: to)
    }
    
    private func setHWheelDiversion(to: Bool) {
        guard _HWheelDiversion != nil || getHWheelInfo().1 != nil else { return }
        setHWheelMode(diversion: to,
                     invert: _HWheelInvert ?? false)
    }
    
    // Invert, Diverted
    private func getHWheelInfo() -> (Bool?, Bool?) {
        var inv: Bool?
        var div: Bool?
        
        let rMode = Proto.ThumbWheel.GetMode.Call(onDevice: backingDevice)
        if rMode?.CheckError20() == .Success {
            let lo8 = rMode!.parameters[0]
            let hi8 = rMode!.parameters[1]
            div = lo8 != 0
            inv = hi8 != 0
        }
        _HWheelInvert = inv
        _HWheelDiversion = div
        print("thumb wheel invert \(inv) divert \(div)")
        return (inv, div)
    }
    
    private func setWheelMode(diversion: Bool, invert: Bool, hires: Bool) {
        var flags: UInt8 = 0
        flags |= diversion ? 0x01 : 0
        flags |= hires ? 0x02 : 0
        flags |= invert ? 0x04 : 0
        _ = Proto.HiResWheel.SetMode.Call(onDevice: backingDevice, parameters: [flags])
        _ = getWheelInfo()
    }
    
    // We might as whell check every time if the cache variable is nil
    // the UI wouldn't be able to issue this command anyway, and it's useful for debugging
    private func setWheelInvert(to: Bool) {
        guard _WheelInvert != nil || getWheelInfo().0 != nil else { return }
        setWheelMode(diversion: _WheelDiversion ?? false,
                     invert: to,
                     hires: _WheelHiRes ?? false)
    }
    
    private func setWheelHiRes(to: Bool) {
        guard _WheelHiRes != nil || getWheelInfo().3 != nil else { return }
        setWheelMode(diversion: _WheelDiversion ?? false,
                     invert: _WheelInvert ?? false,
                     hires: to)
    }
    
    private func setWheelDiversion(to: Bool) {
        guard _WheelDiversion != nil || getWheelInfo().2 != nil else { return }
        setWheelMode(diversion: to,
                     invert: _WheelInvert ?? false,
                     hires: _WheelHiRes ?? false)
    }
    
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
        _WheelInvert = inv
        _WheelHiRes = res
        _WheelDiversion = div
//        DebugPrint("inv \(inv) rat \(rat) div \(div) res \(res)")
        return (inv, rat, div, res)
    }
    
    func getSmartShift() -> UInt? {
        let report = Proto.SmartShift.Read.Call(onDevice: backingDevice)
        if report?.isError20 == false {
            let data = report!.parameters
            let r = UInt(data[1])
            _SmartShift = r
            DebugPrint("SmartShift is \(_SmartShift ?? 0)")
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
    
    private func setRatchet(to: Bool) {
        // TODO: get a default instead of 45
        // save this now, it will get clobbered, restore it later
        let x = _SmartShift ?? getSmartShift()
        setSmartShift(to: to ? _SmartShift ?? 45: 0)
        _SmartShift = x
    }

    override func refreshData() {
        super.refreshData()
        _ = getWheelInfo()
        _ = getSmartShift()
        _ = getHWheelInfo()
    }
    
}
