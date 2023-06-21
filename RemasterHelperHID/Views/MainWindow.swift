//
//  MainWindow.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import SwiftUI



struct MainWindow: View {
    @State var aa: Bool = true
    
    var body: some View {
        NavigationSplitView()
        {
            List {
                Section {
                    NavigationLink("Connected Devices", destination: ConnectedDevices())
                } header: {
                    Text("Basic Settings")
                        .font(.title2)
                }
            }
            .toolbar(content: {
                ToolbarItemGroup(placement: .status) {
                    Image(systemName: "gear")
                    Text("Remaster")
                        .font(.smallCaps(.title2)())
                }
            })
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 200, ideal: 200, max: 200)
            .presentedWindowToolbarStyle(.unified(showsTitle: true))
        }
    detail: {
        Text("Default")
    }
    .navigationTitle("Remaster")
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
    }
}
