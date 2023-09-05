//
//  AlertCard.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 25/08/23.
//

import SwiftUI

struct AlertCard: View {
    let symbol: String
    let description: LocalizedStringKey
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(.ultraThinMaterial)
                .shadow(radius: 6)
            VStack {
                Image(systemName: symbol)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .padding(15)
                
                Text(description)
                    .font(.smallCaps(.largeTitle)())
            }
            .padding(.all, 20)
        }
        .frame(width: 400, height: 200)
    }
}

#Preview {
    AlertCard(symbol: "exclamationmark.triangle", description: "Connect a device")
}
