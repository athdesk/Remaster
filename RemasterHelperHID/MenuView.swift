//
//  MenuView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI

class ViewData : ObservableObject, Equatable {
    private func checkUpdateRef() {
//        if ViewData.mainDeviceRef === self {
//            ViewData.set(to: self)
//        }
    }
    
    var DefaultSmartShiftCallback: UIntOptCallback {{ v in
        print("\(#function) \(String(describing: v))")
        self.setSmartShift(v: v)
        self.checkUpdateRef()
    }}
    
    var DefaultRatchetCallback: BoolOptCallback {{ v in
        print("\(#function) \(String(describing: v))")
        self.setRatchet(b: v)
        self.checkUpdateRef()
    }}
    
    var DefaultStatusCallback: StringCallback {{ v in
        print("\(#function) \(String(describing: v))")
        self.setStatus(s: v)
        self.checkUpdateRef()
    }}

    var DefaultDPISupportCallback: UIntTripletCallback {{ x, y, z in
        self.setDPISupport(min: x, max: y, step: z)
        self.checkUpdateRef()
    }}

    var DefaultDPICallback: UIntCallback {{ v in
        print("\(#function) \(String(describing: v))")
        self.setDPIReport(v: v)
        self.checkUpdateRef()
    }}

    var DefaultBatteryCallback: UIntCallback {{ v in
        print("\(#function) \(String(describing: v))")
        self.setBatReport(v: v)
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
    
    let defaultStatus = "No Mouse Connected"
    @Published var statusString: String = "No Mouse Connected"
    
    @Published var batReport: UInt = 0
    
    @Published var _smartShift: UInt? = 0
    var smartShift: Float { Float(_smartShift ?? 0) }
    
    @Published var ratchet: Bool?
    
    @Published var _dpiReport: UInt = DefaultMousePreferences.dpi
    var dpiReport: Float { Float(_dpiReport) }
    
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
    
    func setRatchet(b: Bool?) {
        DispatchQueue.main.async { self.ratchet = b }
    }
    
    func setSmartShift(v: UInt?) {
        DispatchQueue.main.async { self._smartShift = v }
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
    @EnvironmentObject var watcher: ConnectionWatcher
    var body: some View {
        HStack {
            Text(watcher.isMainAvailable ? data.statusString : data.defaultStatus)
            if watcher.isMainAvailable {
                if data.batReport != 0 {
                    Text("\(data.batReport)%")
                }
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
                   in: ClosedRange(uncheckedBounds: (data.dpiSupport.min, data.dpiSupport.max)))
                    { x in if !x { MouseFactory.defaultInstance?.setDPI(to: UInt(dpiSlider)) }}
        }
        .onChange(of: data.dpiReport) { newValue in dpiSlider = newValue }
        .animation(.easeInOut, value: data)
    }
}

struct SwitchView: View {
    @EnvironmentObject var data: ViewData
    @State var ssSlider: Float = Float(DefaultMousePreferences.smartShift)
    var body: some View {
        VStack {
            HStack {
                if let r = data.ratchet {
                    Button {
                        MouseFactory.defaultInstance?.toggleRatchet()
                    } label: { Image(systemName: "pin")
                        .frame(maxWidth: .infinity)
                        .symbolVariant(.fill)
                        .symbolVariant(r ? .none : .slash)
                        .foregroundColor(r ? .accentColor : .primary)
                    }
                }
                Button {
                    
                } label: { Image(systemName: "arrow.up.and.down.square.fill").frame(maxWidth: .infinity) }
                
                Button {
                    
                } label: { Image(systemName: "ellipsis").frame(maxWidth: .infinity) }
            }
            .font(.title)
            .padding(.vertical, 4)
            .buttonStyle(.plain)
            .font(.title2)
            if data.ratchet == true && data.smartShift != 0 {
                HStack {
                    Image(systemName: "s.circle.fill")
                        .font(.title3)
                    Slider(value: $ssSlider,
                           in: ClosedRange(uncheckedBounds: (1, 49)))
                    { x in if !x { MouseFactory.defaultInstance?.setSmartShift(to: UInt(ssSlider)) } }
                        .animation(.easeInOut(duration: 1), value: data.ratchet)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
        .symbolRenderingMode(.hierarchical)
        .onChange(of: data.smartShift) { newValue in ssSlider = newValue }
        .animation(.easeInOut, value: data)
    }
}


struct MenuView: View {
    @ObservedObject var data: ViewData = ViewData.main
    @ObservedObject var watcher: ConnectionWatcher = ConnectionWatcher.sharedInstance
    
    var body: some View {
        VStack {
            StatusView()
                .environmentObject(data)
                .environmentObject(watcher)
            Divider()
                .padding(6)
            DPIView()
                .environmentObject(data)
            Divider()
                .padding(6)
            SwitchView()
                .environmentObject(data)
            Divider()
                .padding(6)
        }
        .padding(16)
        .frame(maxWidth: 240)
        .disabled(!watcher.isMainAvailable)
    }
}
