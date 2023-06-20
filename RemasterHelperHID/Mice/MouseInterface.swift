//
//  MouseInterface.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation
import Combine

// Class for interfacing with #.*.*.# a mouse #.*.*.# :)
//
// the `mainMouse` should always try to represent a connected mouse
// this means that it's going to be mutating without telling anyone
// (or maybe send a notification, but it's better for most of the
//      data to not be targeted at one specific device)
// Also, devices are expected to disconnect/reconnect at random,
//      especially for Bluetooth, so we might need to be a bit
//      clever in the way we reapply settings etc.

protocol Mouse : AnyObject, ObservableObject {
    var identifier: any MouseIdentifier { get }
    var name: String { get }
    var transport: TransportType { get }

//   Events have to be manually specified by drivers
//    var EventBattery: EventCallback { get }
//    var EventDPI: EventCallback { get }
//    var EventWheel: EventCallback { get }
    
    var Ratchet: Bool? { get set }
    var SmartShift: UInt? { get set }
    var WheelInvert: Bool? { get set }
    var WheelHiRes: Bool? { get set }
    var WheelDiversion: Bool? { get set }
    
    var Battery: Battery? { get }
    
    var DPI: UInt { get set }
    var SupportedDPI: DPISupport { get }
    
    func refreshData()
    
    init?(withHIDDevice d: HIDDevice, index i: UInt8)
}

extension Mouse {
    func onUpdate(_ clause: @escaping () -> () ) -> AnyCancellable? {
        print("onUpdate()")
        return objectWillChange.sink { _ in clause() }
    }
}
