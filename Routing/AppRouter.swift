//
//  Routing.swift
//  aboutme
//
//  Created by zeyad Shawki on 11/01/2026.
//

import Combine
import Foundation
import SwiftUI

enum DiscoveryRoute: Hashable {
    case webView(
        webViewModel: WebViewModel
    )
}

enum PlaylistRoute: Hashable {
    case songs(playlist: Playlist)
    case songDetail(song: Song)
}

// MARK: - Settings Flow Routes
enum SettingsRoute: Hashable {

}

class AppRouter: ObservableObject {
    @Published var selectedTab: Tab = .discovery
    @Published var discoveryPath: [DiscoveryRoute] = []
    @Published var playlistPath: [PlaylistRoute] = []
    @Published var settingsPath: [SettingsRoute] = []

    // MARK: - Discovery Navigation
    func navigateDiscovery(to route: DiscoveryRoute) {
        selectedTab = .discovery
        if discoveryPath.contains(route) { return }
        discoveryPath.append(route)
    }

    // MARK: - Playlist Navigation
    func navigatePlaylist(to route: PlaylistRoute) {
        selectedTab = .playlist
        if playlistPath.contains(route) { return }
        playlistPath.append(route)
    }

    // MARK: - Settings Navigation
    func navigateSettings(to route: SettingsRoute) {
        selectedTab = .settings
        if settingsPath.contains(route) { return }
        settingsPath.append(route)
    }

    func goBack(tab: Tab) {
        switch tab {
        case .discovery:
            if !discoveryPath.isEmpty { discoveryPath.removeLast() }
        case .playlist:
            if !playlistPath.isEmpty { playlistPath.removeLast() }
        case .settings:
            if !settingsPath.isEmpty { settingsPath.removeLast() }
        }
    }

}

enum Tab: Int {
    case discovery = 0
    case playlist = 1
    case settings = 2
}
