//
//  DiscoveryPage.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import Foundation
import SwiftUI

struct DiscoveryPage : View {
    @EnvironmentObject var appRouter: AppRouter
    @StateObject private var webViewModel = WebViewModel()
    @EnvironmentObject var audioManager: AudioManager
    @State private var songs: [Song] = []
    @State private var playlist: Playlist?
    @State private var isLoading = false
    @State private var hasLoaded = false
    
    private let songManager = SongManager()
    private let initialPlaylist: Playlist?
    
    init(playlist: Playlist? = nil) {
        self.initialPlaylist = playlist
    }
    var searchEngineOptions = [
        IconButtonOption(
            title: "YouTube",
            color: .red,
            imageName: "youtube-logo",
            action: {
                print("YouTube option selected")
            },
            searchEngine: .youtube
        ),
    ]
    
    
    var body: some View {
        Group {

                NavigationStack(path: $appRouter.discoveryPath) {
                    content()
                        .toolbar(.visible, for: .tabBar)
                }

        }
    }
    
    @ViewBuilder
    private func content() -> some View {
        LoadingView(isShowing: $isLoading,) {
            VStack {
                ReusableTextField(
                    text: $webViewModel.text,
                    placeHolder: "Search or enter web address",
                    title: nil,
                    buttonOptions: searchEngineOptions,
                    selectedOption: $webViewModel.selectedSearchEngine,
                    onSearch: onSearch
                )
                
                OfflineSongsSection(songs: songs, onMoreTap: {
                    appRouter.navigatePlaylist(to: .songs(playlist: playlist!))
                }, onSongTap: { music in
                    audioManager.initQueue(songsQueue: songs, playlist: playlist!)
                    audioManager.loadSong(song: music, playIt: true)
                })
            }}.frame(maxWidth: .infinity,maxHeight: .infinity,alignment: .topLeading).padding(.horizontal,10)
                .navigationDestination(for: DiscoveryRoute.self) { route in
                    switch route {
                    case .webView(let webViewModel):
                        WebViewPage(webViewModel: webViewModel)
                    }
                }.task {
                    guard !hasLoaded else { return }
                    hasLoaded = true
                    playlist = initialPlaylist
                    await loadSongs()
                }
                .onAppear {
                    guard hasLoaded else { return }
                    Task { await loadSongs() }
                }
    }
    
    private func loadSongs() async {
        guard let playlist = playlist else {
            songs = []
            return
        }
        
        isLoading = true
        do {
            songs = try await songManager.loadSongs(for: playlist)
            print("✅ Loaded \(songs.count) songs for playlist: \(playlist.name)")
        } catch {
            print("❌ Error loading songs: \(error)")
            songs = []
        }
        isLoading = false
    }
    
    func onSearch() {
        guard let selected = webViewModel.selectedSearchEngine else { return }
        let engine = selected.searchEngine
        webViewModel.searchURL = WebViewSearchHelper.buildSearchURL(query: webViewModel.text, engine: engine)
        // Navigate to WebView page
        if webViewModel.searchURL != nil {
                   appRouter.navigateDiscovery(to: .webView(webViewModel: webViewModel))
        }
    }
    
}

#Preview {
    DiscoveryPage()
}


