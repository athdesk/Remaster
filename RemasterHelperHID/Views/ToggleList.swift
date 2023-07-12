//
//  ToggleList.swift
//  RemasterHelperHID
//
//  Created by Mario on 12/07/23.
//

import SwiftUI

struct DiversionSelector<T: StringProtocol, Content: View>: View {
    let choices: Array<T>
    @Binding var selection: T
    let title: () -> Content
    var body: some View {
        HStack {
            title()
            Spacer()
            Menu {
                ForEach(choices, id: \.self) { s in
                    Button(s) { selection = s }
                }
            } label: {
                Text(selection)
            }
            .menuStyle(.borderlessButton)
        }
    }
}

struct ToggleList: View {
    @ObservedObject var mouse: MouseInterface
    @State private var ssSlider: Float = 0
    
    //TODO: bind these directly to the mouse
    @State private var selVWheel = "Default"
    @State private var selHWheel = "Default"
    @State private var selGestures = "Default"
   
    // TODO: make these an enum
    let btnPickerChoices = ["Left Click", "Right Click", "Middle Click", "Button 4", "Button 5", "Button 6"]
    let movPickerChoices = ["Controlled by Remaster", "Default"]
    
    var body: some View {
        List { // Toggles
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
            Divider()
            // TODO: add diversion capability checks
            DiversionSelector(choices: movPickerChoices, selection: $selVWheel) {
                ListText("Scroll Wheel").frame(maxWidth: .infinity, alignment: .leading)
            }
            DiversionSelector(choices: movPickerChoices, selection: $selHWheel) {
                ListText("Thumb Wheel").frame(maxWidth: .infinity, alignment: .leading)
            }
            DiversionSelector(choices: movPickerChoices, selection: $selGestures) {
                ListText("Gestures").frame(maxWidth: .infinity, alignment: .leading)
            }
            
//                Picker(selection: $selWheel, content: {
//                    ForEach(movPickerChoices, id: \.self) {
//                        Text($0)
//                    }
//                }, label: {
//                    ListText("Scroll Wheel")
//                })
//                .pickerStyle(.menu)
//
            
        }
    }
}

struct ToggleList_Previews: PreviewProvider {
    static var previews: some View {
        if let m = MouseTracker.global.mainMouse {
            ToggleList(mouse: m)
        }
    }
}
