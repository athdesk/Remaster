//
//  Convenience.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 14/06/23.
//

import Foundation
import SwiftUI

extension SwiftMxDevice : ObservableObject {
    static var desiredDPI: UInt32 = 1200
    func setMouseDPI(val: UInt32) {
        print("Setting DPI to \(val)")
        self.setDPI(val: val)
        checkDPIAndReport()
    }

    func checkDPIAndReport() {
        ViewData.sharedInstance.setDPIReport(v: self.getDPI())
    }

}
