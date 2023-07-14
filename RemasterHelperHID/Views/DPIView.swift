//
//  DPIView.swift
//  RemasterHelperHID
//
//  Created by Mario on 12/07/23.
//

import Foundation
import SwiftUI

struct DPIView: View {
    @ObservedObject var mouse: MouseInterface
    var shimBind: Binding<Float> { Binding(get: {
        mouse.dpiShim
    }, set: {
        mouse.dpiShim = $0
    })}
    var body: some View {
        VStack {
            HStack {
                Text("DPI").font(.title2)
                Spacer()
                Text("\(UInt(mouse.dpiShim))").font(.title)
            }
            .padding(.bottom, 6)
            Slider(value: shimBind,
                   in: ClosedRange(uncheckedBounds:
                                    (Float(mouse.SupportedDPI.min),
                                     Float(mouse.SupportedDPI.max))))
            { if $0 { Task { await mouse.setDPI(UInt(mouse.dpiShim) )}}}
                .animation(.linear, value: mouse.dpiShim)
        }
        .transition(.scale)
        .padding(.horizontal, 6)
        .animation(.linear(duration: 0.06), value: mouse.dpiShim)
    }
    
    init(mouse: MouseInterface) {
        self.mouse = mouse
    }
}
