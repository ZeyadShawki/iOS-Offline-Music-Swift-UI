//
//  PlayistRow.swift
//  aboutme
//
//  Created by zeyad Shawki on 23/12/2025.
//

import SwiftUI

struct PlayistRow: View {
    let playlist: Playlist
    
    var body: some View {
        VStack (alignment: .leading){
            HStack(alignment: .top, spacing: 16){
                RoundedRectangle(cornerRadius: 12).fill(playlist.overlayColor).frame(width: 50,height: 50).overlay(Image(
                    systemName: playlist.iconName
                ).font(.system(size: 30)).foregroundStyle(.primary))
                
                VStack (alignment: .leading,spacing: 0){
                    Text(playlist.name)
                    Text("\(playlist.songCount) Songs").foregroundColor(.secondary)
                    
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    PlayistRow(playlist:
        Playlist(
            name: "Liked Songs", songCount: 3, iconName: "heart.fill",
            overlayColor: .blue
        )
    )
}
