//
//  MenuView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI

typealias UIntCallback = (UInt) -> ()
typealias UIntTripletCallback = (UInt, UInt, UInt) -> ()


let DefaultCallbackDPISupport: UIntTripletCallback = { x, y, z in
    ViewData.sharedInstance.setDPISupport(min: x, max: y, step: z)
}

let DefaultCallbackDPI: UIntCallback = { x in
    ViewData.sharedInstance.setDPIReport(v: x)
}

class ViewData : ObservableObject {
    
    static let sharedInstance = ViewData()
    
    @Published var StatusString: String = "Initializing ..."
    @Published var dpiReport: UInt = 0
    @Published var _dpiSupport: (UInt?, UInt?, UInt?) = (0, 0, 0) // Min, Max, Step
    
    struct DPISupport {
        var min: Float
        var max: Float
        var step: Float
    }
    
    var dpiSupport: DPISupport {
        // set defaults here
        DPISupport(min: Float(_dpiSupport.0 ?? 200),
                   max: Float(_dpiSupport.1 ?? 8000),
                   step: Float(_dpiSupport.2 ?? 200))
    }
    
    func setStatus(s: String) {
        DispatchQueue.main.async { self.StatusString = s }
    }
    
    func setDPIReport(v: UInt) {
        DispatchQueue.main.async { self.dpiReport = v }
    }
    
    func setDPISupport(min: UInt, max: UInt, step: UInt) {
        DispatchQueue.main.async {
            // We wrap into optionals here to keep callbacks and data functions simpler
            var localMin: UInt? = min
            var localMax: UInt? = max
            var localStep: UInt? = step
            if localMin == 0 { localMin = nil }
            if localMax == 0 { localMax = nil }
            if localStep == 0 { localStep = nil }
            
            self._dpiSupport = (localMin, localMax, localStep)
        }
    }
    
}

struct MenuView: View {
    @State var dpiSlider: Float = Float(DefaultMousePreferences.dpi)
    @ObservedObject var data: ViewData = ViewData.sharedInstance
    @ObservedObject var watcher: ConnectionWatcher = ConnectionWatcher.sharedInstance
    
    var body: some View {
        VStack {
            Text("Current DPI: \(data.dpiReport)")
            Slider(value: $dpiSlider, in: ClosedRange(uncheckedBounds: (data.dpiSupport.min, data.dpiSupport.max)),
//                   step: data.dpiSupport.step,
                   onEditingChanged: { x in
                if !x {
                    DispatchQueue.global(qos: .utility).async {
                        MouseFactory.defaultInstance?.setDPI(to: UInt(dpiSlider)) }
                }
            })
                .disabled(!watcher.isMainAvailable)
            
        }
        .padding(16)
        .frame(maxWidth: 240)
    }
}
