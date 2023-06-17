//
//  SwiftMX.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation

extension String : Error {} // Just makes throwing errors not a pain

class SwiftMxDevice {
    var devPath: String
    var devIndex: Int32
    var mxDev: MxHIDDevice = MxHIDDevice()
    
    static var activeInstances: Int = 0
    
    func getDPI() -> UInt32 {
        return mxDev.getDPI()
    }
    
    func setDPI(val: UInt32) {
        mxDev.setDPI(val)
    }
    
    init(devPath: String, devIndex: Int32) throws {
        self.devPath = devPath
        self.devIndex = devIndex
        
        // Basic checks to avoid segfaulting every time nothing is connected
        guard devPath.contains("dev://") else { throw "Device path not valid" }
        guard devIndex > -1 && devIndex != 255 else { throw "Device index not valid" }
        print("Device path checks: OK")
        
        guard mxDev.initialize(withDevpath: devPath, index: devIndex) else { throw "Could not initialize device" }
        
        print("MxDevice initialized")
        SwiftMxDevice.activeInstances += 1
        ConnectionWatcher.sharedInstance.updateStatus()
    }
    
    convenience init(devPath: String, devIndex:Int32, callback:(SwiftMxDevice)->Void) throws {
        try self.init(devPath: devPath, devIndex: devIndex)
        callback(self)
    }
    
    deinit {
        print("Destroying MxDevice")
        if SwiftMxDevice.activeInstances == 0 {
            print("This should never happen")
            abort()
        }
        SwiftMxDevice.activeInstances -= 1
        ConnectionWatcher.sharedInstance.updateStatus()
    }
}
