//
//  MenuView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI
import Combine

struct StatusView: View {
    @ObservedObject var factory = MouseTracker.global
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(factory.mainMouse != nil ? factory.mainMouse!.name : "No Mouse")
                .font(.title2)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
            
            Spacer()
                .minimumScaleFactor(0)
            
            TransportIndicatorView(transport: factory.mainMouse?.transport)
                .font(.title2)
                .minimumScaleFactor(0.1)
                .frame(width: 20, height: 16)
            
            if let b = factory.mainMouse?.Battery {
                VStack(spacing: 0) {
//                    if !b.Charging {
//                        Text("\(b.Percent)")
//                            .font(.title3)
//                            .foregroundColor(.primary)
//                            .minimumScaleFactor(0.1)
//                            .frame(height: 16)
//
//                    }
                    ZStack(alignment: .center) {
                        BatteryIndicatorView(level: Int(b.Percent))
                            .backgroundStyle(.primary)
                            .foregroundColor(b.Percent > 15 || b.Charging ? .accentColor : .red)
                            .frame(width: 28, height: 12)
                        if b.Charging {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.green)
                                .minimumScaleFactor(0.1)
                                .font(.title)
                                .frame(height: 20)
                                .transition(.scale)
                                .animation(.spring(), value: b.Charging)
                        }
                    }
                    .animation(.spring(), value: b.Charging)
                    .frame(width: 28, height: 16)
                }
            }
        }
    }
}

struct SwitchView: View {
    @ObservedObject var mouse: MouseInterface
    @State var ssSlider: Float = 0
    var body: some View {
        VStack {
            HStack { // Upper half
                if let r = mouse.Ratchet {
                    Button { Task { await mouse.toggleRatchet() } }
                    label: { Image(systemName: "pin.square")
                            .frame(maxWidth: .infinity)
                            .symbolVariant(r ? .fill : .none)
                            .foregroundColor(r ? .accentColor : .primary)
                            .contentTransition(.identity)
                    }
                }
                if let i = mouse.WheelInvert {
                    Button { Task { await mouse.toggleWheelInvert() } }
                    label: { Image(systemName: "arrow.up.and.down.square")
                            .frame(maxWidth: .infinity)
                            .symbolVariant(i ? .fill : .none)
                            .foregroundColor(i ? .accentColor : .primary)
                            .contentTransition(.identity)
                            .animation(.default, value: i)
                    }
                }
                if let h = mouse.WheelHiRes {
                    Button { Task { await mouse.toggleWheelHiRes() } }
                    label: { Image(systemName: h ? "circle.dotted" : "circle.dashed")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(h ? .accentColor : .primary)
                            .contentTransition(.interpolate)
                            .animation(.linear, value: h)
                    }
                }
            }
            .transition(.move(edge: .top))
            .font(.title)
            .padding(.vertical, 6)
            .buttonStyle(.plain)
            HStack { // Lower half (optional controls)
                if mouse.Ratchet == true && mouse.SmartShift != 0 {
                    Image(systemName: "s.circle.fill")
                        .font(.title3)
                    Slider(value: $ssSlider,
                           in: ClosedRange(uncheckedBounds: (1, 128)))
                    { x in if !x { Task.init { await mouse.setSmartShift(UInt(ssSlider)) }}}
                        .onAppear() { ssSlider = Float(mouse.SmartShift ?? 40) }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
        .animation(.linear, value: mouse.Ratchet)
        .frame(height: 64)
    }
}


struct MenuView: View {
    @ObservedObject var factory = MouseTracker.global
    @Environment(\.openWindow) var openWindow
    
    var body: some View {
        VStack {
            Button {
                openWindow(id: "settings")
            } label: {
                Image(systemName: "gear")
                Text(factory.mainMouse?.Ratchet == true ? "dio" : "porco")
            }

            StatusView()
                .padding(4)
                .padding(.horizontal, 4)
                .symbolRenderingMode(.hierarchical)
            if factory.mainMouse != nil {
                if let m = factory.mainMouse {
                    Divider()
                    DPIView(mouse: m).padding(4)
                    Divider()
                    SwitchView(mouse: m)
                        .padding(4)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: 240, alignment: .top)
        .animation(.linear, value: factory.mainMouse?.Ratchet)
    }
}
