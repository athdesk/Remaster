//
//  MouseInterface.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

// Class for interfacing with #.*.*.# a mouse #.*.*.# :)
//
// the `defaultInstance` should always try to represent a connected mouse
// this means that it's going to be mutating without telling anyone
// (or maybe send a notification, but it's better for most of the
//      data to not be targeted at one specific device)
// Also, devices are expected to disconnect/reconnect at random,
//      especially for Bluetooth, so we might need to be a bit
//      clever in the way we reapply settings etc.

protocol Mouse : AnyObject {
    var identifier: any MouseIdentifier { get }
    var name: String { get }
    var view: ViewData { get set }

    var EventDPI: EventCallback { get }
    var EventWheel: EventCallback { get }
   
    func getSmartShift() -> UInt?
    func setSmartShift(to: UInt)
    func getRatchet() -> Bool?
    func setRatchet(to: Bool)
    func toggleRatchet()
    
    func getBattery() -> UInt
    
    func getSupportedDPI() -> (UInt, UInt, UInt)?
    func getDPI() -> UInt
    func setDPI(to: UInt)
    
    func refreshData(delayed: Bool)
    
    init?(withHIDDevice d: HIDDevice, index i: UInt8)
}

extension Mouse {
    
    internal var CallbackBattery: UIntCallback { view.DefaultBatteryCallback }
    internal var CallbackDPI: UIntCallback { view.DefaultDPICallback }
    internal var CallbackDPISupport: UIntTripletCallback { view.DefaultDPISupportCallback }
    internal var CallbackRatchet: BoolOptCallback { view.DefaultRatchetCallback }
    internal var CallbackSmartShift: UIntOptCallback { view.DefaultSmartShiftCallback }
    
    func refreshData(delayed: Bool = false) {
        DispatchQueue.global().async {
            if delayed { sleep(2) }
            self.view.DefaultStatusCallback(self.name)
            _ = self.getBattery()
            _ = self.getDPI()
            _ = self.getSupportedDPI()
            _ = self.getRatchet()
            _ = self.getSmartShift()
        }
    }

}


