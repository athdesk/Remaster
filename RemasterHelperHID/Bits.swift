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

extension Data {
    var hexDescriptionPacked: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x ", $1)}
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
