//
//  MouseFactory.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 19/06/23.
//

import Foundation
import Combine
import SwiftUI



class DataSource: ObservableObject, Equatable {
    static func == (lhs: DataSource, rhs: DataSource) -> Bool {
        // TODO: make this actually useful
        lhs.mainMouse === rhs.mainMouse
    }

    private var mouseSink: AnyCancellable? = nil
    
    static var sharedInstance = DataSource()
    
    var mainMouseRef: Int? = nil
    var mainMouse: (any Mouse)? = nil {
        didSet {
            print("Replaced main instance")
            mainMouseRef = nil
            mouseSink?.cancel()
            mouseSink = nil
            if let m = mainMouse {
                print("Changing reference value to trigger events")
                mainMouseRef = Unmanaged.passUnretained(m as AnyObject).toOpaque().hashValue
                print("Setting update hook on \(m)")
                mouseSink = m.onUpdate {
                    DispatchQueue.main.async { self.objectWillChange.send() }
                }
            }
            self.objectWillChange.send()
        }
    }
    
    
}

class MouseFactory {
    enum Identifiers : MouseIdentifier, CaseIterable, Hashable {
        // Special identifiers that alias to some specific instances
        case Main
    }
    
    static private let MainChangedCallback: ((any Mouse)?, (any Mouse)?) -> () = { new, old in
        ConnectionWatcher.sharedInstance.updateStatus()
//        new?.view = ViewData.main
//        old?.view = ViewData()
        DispatchQueue.main.async {
            DataSource.sharedInstance.mainMouse = new
        }
        new?.refreshData()
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
        let oldMain = _mice[Identifiers.Main]
        guard let newMain = _mice.first(where: isReal)?.value else {
            _mice[Identifiers.Main] = nil
            MainChangedCallback(nil, oldMain)
            return
        }
        if newMain === _mice[Identifiers.Main] { return }
        print("There's a new sheriff in town! \(newMain.name)")
        MainChangedCallback(newMain, oldMain)
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
