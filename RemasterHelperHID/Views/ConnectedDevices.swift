//
//  ConnectedDevices.swift
//  RemasterHelperHID
//
//  Created by Mario Del Gaudio on 20/06/23.
//

import SwiftUI

struct ConnectedDevices: View {
    @ObservedObject var source = DataSource.sharedInstance
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct ConnectedDevices_Previews: PreviewProvider {
    static var previews: some View {
        ConnectedDevices()
    }
}
