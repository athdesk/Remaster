//
//  Preferences.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation

var DefaultMousePreferences = MousePreferences(id: "default")

struct MousePreferences {
    enum Key : Codable {
        case DPI
        case SmartShift
    }
    
    private var id: String
    private var backingDict: Dictionary<Key, Int64> // This is going to be ugly if we ever need non-numeric preferences
    
    var dpi: UInt {
        get { UInt(getVal(key: .DPI))  }
        set { setVal(key: .DPI, val: Int64(newValue)) }
    }
    
    var smartShift: UInt {
        get { UInt(getVal(key: .DPI))  }
        set { setVal(key: .SmartShift, val: Int64(newValue)) }
    }
    
    private func getDefault(key: Key) -> Int64 {
        switch key {
        case .DPI: return 1200
        case .SmartShift: return 40
        }
    }
    
    private func getVal(key: Key) -> Int64 {
        let v = backingDict[key]
        return v ?? getDefault(key: key)
    }
    
    private mutating func setVal(key: Key, val: Int64) {
        backingDict[key] = val
        guard let encodedDict = try? JSONEncoder().encode(backingDict) else { return } // fail silently
        UserDefaults.standard.set(encodedDict, forKey: id)
    }
    
    init(id: String, reset: Bool = false) {
        self.id = id
        backingDict = Dictionary<Key, Int64>()
        
        let prefsOpt = UserDefaults.standard.object(forKey: id)
        if (!reset || prefsOpt != nil) {
            if let prefsData = prefsOpt as? Data {
                backingDict = (try? JSONDecoder().decode(Dictionary<Key, Int64>.self, from: prefsData)) ?? backingDict
            }
        }
    }
}
