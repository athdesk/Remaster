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
    func getSupportedDPI() -> (UInt, UInt, UInt)
    func getDPI() -> UInt
    func setDPI(to: UInt)
    func refreshData(delayed: Bool)
    init?(withHIDDevice d: HIDDevice, index i: UInt8)
}

extension Mouse {
    // TODO: callbacks have to be disabled/changed for non-main devices
    internal var CallbackDPI: UIntCallback { DefaultCallbackDPI }
    internal var CallbackDPISupport: UIntTripletCallback { DefaultCallbackDPISupport }
    
    func refreshData(delayed: Bool = false) {
        DispatchQueue.global().async {
            if delayed { sleep(2) } // otherwise this won't work when first connecting
            _ = self.getDPI()
            _ = self.getSupportedDPI()
        }
    }
    
    init?(withHIDDevice d: HIDDevice, index i: UInt8) { print("Device \(d) does not have a driver yet :("); return nil }
}

// just to only have explicit identifiers
protocol MouseIdentifier : Hashable { }

// much swiftui
class ConnectionWatcher : ObservableObject {
    static let sharedInstance = ConnectionWatcher()
    @Published var isMainAvailable: Bool = false
    
    func updateStatus() {
        DispatchQueue.main.async { [self] in
            isMainAvailable = MouseFactory.defaultInstance != nil
        }
    }
}

class MouseFactory {
    enum Identifiers : MouseIdentifier, CaseIterable {
        // Special identifiers that alias to some specific instances
        case Main
    }
    static let isReal: ((key: AnyHashable, value: any Mouse)) -> (Bool) = {val in
        for i in Identifiers.allCases {
            if val.key.hashValue == i.hashValue { return false }
        }
        return true
    }
    
    static private var mice: Dictionary<AnyHashable, any Mouse> = .init()
    static var defaultInstance: (any Mouse)? { mice[Identifiers.Main] }
    static var miceCount: Int { mice.filter(isReal).count }
    
    // TODO: for now just pick the first one, when we have favorites we'll change this
    static private func chooseMainInstance() {
        guard let newMain = mice.first(where: isReal)?.value else { return }
        if newMain === mice[Identifiers.Main] { return }
        print("There's a new sheriff in town! \(newMain)")
        mice[Identifiers.Main] = newMain
        newMain.refreshData()
        ConnectionWatcher.sharedInstance.updateStatus()
    }
    
    // This should be set as a callback for the HID Monitor
    static func addMouse(withIdentifier i: some MouseIdentifier, device: some Mouse) {
        mice[i] = device
        chooseMainInstance()
        print("New mouse in da house! \(i)")
        print("\(miceCount) known mice currently here")
    }
    
    static func removeMouse(withIdentifier i: some MouseIdentifier) {
        mice.removeValue(forKey: i)
        chooseMainInstance()
        print("Mouse \(i) left :(")
        print("\(miceCount) known mice currently here")
    }
    
    static func getMouse(withIdentifier i: some MouseIdentifier) -> (any Mouse)? {
        return mice[i]
    }
    
}
