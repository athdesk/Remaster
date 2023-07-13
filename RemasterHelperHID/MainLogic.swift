//
//  MainLogic.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import Foundation
import IOKit.hid

func start() {
    let hidMonitor = HIDDeviceMonitor(RemasterDevice.SupportedDevices, reportSize: 64)

    Task {
        await hidMonitor.start()
    }
}
