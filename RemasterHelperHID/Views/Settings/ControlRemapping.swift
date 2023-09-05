//
//  ControlRemapping.swift
//  RemasterHelperHID
//
//  Created by Mario on 16/07/23.
//

import SwiftUI

protocol SidebarChoice : Identifiable, Equatable {
    var content: String { get }
}

struct FixedSidebarView<Choice: SidebarChoice, Content: View>: View {
    init(choices: [Choice], widthPercent: CGFloat = 0.4, @ViewBuilder _ content: @escaping (Choice?) -> Content) {
        self.sidebarChoices = choices
        self.sidebarSize = widthPercent
        contentBuilder = content
    }
    
    let sidebarSize: CGFloat
    let sidebarChoices: [Choice]
    private let contentBuilder: (Choice?) -> Content
    @State private var selected: Choice? = nil

    
    var body: some View {
        let content: Content = contentBuilder(selected)
        GeometryReader { geo in
            HStack {
                List {
                    ForEach(sidebarChoices) { cur in
                        Button(action: { selected = selected == cur ? nil : selected },
                        label: {
                            Text(cur.content)
                        })
                        .buttonStyle(.plain)
                        .font(.smallCaps(.title2)())
                        .foregroundStyle(cur != selected ? .primary : .secondary)
                        .tint(.accentColor)
                        .onDisappear(perform: { selected = selected == cur ? nil : selected })
                    }
                }
                .padding(.all, 12)
                .scrollContentBackground(.hidden)
                .background(.thinMaterial)
                .frame(width: geo.size.width * sidebarSize, height: geo.size.height)
                
                content.padding(.all, 12)
            }

        }
    }
}

struct ControlRemapping: SettingsTab {
    static let title = "Reprogrammable Keys"
    @ObservedObject var factory = MouseTracker.global

    var body: some View {
        VStack {
            if factory.mice.count > 0 {
                FixedSidebarView(choices: factory.mice) { sel in
                    Text(sel?.name ?? "No selection")
                }
            } else {
                AlertCard(symbol: "exclamationmark.triangle", description: "Connect a device")
            }
        }
        .animation(.default, value: factory.mice.count)
    }
}

extension MouseInterface : SidebarChoice {
    nonisolated var content: String { self.name }
}

struct ControlRemapping_Previews: PreviewProvider {
    static var previews: some View {
        ControlRemapping()
            .frame(width: 600, height: 400)
    }
}
