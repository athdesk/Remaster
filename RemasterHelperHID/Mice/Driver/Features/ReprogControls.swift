//
//  ReprogControls4.swift
//  RemasterHelperHID
//
//  Created by Mario on 14/07/23.
//

import Foundation

// It being a class/actor may not be so bad after all, but struct seems fine until now
actor ReprogKey : ReprogChoice {
    static func == (lhs: ReprogKey, rhs: ReprogKey) -> Bool {
        lhs.hashValue == rhs.hashValue
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(backingDevice)
        hasher.combine(Index)
        hasher.combine(ControlID)
        hasher.combine(TaskID)
        hasher.combine(Position)
        hasher.combine(Group)
        hasher.combine(GroupMask)
        hasher.combine(Flags)
    }
    
    typealias Feature = HIDPP.v20.ReprogControls4
    
    // Key constants
    let backingDevice: HIDPP.Device
    let Index: UInt8
    let ControlID: UInt16
    let TaskID: UInt16
    let Position: UInt8
    let Group: UInt8 // Groups Range from 1 to 8; Zero means no group
    let GroupMask: UInt8
    let Flags: UInt16
    
    nonisolated lazy var FriendlyName: String = {
        if Position == 0 {
            switch Index {
            case 0: return "Left Button"
            case 1: return "Right Button"
            case 2: return "Middle Button"
            default: return "Button \(Index + 1)"
            }
        }
        return "Control \(Position):\(Index)"
    }()
    
    // Dirty hack to break the async cycle :crying_face:
    nonisolated func str() -> String {
        return FriendlyName
    }
    
    // Flags easy getters
    var fReprogrammable: Bool { Flags & 0x10 != 0 }
    var fDivertable: Bool { Flags & 0x20 != 0 }
    var fDivertablePersist: Bool { Flags & 0x40 != 0 }
    var fRawXY: Bool { Flags & 0x100 != 0 }
    var fRawXYForced: Bool { Flags & 0x200 != 0 }
    
    // Key variable fields
    var _rCID: UInt16 = 0
    var _rFlags: UInt16 = 0
    
    var rCID: UInt16 {
        get {
            if _rCID != 0 {
                return _rCID
            }
            return ControlID
        }
        set {
            setFields(cid: newValue, flags: rFlags)
        }
    }

    var rFlags: UInt16 {
        get {
            if _rFlags != 0 {
                return _rFlags
            }
            return Flags
        }
        set {
            setFields(cid: rCID, flags: newValue)
        }
    }

    private func refreshFields() -> Bool {
        guard let report = Feature.GetControlReporting.Call(
            onDevice: backingDevice,
            parameters: ControlID.bytes) else { return false }
        guard !report.isError20 else { return false }
        let repCID = UInt16([UInt8](report.parameters[0..<2]))!.littleEndian
        guard repCID == ControlID else { return false }
        let mapCID = UInt16([UInt8](report.parameters[3..<5]))!.littleEndian
        let mapFlags = UInt16(report.parameters[2]) + UInt16(report.parameters[5]) << 8
        _rCID = mapCID
        _rFlags = mapFlags
        return true
    }

    private func setFields(cid: UInt16, flags: UInt16) {
        var params: [UInt8] = []
        params.append(contentsOf: ControlID.bytes)
        params.append(UInt8(flags & 0xff))
        params.append(contentsOf: cid.bytes)
        params.append(UInt8(flags >> 8))

        _ = Feature.SetControlReporting.Call(
            onDevice: backingDevice,
            parameters: params)
    }
    
    init(withDevice dev: HIDPP.Device, report: HIDPP.CustomReport, index i: UInt8) {
        Index = i
        backingDevice = dev
        ControlID = UInt16([UInt8](report.parameters[0..<2]))!.littleEndian
        TaskID = UInt16([UInt8](report.parameters[2..<4]))!.littleEndian
        Position = report.parameters[5]
        Group = report.parameters[6]
        GroupMask = report.parameters[7]
        Flags = UInt16(report.parameters[4]) + UInt16(report.parameters[8]) << 8
        Task {
            if await !refreshFields() {
                print("[E] Error while initializing key \(await FriendlyName)")
            } else {
                print("[I] Added reprogrammable key \"\(await FriendlyName)\"")
            }
        }
    }
}

struct ReprogControls {
    typealias Feature = HIDPP.v20.ReprogControls4
    private var backingDevice: HIDPP.Device
    private var KeyCount: UInt8
    var Keys: [ReprogKey] = []
    
    func getKeyGroup(_ groupID: UInt8) -> [ReprogKey] {
        var res: [ReprogKey] = []
        Keys.forEach { k in
            if k.Group == groupID {
                res.append(k)
            }
        }
        return res
    }
    
    func getKey(fromCID cid: UInt16) -> ReprogKey? {
        return Keys.first { k in
            k.ControlID == cid
        }
    }
    
    init? (backingDevice d: HIDPP.Device) {
        self.backingDevice = d
        guard let report = Feature.GetControlCount.Call(onDevice: d) else { return nil }
        if report.CheckError20() != .Success { return nil }
        self.KeyCount = report.parameters[0]

        print("[I] Querying \(self.KeyCount) reprogrammable keys on device \(backingDevice.name)")
        for i in 0..<self.KeyCount {
            guard let report = Feature.GetControlInfo.Call(onDevice: d, parameters: [i]) else {
                print("[W] Key \(i) expected on \(backingDevice.name), but not reported by device")
                continue
            }
            guard !report.isError20 else {
                print("[W] Key \(i) expected on \(backingDevice.name), but not reported by device")
                continue
            }
            Keys.append(ReprogKey(withDevice: backingDevice, report: report, index: i))
        }
    }
}
