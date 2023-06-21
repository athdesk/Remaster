//
//  ConnectedDevices.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import SwiftUI

struct DeviceCard: View {
    var mouse: any Mouse
    var active: Bool
    var onClick: () -> ()
    @State var clickAnimOpacity: Double = 1 // lmao
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .center) {
                Image(mouse.thumbnailName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width - 16, height: geo.size.height - 16)
                    .clipped()
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: geo.size.width - 16, height: geo.size.height - 16)
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(radius: 6)
                VStack(alignment: .center) {
                    Text(mouse.name)
                        .font(.title)
                        .foregroundColor(.primary)
                        .fontDesign(.rounded)
                        .minimumScaleFactor(0.1)
                        .lineLimit(1)
                        .bold(mouse.self === MouseFactory.sharedInstance.mainMouse)
                    Spacer()
                    Image(mouse.thumbnailName)
                        .resizable()
                        .scaledToFit()
                    Spacer()
                    if (active) {
                        Image(systemName: "circle.fill")
                            .font(.footnote)
                            .foregroundColor(.accentColor)
                            .transition(.opacity)
                            .animation(.easeInOut, value: active)
                    }
                    
                }
                .padding(18)
                .foregroundColor(.primary)
                Button {
                    Task.init {
                        clickAnimOpacity = 0.6
                        try? await Task.sleep(for: .milliseconds(100))
                        clickAnimOpacity = 1
                    }
                    onClick()
                } label: {
                    Rectangle()
                        .opacity(0.0000001)
                        .frame(width: geo.size.width - 16, height: geo.size.height - 16)
                }
                .buttonStyle(.plain)
            }
        }
        .opacity(clickAnimOpacity)
        .animation(.linear(duration: 0.2), value: clickAnimOpacity)
        .frame(width: 180, height: 280)
        .fixedSize()
    }
}


struct DeviceTab: View {
    var mouse: any Mouse
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Rectangle()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .foregroundStyle(.ultraThinMaterial)
                    .shadow(radius: 4)
                HStack {
                    Text("A")
                    Text(mouse.name)
                    Image(mouse.thumbnailName)
                }
            }
        }
    }
}

struct ConnectedDevices: View {
    @ObservedObject var factory = MouseFactory.sharedInstance
    var sortedMice: [any Mouse] {
        Array(factory.mice.values).sorted { lhs, rhs in
            lhs.name > rhs.name
        }
    }
    
    @State var asd: String = "asad"
    @State var selectedMouse: (any Mouse)? = nil
    
    var body: some View {
        VStack(alignment: .center) {
            GeometryReader { geo in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .center) {
                        ForEach(sortedMice, id: \.identifier.hashValue) { v in
                            DeviceCard(mouse: v, active: selectedMouse === v) {
                                if selectedMouse === v {
                                    selectedMouse = nil
                                } else {
                                    selectedMouse = v
                                }
                            }
                            .animation(.easeInOut, value: selectedMouse === v)
                        }
                    }
                    .padding(12)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
            if let m = selectedMouse {
                Spacer()
                DeviceTab(mouse: m)
                    .transition(.asymmetric(insertion: .push(from: .bottom), removal: .push(from: .top)))
            }
        }
        .frame(minWidth: 1000, minHeight: 600)
        .navigationTitle("Connected Devices")
        .animation(.easeInOut, value: selectedMouse?.id)
    }
}

struct ConnectedDevices_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedDevices()
    }
}
