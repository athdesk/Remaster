//
//  MenuView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI
import Combine

struct StatusView: View {
    @ObservedObject var source = DataSource.sharedInstance
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(source.mainMouse != nil ? source.mainMouse!.name : "No Mouse")
                .font(.title2)
                .minimumScaleFactor(0.1)
                .lineLimit(1)
            
            Spacer()
                .minimumScaleFactor(0)
            
            TransportIndicatorView(transport: source.mainMouse?.transport)
                .font(.title2)
                .minimumScaleFactor(0.1)
                .frame(width: 20, height: 16)
            
            if let b = source.mainMouse?.Battery {
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

struct DPIView: View {
    @ObservedObject var source = DataSource.sharedInstance
    @State var dpiSlider: Float = 0
    
    var body: some View {
        if let mouse = source.mainMouse {
            Divider()
            VStack {
                HStack {
                    Text("DPI").font(.title2)
                    Spacer()
                    Text("\(UInt(dpiSlider))").font(.title)
                }
                .padding(.bottom, 6)
                Slider(value: $dpiSlider,
                       in: ClosedRange(uncheckedBounds:
                                        (Float(mouse.SupportedDPI.min),
                                         Float(mouse.SupportedDPI.max))))
                { x in if !x { Task.init { mouse.DPI = UInt(dpiSlider) }}}
                    .onAppear() { dpiSlider = Float(mouse.DPI) }
                    .onChange(of: source.mainMouseRef) { _ in dpiSlider = Float(source.mainMouse?.DPI ?? 0) }
                    .animation(.linear, value: dpiSlider)
            }
            .transition(.scale)
            .padding(.horizontal, 6)
        }
    }
}

struct SwitchView: View {
    @ObservedObject var source = DataSource.sharedInstance
    @State var ssSlider: Float = 0
    var body: some View {
        if let mouse = source.mainMouse {
            Divider()
            VStack {
                HStack { // Upper half
                    if let r = mouse.Ratchet {
                        Button { Task.init {
                            mouse.Ratchet?.toggle()
                        }} label: { Image(systemName: "pin.square")
                                .frame(maxWidth: .infinity)
                                .symbolVariant(r ? .fill : .none)
                                .foregroundColor(r ? .accentColor : .primary)
                                .contentTransition(.identity)
                        }
                    }
                    if let i = mouse.WheelInvert {
                        Button { Task.init {
                            mouse.WheelInvert?.toggle()
                        }} label: { Image(systemName: "arrow.up.and.down.square")
                                .frame(maxWidth: .infinity)
                                .symbolVariant(i ? .fill : .none)
                                .foregroundColor(i ? .accentColor : .primary)
                                .contentTransition(.identity)
                                .animation(.default, value: i)
                        }
                    }
                    if let h = mouse.WheelHiRes {
                        Button { Task.init {
                            mouse.WheelHiRes?.toggle()
                        }} label: { Image(systemName: h ? "circle.dotted" : "circle.dashed")
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
                .animation(.linear, value: mouse.Ratchet)
                
                HStack { // Lower half (optional controls)
                    if mouse.Ratchet == true && mouse.SmartShift != 0 {
                            Image(systemName: "s.circle.fill")
                                .font(.title3)
                            Slider(value: $ssSlider,
                                   in: ClosedRange(uncheckedBounds: (1, 49)))
                            { x in if !x { Task.init { mouse.SmartShift = UInt(ssSlider) }}}
                                .onAppear() { ssSlider = Float(mouse.SmartShift ?? 40) }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
                .transition(.move(edge: .bottom))
            }
            .frame(height: 64)
        }
    }
}


struct MenuView: View {
    @ObservedObject var source = DataSource.sharedInstance
    
    var body: some View {
        VStack {
            StatusView()
                .padding(4)
                .padding(.horizontal, 4)
                .symbolRenderingMode(.hierarchical)
            if source.mainMouse != nil {
                DPIView().padding(4)
                SwitchView()
                    .padding(4)
                    .symbolRenderingMode(.hierarchical)
            }
        }
        .padding(16)
        .frame(maxWidth: 240, alignment: .top)
        .animation(.linear, value: source.mainMouse?.Ratchet)
    }
}
