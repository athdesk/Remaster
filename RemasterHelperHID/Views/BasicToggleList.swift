//
//  ToggleList.swift
//  RemasterHelperHID
//
//  Created by Mario on 12/07/23.
//

import SwiftUI

struct BasicToggleList: View {
    @ObservedObject var mouse: MouseInterface
    @State private var ssSlider: Float = 0

    var body: some View {
        if let v = mouse.Ratchet {
            Toggle(isOn: Binding(get: {v}, set: { _ in Task { await mouse.toggleRatchet() } }))
            { ListText("Ratchet") }
                .animation(.default, value: v)
            if v && mouse.SmartShift != 0 {
                HStack { // SmartShift slider
                    Image(systemName: "s.circle.fill")
                        .font(.title3)
                    Slider(value: $ssSlider, in: ClosedRange(uncheckedBounds: (1, 128)))
                    { x in if !x { Task.init { await mouse.setSmartShift(UInt(ssSlider)) }}}
                        .onAppear() { ssSlider = Float(mouse.SmartShift ?? 40) }
                }
                .padding(8)
            }
        }
        if let v = mouse.WheelInvert {
            Toggle(isOn: Binding(get: {v}, set: { _ in Task { await mouse.toggleWheelInvert() } }))
            { ListText("Scroll Wheel Inversion") }
        }
        if let v = mouse.WheelHiRes {
            Toggle(isOn: Binding(get: {v}, set: { _ in Task { await mouse.toggleWheelHiRes() } }))
            { ListText("High Resolution Wheel") }
        }
        if mouse.WheelHiRes != nil || mouse.WheelInvert != nil || mouse.Ratchet != nil {
            Spacer()
        }
    }
}

struct ToggleList_Previews: PreviewProvider {
    static var previews: some View {
        if let m = MouseTracker.global.mainMouse {
            BasicToggleList(mouse: m)
        }
    }
}
