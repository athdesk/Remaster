//
//  MenuView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI

// Bindings don't work, this is a dirty workaround, but eh
// Also no need for `inout` anymore when passing this
class ViewData : ObservableObject {
    
    static let sharedInstance = ViewData()
    
    @Published var StatusString: String = "Initializing ..."
    @Published var dpiReport: UInt32 = 0
    
    func setStatus(s: String) {
        DispatchQueue.main.async { self.StatusString = s }
    }
    
    func setDPIReport(v: UInt32) {
        print("Now setting dpi report to \(v)")
        DispatchQueue.main.async { self.dpiReport = v }
    }
    
}

struct MenuView: View {
    @State var dpiSlider: Float = 1200.0
    @ObservedObject var data: ViewData = ViewData.sharedInstance
    @State var DeviceConnected: Bool = false
    
    var body: some View {
        VStack {
            Text("Current DPI: \(data.dpiReport)")
            Slider(value: $dpiSlider, in: ClosedRange(uncheckedBounds: (100, 8000)), step: 200.0, onEditingChanged: { x in
                if (!x) {
                    if (CurrentMXDevice != nil) {
                        CurrentMXDevice!.setMouseDPI(val: UInt32(dpiSlider))
                    }
                }
            })
            .disabled(DeviceConnected)
            
        }
        .padding(16)
        .frame(maxWidth: 240)
        .onAppear()
    }
}
