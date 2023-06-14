//
//  Convenience.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation
import SwiftUI

private var lastGotDPI: UInt32 = 0

private var dpiLock = NSLock()
private var latestRequestedDPI: UInt32 = 0
private var dpiRequestRunning: Bool = false

extension SwiftMxDevice : ObservableObject {
    func restoreDesiredDPI() {
        setMouseDPI(val: DefaultMousePreferences.dpi)
    }
    
    private func _setMouseDPI() {
        if (!dpiLock.try()) {
            // Already running
            print("request failed")
            return
        }
        var settingTo: UInt32
        repeat {
            settingTo = latestRequestedDPI
            print("Setting DPI to \(settingTo), was \(lastGotDPI)")
            DefaultMousePreferences.dpi = settingTo
            self.setDPI(val: settingTo)
        } while (settingTo != latestRequestedDPI) // in case of request-spam
        dpiLock.unlock()
        DispatchQueue.global(qos: .background).async { self.checkDPIAndReport() }
    }
    
    func setMouseDPI(val: UInt32) {
        latestRequestedDPI = val
        print("DPI request \(val)")
        DispatchQueue.global(qos: .userInteractive).async {
            self._setMouseDPI()
        }
    }

    func checkDPIAndReport() {
        lastGotDPI = self.getDPI()
        ViewData.sharedInstance.setDPIReport(v: lastGotDPI)
    }

}
