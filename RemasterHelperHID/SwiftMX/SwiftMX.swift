//
//  SwiftMX.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation

extension String : Error {} // Just makes throwing errors not a pain

class ConnectionWatcher : ObservableObject {
    static let sharedInstance = ConnectionWatcher()
    @Published var status: Bool = false
    
    func updateStatus(to: Bool? = nil) {
        if let to = to {
            status = to
        } else {
            status = CurrentMXDevice != nil
        }
        print("Connection status UI elements now are: \(status)")
    }
}

class SwiftMxDevice {
    var devPath: String
    var devIndex: Int32
    var mxDev: MxHIDDevice

    func getDPI() -> UInt32 {
        return mxDev.getDPI()
    }
    
    func setDPI(val: UInt32) {
        mxDev.setDPI(val)
    }
    
    init(devPath: String, devIndex: Int32) throws {
        self.devPath = devPath
        self.devIndex = devIndex
        let mx = MxHIDDevice()
        
        // Basic checks to avoid segfaulting every time nothing is connected
        guard devPath.contains("dev://") else { throw "Device path not valid" }
        guard devIndex > -1 && devIndex != 255 else { throw "Device index not valid" }
        
        guard mx.initialize(withDevpath: devPath, index: devIndex) else { throw "Could not initialize device" }
        mxDev = mx
        ConnectionWatcher.sharedInstance.updateStatus(to: true)
    }
    
    
    deinit {
        ConnectionWatcher.sharedInstance.updateStatus(to: false)
    }
}
