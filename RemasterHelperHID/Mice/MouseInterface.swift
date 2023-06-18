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


// just to only have explicit identifiers
protocol MouseIdentifier : Hashable { }

// no chance this breaks everything, right?
struct MouseIdent: Hashable, Equatable {
    fileprivate let srcHash: Int
    
    init<T: Hashable>(_ ident: T) {
        srcHash = ident.hashValue
    }
}

extension Dictionary where Key == MouseIdent {
    mutating func removeValue(forKey key: any MouseIdentifier) -> Value? {
        return self.removeValue(forKey: Key(key))
    }
    
    subscript(key: any MouseIdentifier) -> Value? {
        get {
            return self.first { x in
                x.key == Key(key)
            }?.value
        }
        set {
            if newValue == nil {
                self.removeValue(forKey: Key(key))
            } else {
                self.updateValue(newValue!, forKey: Key(key))
            }
        }
    }
}

protocol Mouse : AnyObject {
    var identifier: any MouseIdentifier { get }
    var name: String { get }
    var view: ViewData { get set }
    
    func getBattery() -> UInt
    func getSupportedDPI() -> (UInt, UInt, UInt)?
    func getDPI() -> UInt
    func setDPI(to: UInt)
    func refreshData(delayed: Bool)
    
    init?(withHIDDevice d: HIDDevice, index i: UInt8)
}

extension Mouse {
    internal var CallbackBattery: UIntCallback { view.DefaultCallbackBat }
    internal var CallbackDPI: UIntCallback { view.DefaultCallbackDPI }
    internal var CallbackDPISupport: UIntTripletCallback { view.DefaultCallbackDPISupport }
    
    func refreshData(delayed: Bool = false) {
        DispatchQueue.global().async {
            if delayed { sleep(2) } // otherwise this won't work when first connecting
            _ = self.getBattery()
            _ = self.getDPI()
            _ = self.getSupportedDPI()
        }
    }
    
//    init?(withHIDDevice d: HIDDevice, index i: UInt8) { print("Device \(d) does not have a driver yet :("); return nil }
}

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
    static private let MainChangedCallback: ((any Mouse)?) -> () = { new in
        ConnectionWatcher.sharedInstance.updateStatus()
        new?.view = ViewData.main
        
        // TODO: if we ever have on-the-fly changing mains, change ViewData reference in old mouse instances
    }
    
    enum Identifiers : MouseIdentifier, CaseIterable, Hashable {
        // Special identifiers that alias to some specific instances
        case Main
    }
    static let isReal: ((key: MouseIdent, value: any Mouse)) -> (Bool) = {val in
        for i in Identifiers.allCases {
            if val.key.srcHash == i.hashValue { return false }
        }
        return true
    }
    
    static private var _mice: Dictionary<MouseIdent, any Mouse> = .init()
    static public var mice: Dictionary<MouseIdent, any Mouse> { _mice.filter(isReal) }
    
    static var defaultInstance: (any Mouse)? { _mice[Identifiers.Main] }
    static var miceCount: Int { _mice.filter(isReal).count }
    
    // TODO: for now just pick the first one, when we have favorites we'll change this
    static private func chooseMainInstance() {
        guard let newMain = _mice.first(where: isReal)?.value else {
            _mice[Identifiers.Main] = nil
            MainChangedCallback(nil)
            return
        }
        if newMain === _mice[Identifiers.Main] { return }
        print("There's a new sheriff in town! \(newMain.name)")
        MainChangedCallback(newMain)
        _mice[Identifiers.Main] = newMain
        newMain.refreshData()
        ConnectionWatcher.sharedInstance.updateStatus()
    }
    
    // This should be set as a callback for the HID Monitor
    static func addMouse(_ device: some Mouse) {
        _mice.updateValue(device, forKey: MouseIdent(device.identifier))
        chooseMainInstance()
        print("New mouse in da house! \(device.name)")
        print("\(miceCount) known mice currently here")
    }
    
    static func removeMouse(withIdentifier i: some MouseIdentifier) {
        let m = _mice.removeValue(forKey: i)
        if m == nil { return }
        chooseMainInstance()
        print("Mouse \(m?.name ?? "Unknown") left :(")
        print("\(miceCount) known mice currently here")
    }
    
    static func getMouse(withIdentifier i: some MouseIdentifier) -> (any Mouse)? {
        return _mice[i]
    }
    
}
