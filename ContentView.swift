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
        ZStack (alignment: .bottom){
            TabView(selection: $selectedTab){
                DiscoveryPage(text: "").tabItem {
                    Label("Discovery",systemImage: "safari.fill")
                }
                PlaylistPage(playlists: []).tabItem {
                    Label("PlayList",systemImage: "books.vertical.fill")
                }
                SettingPage().tabItem {
                    Label("Setting",systemImage: "gear")
                }
            }.padding(.bottom, 60)
            MiniPlayer(song:
                        Song(
                            title: "Amr Diab - Ayyam We Ben'eshha",
                            artist: "Rotana",
                            duration: 195,
                            fileSize: 3_670_016,
                            thumbnailImageUrl: nil,
                            audioURL: URL(fileURLWithPath: "")
                        )
            ).padding(.horizontal,20)
        }
    }
}

#Preview {
    ContentView()
}
