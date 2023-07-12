//
//  Utilities.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 19/06/23.
//

import Foundation

enum TransportType {
    case Wired
    case Bluetooth
    case Receiver(ReceiverType)
}

struct DPISupport {
    let min: UInt
    let max: UInt
    let step: UInt?
}

struct Battery {
    let Percent: UInt
    let Charging: Bool
}

// no chance this breaks everything, right?
//struct MouseIdent: Hashable, Equatable {
//    let srcHash: Int
//    
//    init<T: Hashable>(_ ident: T) {
//        srcHash = ident.hashValue
//    }
//}
//
//extension Dictionary where Key == MouseIdent {
//    mutating func removeValue(forKey key: any MouseIdentifier) -> Value? {
//        return self.removeValue(forKey: Key(key))
//    }
//
//    subscript(key: any MouseIdentifier) -> Value? {
//        get {
//            return self.first { x in
//                x.key == Key(key)
//            }?.value
//        }
//        set {
//            if newValue == nil {
//                self.removeValue(forKey: Key(key))
//            } else {
//                self.updateValue(newValue!, forKey: Key(key))
//            }
//        }
//    }
//}

//
//typealias UIntCallback = (UInt) -> ()
//typealias UIntOptCallback = (UInt?) -> ()
//typealias UIntTripletCallback = (UInt, UInt, UInt) -> ()
//typealias StringCallback = (String) -> ()
//typealias BoolOptCallback = (Bool?) -> ()
