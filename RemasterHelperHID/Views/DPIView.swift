//
//  DPIView.swift
//  RemasterHelperHID
//
//  Created by Mario on 12/07/23.
//

import Foundation
import SwiftUI
import Combine

// Probably should make key weak too, but i'll try manual housekeeping first
fileprivate var Shims: Dictionary<MouseInterface, Weak<DPIShim>> = [:]

@MainActor
fileprivate class DPIShim : ObservableObject {
    private var sink: AnyCancellable?
    
    @Published var slider: Float = 0
    var bSlider: Binding<Float> { Binding(get: { self.slider }, set: { self.slider = $0 }) }
    var uSlider: UInt {
        get { UInt(slider) }
        set { slider = Float(newValue) }
        
    }
    
    static func shimForMouse(_ m: MouseInterface) -> DPIShim {
        // Reap dead values here
        Shims.forEach { pair in
            if pair.1.value == nil || !MouseTracker.global.mice.contains(where: { $0 == pair.0 }) {
                Shims.removeValue(forKey: pair.0)
            }
        }
        
        return Shims[m]?.value ?? Self.init(m)
    }
    
    fileprivate required init(_ m: MouseInterface) {
        sink = m.onUpdate {
            self.uSlider = m.DPI
        }
        self.uSlider = m.DPI
        Shims[m] = Weak(value: self)
    }
    
    deinit {
        sink?.cancel()
    }
}

struct DPIView: View {
    @ObservedObject var mouse: MouseInterface
    @ObservedObject private var dpi: Weak<DPIShim>
    
    var body: some View {
        if let dpi = self.dpi.value {
            VStack {
                HStack {
                    Text("DPI").font(.title2)
                    Spacer()
                    Text("\(UInt(dpi.uSlider))").font(.title)
                }
                .padding(.bottom, 6)
                Slider(value: dpi.bSlider,
                       in: ClosedRange(uncheckedBounds:
                                        (Float(mouse.SupportedDPI.min),
                                         Float(mouse.SupportedDPI.max))))
                { x in if !x { Task { await mouse.setDPI(dpi.uSlider) }}}
                    .onAppear() { dpi.uSlider = mouse.DPI }
                    .animation(.linear, value: dpi.slider)
                    .animation(.linear, value: mouse.DPI)
            }
            .transition(.scale)
            .padding(.horizontal, 6)
            .animation(.linear, value: dpi.slider)
        }
    }
    
    init(mouse: MouseInterface) {
        self.mouse = mouse
        dpi = Weak(value: DPIShim.shimForMouse(mouse))
    }
}
