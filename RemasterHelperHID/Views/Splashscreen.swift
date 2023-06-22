//
//  Splashscreen.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 22/06/23.
//

import Foundation
import SwiftUI

// https://github.com/MrChens/SineWaveShape/blob/main/Sources/SineWaveShape/SineWaveShape.swift
public struct SineWaveShape: Shape {
    
    public var animatableData: Double {
        get { phase }
        set { self.phase = newValue }
    }
    var percent: Double
    var strength: Double
    var frequency: Double
    var phase: Double
    
    public init(percent: Double, strength: Double, frequency: Double, phase: Double) {
        self.percent = percent
        self.strength = strength
        self.frequency = frequency
        self.phase = phase
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = Double(rect.width)
        let height = Double(rect.height)
        let midWidth = width / 2
        let oneOverMidWidth = 1 / midWidth
        let wavelength = width / frequency
        path.move(to: CGPoint(x: 0, y: height))
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / wavelength
            let distanceFromMidWidth = x - midWidth
            let normalDistance = oneOverMidWidth * distanceFromMidWidth
            let parabola = -(normalDistance * normalDistance) + 1
            let sine = sin(relativeX + phase)
            let y = parabola * strength * sine + height * percent
            path.addLine(to: CGPoint(x: x, y: y))
        }
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

struct Splashscreen<Content: View>: View {
    let active: Bool
    init(_ a: Bool, @ViewBuilder _ content: () -> Content) {
        active = a
        self.content = content()
    }
    
    let content: Content
    @State private var start: Bool = false
    var body: some View {
        GeometryReader { geo in
            ZStack {
                ZStack {
                    SineWaveShape(percent: 0.3, strength: 30, frequency: 7, phase: start ? 0 + 32 : 360 + 32)
                        .fill(start ? .green : .mint)
                        .animation(.linear(duration: 120).repeatForever(), value: start)
                    SineWaveShape(percent: 0.5, strength: 30, frequency: 7, phase: start ? 0 + 62 : 360 + 62)
                        .fill(start ? .blue : .orange)
                        .animation(.linear(duration: 180).repeatForever(), value: start)
                    SineWaveShape(percent: 0.6, strength: 30, frequency: 7, phase: start ? 0 : 360)
                        .fill(start ? .red : .yellow)
                        .animation(.linear(duration: 240).repeatForever(), value: start)
                        .onAppear(perform: {start = true})
                }
                .blur(radius: 16)
                .opacity(active ? 1 : 0)
                .animation(.linear, value: active)
                content
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
