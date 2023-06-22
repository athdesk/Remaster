//
//  MouseFactory.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 19/06/23.
//

import Foundation
import Combine
import SwiftUI

class MouseFactory : ObservableObject {
    enum Identifiers : MouseIdentifier, CaseIterable, Hashable {
        // Special identifiers that alias to some specific instances
        case Main
    }
    
    private var mouseSink: AnyCancellable? = nil
    func MainChangedCallback(_ new:(any Mouse)?, _ old: (any Mouse)?) async {
        mouseSink?.cancel()
        mouseSink = nil
        if let m = new {
            mouseSink = m.onUpdate {  DispatchQueue.main.async { self.objectWillChange.send() } }
        }
    }
    
    let isReal: ((key: MouseIdent, value: any Mouse)) -> (Bool) = {val in
        for i in Identifiers.allCases {
            if val.key.srcHash == i.hashValue { return false }
        }
        return true
    }
    
    private var _mice: Dictionary<MouseIdent, any Mouse> = .init() {
        didSet {
            // Send a notification every time something changes here, for the settings mainly
            DispatchQueue.main.async { self.objectWillChange.send() }
        }
    }
    public var mice: Dictionary<MouseIdent, any Mouse> { _mice.filter(isReal) }
    
    var mainMouse: (any Mouse)? { _mice[Identifiers.Main] }
    var miceCount: Int { _mice.filter(isReal).count }
    
    // TODO: for now just pick the first one, when we have favorites we'll change this
    private func chooseMainInstance() {
        let oldMain = _mice[Identifiers.Main]
        guard let newMain = _mice.first(where: isReal)?.value else {
            _mice[Identifiers.Main] = nil
            Task { await MainChangedCallback(nil, oldMain) }
            return
        }
        if newMain === _mice[Identifiers.Main] { return }
        print("There's a new sheriff in town! \(newMain.name)")
        Task { await MainChangedCallback(newMain, oldMain) }
        _mice[Identifiers.Main] = newMain
        newMain.refreshData()
    }
    
    // This should be set as a callback for the HID Monitor
    func addMouse(_ device: some Mouse) {
        _mice.updateValue(device, forKey: MouseIdent(device.identifier))
        chooseMainInstance()
        print("New mouse in da house! \(device.name)")
        print("\(miceCount) known mice currently here")
    }
    
    func removeMouse(withIdentifier i: some MouseIdentifier) {
        let m = _mice.removeValue(forKey: i)
        if m == nil { return }
        chooseMainInstance()
        print("Mouse \(m?.name ?? "Unknown") left :(")
        print("\(miceCount) known mice currently here")
    }
    
    func getMouse(withIdentifier i: some MouseIdentifier) -> (any Mouse)? {
        return _mice[i]
    }
    
    static let sharedInstance: MouseFactory = MouseFactory()
    
    private init(){
        
    }
}
