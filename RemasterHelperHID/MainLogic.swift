//
//  MainLogic.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation
import IOKit.hid

fileprivate let hidMonitor = HIDDeviceMonitor(RemasterDevice.SupportedDevices, reportSize: 64)
func start() {
    Task {
        await hidMonitor.start()
    }
}
