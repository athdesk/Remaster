//
//  ToggleList.swift
//  RemasterHelperHID
//
//  Created by Mario on 12/07/23.
//

import SwiftUI

protocol ReprogChoice : Hashable {
    func str() -> String
}

struct ReprogSelector<T: ReprogChoice, Content: View>: View {
    let choices: [T]
    @Binding var selection: T
    let title: () -> Content
    var body: some View {
        HStack {
            title()
            Spacer()
            Menu {
                ForEach(choices, id: \.self) { s in
                    Button(s.str()) { selection = s }
                }
            } label: {
                Text(selection.str())
            }
            .menuStyle(.borderlessButton)
        }
    }
}

enum DiversionChoice: ReprogChoice {
    case Default
    case Diverted
    
    func bool() -> Bool {
        switch self {
        case .Default: return false
        case .Diverted: return true
        }
    }
    
    func str() -> String {
        switch self {
        case .Default:
            return "Default"
        case .Diverted:
            return "Controlled by Remaster"
        }
    }
}

struct ToggleList: View {
    @ObservedObject var mouse: MouseInterface
    @State private var ssSlider: Float = 0
    
    //TODO: bind these directly to the mouse
    private var selVWheel: Binding<DiversionChoice> { Binding {
        switch mouse.WheelDiversion {
        case true:
            return .Diverted
        case false:
            return .Default
        case .none:
            return .Default
        case .some(_):
            return .Default
        }
    } set: { v in Task {
        if v.bool() != mouse.WheelDiversion { await mouse.toggleWheelDiversion() }
    }}}
    
    private var selHWheel: Binding<DiversionChoice> { Binding {
        switch mouse.HWheelDiversion {
        case true:
            return .Diverted
        case false:
            return .Default
        case .none:
            return .Default
        case .some(_):
            return .Default
        }
    } set: { v in Task {
        if v.bool() != mouse.HWheelDiversion { await mouse.toggleHWheelDiversion() }
    }}}
    
    @State private var selGestures = DiversionChoice.Default
   
    let divPickerChoices = [DiversionChoice.Default, DiversionChoice.Diverted]
    
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
            if mouse.WheelHiRes != nil || mouse.WheelInvert != nil || mouse.Ratchet != nil {
                Divider()
            }
            // TODO: add diversion capability checks
            ReprogSelector(choices: divPickerChoices, selection: selVWheel) {
                ListText("Scroll Wheel").frame(maxWidth: .infinity, alignment: .leading)
            }
            ReprogSelector(choices: divPickerChoices, selection: selHWheel) {
                ListText("Thumb Wheel").frame(maxWidth: .infinity, alignment: .leading)
            }
            ReprogSelector(choices: divPickerChoices, selection: $selGestures) {
                ListText("Gestures").frame(maxWidth: .infinity, alignment: .leading)
            }
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
