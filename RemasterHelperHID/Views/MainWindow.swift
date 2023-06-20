//
//  MainWindow.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import SwiftUI

struct MainWindow: View {
    var body: some View {
        NavigationView {
            List{
                Image(systemName: "gear")
                Group {
                Text("Basic Settings")
                    .font(.title3)
                    NavigationLink("Connected Devices") { Text("henlo") }
                }
            }
            .listStyle(.sidebar)
            .frame(minWidth: 160)
        }
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
