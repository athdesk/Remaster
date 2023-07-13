//
//  Bits.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 15/06/23.
//

import Foundation

class Weak<T: AnyObject> : ObservableObject {
  weak var value : T?
  init (value: T) {
    self.value = value
  }
}

func _convertToBytes<T>(_ value: T, withCapacity capacity: Int) -> [UInt8] {
    
    var mutableValue = value
    return withUnsafePointer(to: &mutableValue) {
        
        return $0.withMemoryRebound(to: UInt8.self, capacity: capacity) {
            
            return Array(UnsafeBufferPointer(start: $0, count: capacity))
        }
    }
}

extension UnsignedInteger {
    
    var bytes: [UInt8] {
        return _convertToBytes(self, withCapacity: MemoryLayout<Self>.size)
    }
    
    init?(_ bytes: [UInt8]) {
        guard bytes.count == MemoryLayout<Self>.size else { return nil }
        self = bytes.withUnsafeBytes {
            return $0.load(as: Self.self)
        }
    }
}

func DebugPrint(_ x: Any...) {
    #if DEBUG
    for i in x {
        print(i)
    }
    #endif
}

func DebugPrint(_ x: Any) {
    #if DEBUG
    print(x)
    #endif
}
