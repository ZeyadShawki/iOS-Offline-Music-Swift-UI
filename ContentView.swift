//
//  ContentView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appRouter = AppRouter()
    private let playlistManager = PlaylistManager()
    let audioManager = AudioManager.shared

    @State private var isLoading = false
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            ZStack (alignment: .bottom){
                TabView(selection: $appRouter.selectedTab){
                    DiscoveryPage()
                        .tag(Tab.discovery)
                        .tabItem {
                            Label("Discovery", systemImage: "safari.fill")
                        }
                    PlaylistPage(playlists: [])
                        .tag(Tab.playlist)
                        .tabItem {
                            Label("PlayList", systemImage: "books.vertical.fill")
                        }
                    SettingPage()
                        .tag(Tab.settings)
                        .tabItem {
                            Label("Setting", systemImage: "gear")
                        }
                }.padding(.bottom, 60)
                MiniPlayer()
                    .padding(.horizontal,20)
            }.environmentObject(appRouter).task {
                isLoading = true
                playlistManager.createDefaultPlaylist(completionHandler: { _ in
                    isLoading = false
                })
            }.environmentObject(audioManager)
        }
    }
}

#Preview {
    ContentView()
}
