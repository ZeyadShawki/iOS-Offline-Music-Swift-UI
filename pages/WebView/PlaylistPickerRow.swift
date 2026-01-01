//
//  DownloadOverlayButton.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import SwiftUI

struct PlaylistPickerRow:
    View {
    
    let playlist: Playlist
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(playlist.overlayColor.opacity(0.2)).frame(width: 44,height: 44)
                Image(systemName: playlist.iconName).foregroundStyle(playlist.overlayColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name).font(.system(size: 16, weight: .medium))
                Text("\(playlist.songCount) songs").font(.system(size: 13)).foregroundColor(.secondary)
            }
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        
    }
}

#Preview {
    PlaylistPickerRow(playlist:Playlist(
        name: "Liked Songs", songCount: 3, iconName: "heart.fill",
        overlayColor: .blue,
        folderPath: URL(fileURLWithPath: "")
    ) )
}
