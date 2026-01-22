//
//  PlaylistModel.swift
//  aboutme
//
//  Created by zeyad Shawki on 23/12/2025.
//

import Foundation
import SwiftUI

struct Playlist: Identifiable {
    let id : UUID
    let name: String
    let songCount: Int
    let iconName: String
    let overlayColor: Color
    let folderPath: URL?
    
    init(id: UUID = UUID(), name: String, songCount: Int, iconName: String, overlayColor: Color, folderPath: URL?) {
        self.id = id
        self.name = name
        self.songCount = songCount
        self.iconName = iconName
        self.overlayColor = overlayColor
        self.folderPath = folderPath
    }
}

extension Playlist: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
    }
    
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        lhs.id == rhs.id
    }
}

extension Playlist {
  static func makeTestPlaylist() -> Playlist {
        return Playlist(
            name: "Chill Vibes",
            songCount: 15,
            iconName: "music.note.list",
            overlayColor: .blue.opacity(0.6),
            folderPath: URL(string: "file:///Users/zeyad/Music/ChillVibes")
        )
    }
}
