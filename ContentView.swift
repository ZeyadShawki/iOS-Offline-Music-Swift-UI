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
                await playlistManager.createDefaultPlaylist()
                do {
                    try await getLastSnapshot()
                } catch {
                    print("error fetching playlist \(error.localizedDescription)")
                }
                isLoading = false
            }.environmentObject(audioManager)
        }
    }
    
    func getLastSnapshot() async throws {
        guard let lastPlayedSong = try await  snapshotManager.getLastPlayedSong() else { return }

        guard let playlistPath = lastPlayedSong.playlistPath else {
            print("⚠️ No playlist path found for last played song")
            return
        }
        guard let playlist = try await playlistManager.getPlaylist(byPath: playlistPath) else { return }
        let songs = try await songManager.loadSongs(for: playlist)
        audioManager.initQueue(songsQueue: songs, playlist: playlist)
        guard let lastplayed = songs.first(where: { $0.title == lastPlayedSong.songName }) else { return }
        audioManager.loadSong(song: lastplayed, playIt: false)
    }
}

#Preview {
    ContentView()
}
