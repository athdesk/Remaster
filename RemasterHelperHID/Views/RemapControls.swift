//
//  RemapControls.swift
//  RemasterHelperHID
//
//  Created by Mario on 16/07/23.
//

import SwiftUI

struct RemapControls: View {
    @ObservedObject var mouse: MouseInterface
//    @State var test: ReprogKey
    
    
    var body: some View {
        if let reprog = mouse.ReprogrammableKeys {
//            List {
                Divider()
                ForEach(reprog.Keys) { k in
                    ReprogSelector(choices: reprog.Keys, selection: .constant(k)) {
                        ListText(k.str())
                    }
                }
//            }
        }
    }
}

//struct RemapControls_Previews: PreviewProvider {
//    static var previews: some View {
//        RemapControls()
//    }
//}
