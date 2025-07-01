//
//  ContentView.swift
//  NeoSigner
//
//  Created by Skadz on 2/24/25.
//

import SwiftUI
import WelcomeSheet

internal enum SelectableTab: Int, CaseIterable {
    case browse, library, settings
}

struct ContentView: View {
    @State public var selectedTab: SelectableTab = .library
    
    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                BrowseView()
                    .tabItem {
                        Label("Browse", systemImage: "magnifyingglass")
                    }
                    .tag(SelectableTab.browse)
                
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(SelectableTab.library)
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(SelectableTab.settings)
            }
            .overlay(alignment: .bottom) {
                let color = Color.accentColor
                GeometryReader { geometry in
                    let aThird = geometry.size.width / 3
                    VStack {
                        Spacer()
                        Circle()
                            .background(color.blur(radius: 20))
                            .frame(width: aThird, height: 30)
                            .shadow(color: color, radius: 40)
                            .offset(
                                x: CGFloat(selectedTab.rawValue) * aThird,
                                y: 30
                            )
                    }
                    .animation(.spring(response: 0.45, dampingFraction: 0.6), value: selectedTab)
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
}

#Preview {
    ContentView()
}
