//
//  Utilities.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 19/06/23.
//

import Foundation

enum ReceiverType : CaseIterable {
    case Bolt
    case Unifying
}

enum TransportType {
    case Wired
    case Bluetooth
    case Receiver(ReceiverType)
}

struct DPISupport {
    let min: UInt = 1000
    let max: UInt = 2000
    let step: UInt?
}

// just to only have explicit identifiers
protocol MouseIdentifier : Hashable { }

// no chance this breaks everything, right?
struct MouseIdent: Hashable, Equatable {
    let srcHash: Int
    
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


typealias UIntCallback = (UInt) -> ()
typealias UIntOptCallback = (UInt?) -> ()
typealias UIntTripletCallback = (UInt, UInt, UInt) -> ()
typealias StringCallback = (String) -> ()
typealias BoolOptCallback = (Bool?) -> ()

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
