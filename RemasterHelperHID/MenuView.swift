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

class ViewData : ObservableObject, Equatable {
    private func checkUpdateRef() {
//        if ViewData.mainDeviceRef === self {
//            ViewData.set(to: self)
//        }
    }
    
    var DefaultStatusCallback: StringCallback {{ s in
        self.setStatus(s: s)
        self.checkUpdateRef()
    }}

    var DefaultCallbackDPISupport: UIntTripletCallback {{ x, y, z in
        self.setDPISupport(min: x, max: y, step: z)
        self.checkUpdateRef()
    }}

    var DefaultCallbackDPI: UIntCallback {{ x in
        self.setDPIReport(v: x)
        self.checkUpdateRef()
    }}

    var DefaultCallbackBat: UIntCallback {{ x in
        self.setBatReport(v: x)
        self.checkUpdateRef()
    }}
    
    static func == (lhs: ViewData, rhs: ViewData) -> Bool {
        lhs.statusString == rhs.statusString &&
        lhs.dpiReport == rhs.dpiReport &&
        lhs.batReport == rhs.batReport &&
        lhs.dpiSupport == rhs.dpiSupport
    }
    
    
    static var main = ViewData()
    
    // here just to keep track of things
//    static var mainDeviceRef: ViewData?
    
    static func set(to v: ViewData) {
        Self.main.setStatus(s: v.statusString)
        Self.main.setBatReport(v: v.batReport)
        Self.main.setDPIReport(v: v._dpiReport)
        Self.main.setDPISupport(min: v._dpiSupport.0 ?? 0,
                                max: v._dpiSupport.1 ?? 0,
                                step: v._dpiSupport.2 ?? 0)
    }
    
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
    
    
    struct DPISupport : Equatable {
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
        VStack {
            Text("Current DPI: \(data._dpiReport)")
            Slider(value: $dpiSlider,
                   in: ClosedRange(uncheckedBounds: (data.dpiSupport.min, data.dpiSupport.max)),
                   onEditingChanged: { x in if !x { data.dpiReport = dpiSlider} })
            .onChange(of: data.dpiReport) { newValue in dpiSlider = newValue }
        }
        .animation(.default, value: data)
    }
}

struct MenuView: View {
    @ObservedObject var data: ViewData = ViewData.main
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
