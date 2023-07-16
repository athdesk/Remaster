//
//  ControlRemapping.swift
//  RemasterHelperHID
//
//  Created by Mario on 16/07/23.
//

import SwiftUI

struct ControlRemapping: View {
    static let title = "Programmable Keys"
    
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

//struct ControlRemapping_Previews: PreviewProvider {
//    static var previews: some View {
//        ControlRemapping()
//    }
//}
