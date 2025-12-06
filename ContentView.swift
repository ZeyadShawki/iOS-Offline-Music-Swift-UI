//
//  ContentView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    var body: some View {
        
        TabView(selection: $selectedTab){
            DiscoveryPage(text: "").tabItem {
                Label("Discovery",systemImage: "safari.fill")
            }
            PlaylistPage().tabItem {
                Label("PlayList",systemImage: "books.vertical.fill")
            }
            LibraryPage().tabItem {
                Label("Library",systemImage: "document.fill")
            }
            SettingPage().tabItem {
                Label("Setting",systemImage: "gear")
            }
        }
    }
}

#Preview {
    ContentView()
}
