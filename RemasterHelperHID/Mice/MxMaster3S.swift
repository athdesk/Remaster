//
//  MxMaster3S.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 17/06/23.
//

import Foundation

class MxMaster3SDevice : GenericV20Device {
    override func setDPI(to n: UInt) {
        var p: [UInt8] = [0] // 0 is sensorId
        let n16 = UInt16(n)
        p.append(contentsOf: n16.bigEndian.bytes)
        _ = Proto.AdjustableDPI.SetSensorDPI.Call(onDevice: backingDevice, parameters: p)
        _ = getDPI()
    }
}
