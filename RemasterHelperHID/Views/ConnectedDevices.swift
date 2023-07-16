//
//  ConnectedDevices.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import SwiftUI
import Combine

struct DeviceCard: View {
    var mouse: MouseInterface
    var activeMouse: MouseInterface?
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: geo.size.width - 16, height: geo.size.height - 16)
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(radius: 4)
                VStack(alignment: .center) {
                    Text(mouse.name)
                        .font(.title)
                        .foregroundColor(.primary)
                        .fontDesign(.rounded)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                        .bold(mouse.self === MouseTracker.global.mainMouse)
                    HStack(alignment: .lastTextBaseline) {
                        TransportIndicatorView(transport: mouse.transport)
                            .font(.title2)
                            .minimumScaleFactor(0.1)
                            .frame(width: 20, height: 16)
                        let transport = { () -> String in
                            if case .Receiver(let type) = mouse.transport {
                                return String(describing: type)
                            } else {
                                return String(describing: mouse.transport)
                            }
                        }()
                        Text(transport)
                            .font(.title3)
                            .fontDesign(.rounded)
                            .minimumScaleFactor(0.1)
                            .lineLimit(1)
                    }
                    .padding(4)
                    Spacer()
                    Image(mouse.thumbnailName)
                        .resizable()
                        .scaledToFit()
                    Spacer()
                    Circle()
                        .frame(width: activeMouse === mouse ? 8 : 0,
                               height: activeMouse === mouse ? 8 : 0)
                        .offset(x: 0, y:  activeMouse === mouse ? 0 : 24)
                        .padding(12)
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                }
                .padding(18)
                .foregroundColor(.primary)
            }
            .clipped()
        }
        .animation(.easeInOut, value: activeMouse)
        .aspectRatio(0.66, contentMode: .fit)
    }
}

struct ListText: View {
    var text: String
    var body: some View {
        Text(text)
            .font(.smallCaps(.title2)())
            .lineLimit(1)
            
    }
    init(_ t: String) {
        text = t
    }
}

struct DualListText: View {
    var text1: String
    var text2: String
    var body: some View {
        HStack {
            ListText(text1)
            Spacer()
            ListText(text2)
        }
    }
    init(_ leftText: String, _ rightText: String) {
        text1 = leftText
        text2 = rightText
    }
}

struct InfoList: View {
    @ObservedObject var mouse: MouseInterface
    var body: some View {
        List {
            DualListText("Serial", mouse.Serial)
            
            let transport = { () -> String in
                if case .Receiver(let type) = mouse.transport {
                    return String(describing: type)
                } else {
                    return String(describing: mouse.transport)
                }
            }()
            
            DualListText("Transport", transport)
            
            if let bat = mouse.Battery {
                DualListText("Battery", bat.Percent.description + (bat.Charging ? "% +" : "%"))
            }
        }
    }
}

struct BasicDeviceTab: View {
    @ObservedObject var mouse: MouseInterface
    
    init(_ m : MouseInterface) {
        mouse = m
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle() // Background
                    .frame(width: geo.size.width, height: geo.size.height)
                    .foregroundStyle(.ultraThickMaterial)
                    .shadow(radius: 4)
                VStack { // Actual Content
                    HStack { // Header
                        Text(mouse.name)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .bold()
                            .fontDesign(.rounded)
                            .minimumScaleFactor(0.4)
                        Spacer()
                    }
                    .frame(height: geo.size.height * 0.15)
                    .padding(12)
                    HStack { // Body
                        List {
                            BasicToggleList(mouse: mouse)
                                .frame(minWidth: 280, maxWidth: 440)
                            DPIView(mouse: mouse)
                                .frame(minWidth: 280, maxWidth: 440)
                        }
                        .animation(.default, value: mouse.Ratchet)
                        Spacer()
                        InfoList(mouse: mouse)
                        .frame(minWidth: 240, maxWidth: 400)
                        .transition(.scale)
                    }
                    .toggleStyle(.switch)
                    .font(.smallCaps(.title3)())
                    .scrollContentBackground(.hidden)
                    .transition(.opacity)
                    .padding(4)
                    Spacer()
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
    }
}

struct ConnectedDevices: SettingsTab {
    static let title = "Connected Devices"
    
    @ObservedObject var factory = MouseTracker.global
    @State private var selectedMouse: MouseInterface? = nil
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .center, spacing: 0) {
                ScrollView(.horizontal) {
                    HStack(alignment: .center) {
                        HStack { // Need it twice to apply a frame, because variable .padding makes the text in the card glitch
                            ForEach(factory.mice, id: \.hashValue) { v in
                                Button {
                                    if selectedMouse === v {
                                        selectedMouse = nil
                                    } else {
                                        selectedMouse = v
                                    }
                                } label: {
                                    DeviceCard(mouse: v, activeMouse: selectedMouse)
                                }
                                .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                                .onDisappear {
                                    // This fixes a retain cycle in case the selected mouse gets removed
                                    if !factory.mice.contains(where: { m in  m === selectedMouse }) {
                                        selectedMouse = nil
                                    }
                                }
                            }
                        }
                        .frame(minWidth: geo.size.width, minHeight: geo.size.height * 0.4, maxHeight: geo.size.height * 0.7, alignment: .center)
                    }
                    .buttonStyle(.plain)
                    .padding(12)
                    .frame(minWidth: geo.size.width, minHeight: geo.size.height * 0.4, maxHeight: geo.size.height, alignment: .center)
                    .animation(.easeInOut, value: factory.mice.count)
                }
                .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
                if let m = selectedMouse {
                    BasicDeviceTab(m)
                        .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
                        .frame(maxHeight: 360)
                }
            }
        }
        .animation(.easeInOut, value: selectedMouse)
    }
}

struct ConnectedDevices_Previews: PreviewProvider {
    static var previews: some View {
        if let mouse = MouseTracker.global.mainMouse {
            BasicDeviceTab(mouse)
                .frame(minWidth: 840, minHeight: 600 * 0.6)
            //        ConnectedDevices(selectedMouse: MouseFactory.sharedInstance.mainMouse)
        }
    }
}
