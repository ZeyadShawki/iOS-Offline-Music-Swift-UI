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
    let snapshotManager = SnapshotManager()
    let songManager = SongManager()
    @State private var lastPlayedlist: Playlist?

    @State private var isLoading = true
    @State private var isInitialized = false
    @State private var hasLoaded = false
    
    var body: some View {
        LoadingView(isShowing: $isLoading) {
            if isInitialized {
                ZStack (alignment: .bottom){
                    TabView(selection: $appRouter.selectedTab){
                        DiscoveryPage(playlist: lastPlayedlist)
                            .id(lastPlayedlist?.id)
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
                }.environmentObject(appRouter)
                    .environmentObject(audioManager)
            }
        }
        .task {
            guard !hasLoaded else { return }
            hasLoaded = true
            
            let playlists = await playlistManager.createDefaultPlaylist()
            lastPlayedlist = playlists?.first(where: {$0.name == playlistManager.defaultLikedSong})
            print("playlists  \(playlists)")
            do {
                try await getLastSnapshot()
            } catch {
                print("error fetching playlist \(error.localizedDescription)")
            }
            isInitialized = true
            isLoading = false
        }
    }
    
    func getLastSnapshot() async throws {
        guard let lastPlayedSong = try await  snapshotManager.getLastPlayedSong() else { return }

        guard let playlistPath = lastPlayedSong.playlistPath else {
            print("⚠️ No playlist path found for last played song")
            return
        }
        guard let playlist = try await playlistManager.getPlaylist(byPath: playlistPath) else {
            return
        }
        let songs = try await songManager.loadSongs(for: playlist)
        audioManager.initQueue(songsQueue: songs, playlist: playlist)
        guard let lastplayed = songs.first(where: { $0.title == lastPlayedSong.songName }) else { return }
        audioManager.loadSong(song: lastplayed, playIt: false)
        lastPlayedlist = playlist
    }
}

#Preview {
    ContentView()
}
