//
//  RemapControls.swift
//  RemasterHelperHID
//
//  Created by Mario on 16/07/23.
//

import SwiftUI

protocol ReprogChoice : Hashable, Identifiable {
    func str() -> String
}

struct ReprogSelector<T: ReprogChoice, Content: View>: View {
    let choices: [T]
    @Binding var selection: T
    let title: () -> Content
    var body: some View {
        HStack {
            title()
            Spacer()
            Menu {
                ForEach(choices, id: \.self) { s in
                    Button(s.str()) { selection = s }
                }
            } label: {
                Text(selection.str())
            }
            .menuStyle(.borderlessButton)
        }
    }
}

enum DiversionChoice: ReprogChoice, Identifiable {
    // This is fake, but we don't use IDs with this
    var id: ObjectIdentifier { ObjectIdentifier(Self.self) }
    
    case Default
    case Diverted
    
    func bool() -> Bool {
        switch self {
        case .Default: return false
        case .Diverted: return true
        }
    }
    
    func str() -> String {
        switch self {
        case .Default:
            return "Default"
        case .Diverted:
            return "Controlled by Remaster"
        }
    }
}


struct RemapControls: View {
    @ObservedObject var mouse: MouseInterface

    var body: some View {
        if let reprog = mouse.ReprogrammableKeys {
            ForEach(reprog.Keys) { k in
                ReprogSelector(choices: reprog.Keys, selection: .constant(k)) {
                    ListText(k.str())
                }
            }
        }
    }
}

//struct RemapControls_Previews: PreviewProvider {
//    static var previews: some View {
//        RemapControls()
//    }
//}
