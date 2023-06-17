//
//  MenuView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI

typealias UIntCallback = (UInt) -> ()
typealias UIntTripletCallback = (UInt, UInt, UInt) -> ()
typealias StringCallback = (String) -> ()

let DefaultStatusCallback: StringCallback = { s in
    ViewData.sharedInstance.setStatus(s: s)
}

let DefaultCallbackDPISupport: UIntTripletCallback = { x, y, z in
    ViewData.sharedInstance.setDPISupport(min: x, max: y, step: z)
}

let DefaultCallbackDPI: UIntCallback = { x in
    ViewData.sharedInstance.setDPIReport(v: x)
}

let DefaultCallbackBat: UIntCallback = { x in
    ViewData.sharedInstance.setBatReport(v: x)
}

class ViewData : ObservableObject {
    
    static let sharedInstance = ViewData()
    
    @Published var statusString: String = "No Mouse Connected"
    
    @Published var batReport: UInt = 0
    @Published var _dpiReport: UInt = DefaultMousePreferences.dpi
    var dpiReport: Float {
        get { Float(_dpiReport) }
        set {
            DispatchQueue.global(qos: .utility).async {
                MouseFactory.defaultInstance?.setDPI(to: UInt(newValue))
            }
        }
    }
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
    
    func setBatReport(v: UInt) {
        DispatchQueue.main.async { self.batReport = v }
    }
    
    func setStatus(s: String) {
        DispatchQueue.main.async { self.statusString = s }
    }
    
    func setDPIReport(v: UInt) {
        DispatchQueue.main.async { self._dpiReport = v }
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

struct StatusView: View {
    @EnvironmentObject var data: ViewData
    var body: some View {
        HStack {
            Text(data.statusString)
            if data.batReport != 0 {
                Text("\(data.batReport)%")
            }
        }
    }
}

struct DPIView: View {
    @EnvironmentObject var data: ViewData
    @State var dpiSlider: Float = Float(DefaultMousePreferences.dpi)
    var body: some View {
        Text("Current DPI: \(data._dpiReport)")
        Slider(value: $dpiSlider,
               in: ClosedRange(uncheckedBounds: (data.dpiSupport.min, data.dpiSupport.max)),
        onEditingChanged: { x in
            if !x {
                data.dpiReport = dpiSlider
            }
        })
    }
}

struct MenuView: View {
    @ObservedObject var data: ViewData = ViewData.sharedInstance
    @ObservedObject var watcher: ConnectionWatcher = ConnectionWatcher.sharedInstance
    
    var body: some View {
        VStack {
            StatusView()
                .environmentObject(data)
            Divider()
                .padding(6)
            DPIView()
                .environmentObject(data)
                .disabled(!watcher.isMainAvailable)
            
        }
        .padding(16)
        .frame(maxWidth: 240)
    }
}
