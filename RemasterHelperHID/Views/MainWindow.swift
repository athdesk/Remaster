//
//  MainWindow.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import SwiftUI

protocol SettingsTab : View {
    static var title: String { get }
}

struct Link<Tab:SettingsTab>: View {
    let title: String
    var body: some View {
        Section {
            NavigationLink(Tab.title, value: Tab.title)
        } header: {
            Text(title)
                .font(.title2)
        }
    }
}

struct WelcomeScreen: SettingsTab {
    static let title = "WelcomeScreen"
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .foregroundStyle(.ultraThinMaterial)
                .shadow(radius: 6)
            VStack {
                Image(systemName: "gear")
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .padding(50)
                Text("Remaster")
                    .font(.smallCaps(.system(.largeTitle, design: .rounded, weight: .light))())
                Text("Settings")
                    .font(.smallCaps(.system(.title, design: .rounded, weight: .light))())
            }
        }
        .frame(width: 200, height: 300)
    }
}

struct MainWindow: View {
    @State var sel: String? = nil
    @State var artActive: Bool = true
    
    var body: some View {
        NavigationSplitView()
        {
            List(selection: $sel) {
                Link<ConnectedDevices>(title: "Basic Settings")
            }
            .toolbar(content: {
                ToolbarItem(placement: .status) {
                    Button(action: {
                        sel = nil
                    }, label: {
                        Text("Remaster")
                            .font(.smallCaps(.title2)())
                    })
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        artActive.toggle()
                    }, label: {
                        Image(systemName: "paintbrush.pointed")
                    })
                    
                }
            })
            .listStyle(.sidebar)
            .navigationSplitViewColumnWidth(min: 240, ideal: 240, max: 240)
            .presentedWindowToolbarStyle(.unified(showsTitle: false))
        } detail: {
            Splashscreen(artActive) {
                ZStack{
                    // this lets contents be saved, use a switch if this is too heavy
                    ConnectedDevices()
                        .opacity(sel == ConnectedDevices.title ? 1 : 0)
                    WelcomeScreen()
                        .opacity(sel == nil || sel == WelcomeScreen.title ? 1 : 0)
                }
            }
            .transition(.scale)
            .contentTransition(.interpolate)
        }
        .animation(.linear(duration: 0.1), value: sel)
        .navigationTitle("")
        .frame(minWidth: 840, minHeight: 600)
    }
}

struct MainWindow_Previews: PreviewProvider {
    static var previews: some View {
        MainWindow()
//        Splashscreen()
    }
}
