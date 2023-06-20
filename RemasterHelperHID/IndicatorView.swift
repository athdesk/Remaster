//
//  IndicatorView.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import Foundation
import SwiftUI

struct BatteryIndicatorView: View {
    var level: Int
    private var realLevel: Float {
        if level < 0 { return 0 }
        if level > 100 { return 1 }
        return Float(level) / 100
    }
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.quaternary)
                RoundedRectangle(cornerRadius: 3)
                    .stroke(lineWidth: 2)
                    .foregroundColor(.primary)
                RoundedRectangle(cornerRadius: 3)
                    .fill(.secondary)
                    .frame(width: geo.size.width * CGFloat(realLevel))
            }
        }
    }
}

struct TransportIndicatorView: View {
    let transport: TransportType?
    
    var body: some View {
        switch transport {
        case nil:
            Image(systemName: "nosign")
        case .Wired:
            Image(systemName: "cable.connector.horizontal")
        case .Bluetooth:
            Image("logo.bluetooth.capsule.portrait.fill")
        case .Receiver(let receiverType):
            switch receiverType {
            case .Bolt:
                Image(systemName: "bolt.circle.fill")
            default:
                Image(systemName: "rays")
            }
        }
    }
}
