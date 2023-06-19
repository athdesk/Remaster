//
//  RemasterHelperHIDApp.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 13/06/23.
//

import SwiftUI

@main
struct RemasterHelperHIDApp: App {
    var body: some Scene {
        MenuBarExtra("Remaster", systemImage: "seal") {
            MenuView()
        }
        .menuBarExtraStyle(.window)
    }
  
    init() {
        DispatchQueue.global(qos: .utility).async {
            print("Backgroud thread started")
            start()
        }
    }
}
