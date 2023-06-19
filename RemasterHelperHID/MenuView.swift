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
        if let mouse = source.mainMouse {
            HStack {
                Text(mouse.name)
                if mouse.Battery != 0 { Text("\(mouse.Battery)%") }
            }
        } else {
            Text("No Mouse Connected")
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
                { x in if !x { mouse.DPI = UInt(dpiSlider) }}
                    .onAppear() { dpiSlider = Float(mouse.DPI) }
                    .onChange(of: source.mainMouseRef) { _ in dpiSlider = Float(source.mainMouse?.DPI ?? 0) }
                    .animation(.linear, value: dpiSlider)
            }
            .transition(.scale)
            .padding(.horizontal, 10)
        }
    }
}

struct SwitchView: View {
    @ObservedObject var source = DataSource.sharedInstance
    @State var ssSlider: Float = Float(DefaultMousePreferences.smartShift)
    var body: some View {
        Divider()
        if let mouse = source.mainMouse {
            VStack {
                HStack {
                    if let r = mouse.Ratchet {
                        Button {
                            mouse.Ratchet?.toggle()
                        } label: { Image(systemName: "pin.square")
                                .frame(maxWidth: .infinity)
                                .symbolVariant(r ? .fill : .none)
                                .foregroundColor(r ? .accentColor : .primary)
                                .contentTransition(.identity)
                        }
                    }
                    Button {
                        
                    } label: { Image(systemName: "arrow.up.and.down.square.fill").frame(maxWidth: .infinity) }
                    
                    Button {
                        
                    } label: { Image(systemName: "ellipsis").frame(maxWidth: .infinity) }
                }
                .transition(.move(edge: .top))
                .font(.title)
                .padding(.vertical, 4)
                .buttonStyle(.plain)
                
                if mouse.Ratchet == true && mouse.SmartShift != 0 {
                    HStack {
                        Image(systemName: "s.circle.fill")
                            .font(.title3)
                        Slider(value: $ssSlider,
                               in: ClosedRange(uncheckedBounds: (1, 49)))
                        { x in if !x { mouse.SmartShift = UInt(ssSlider) } }
                            .animation(.linear, value: mouse.Ratchet)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 4)
                    .transition(.move(edge: .bottom))
                }
                
                
            }
            .frame(height: 60)
            .symbolRenderingMode(.hierarchical)
        }
    }
}


struct MenuView: View {
//    @ObservedObject var data: ViewData = ViewData.main
    @ObservedObject var source = DataSource.sharedInstance
    
    var body: some View {
        VStack {
            if let m = source.mainMouse {
                StatusView()
                DPIView().padding(4)
                SwitchView().padding(4)
            }
        }
        .transition(.opacity)
        .contentTransition(.opacity)
        .padding(16)
        .frame(maxWidth: 240, alignment: .top)
        .animation(.spring(), value: source.mainMouse?.Ratchet)
    }
}
