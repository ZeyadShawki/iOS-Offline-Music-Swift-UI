//
//  SongRow.swift
//  aboutme
//
//  Created by zeyad Shawki on 28/12/2025.
//

import Foundation
import SwiftUI

struct SongRow: View {
    
    let song: Song
    let onTap: () -> Void
    let onAddToNextPlay: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 12, ){
            Button(action:onTap ,){
                HStack(spacing: 0) {
                    songThumbnail
                    songInfo
                }
            }
            Spacer()
            SongContextMenu(onAddNextPlay: {}, onDelete: {})
        }.frame(width: .infinity, alignment: .leading)
    }
    
    private var songInfo: some View {
        VStack(alignment: .leading,spacing: 10) {
            Text(song.title).font(.system(size: 16,weight: .medium)).foregroundColor(.primary)
                .lineLimit(1)
            HStack(spacing: 16) {
                Image(systemName: "music.note").font(.system(size: 12)).foregroundColor(.orange)
                Text(song.artist ?? "").font(.system(size: 12)).foregroundColor(.secondary)
                Text("|").font(.system(size: 12)).foregroundColor(.secondary)
                Text(song.duration.formatted()).font(.system(size: 12)).foregroundColor(.secondary)
                Text("|").font(.system(size: 12)).foregroundColor(.secondary)
                Text(song.formattedFileSize).font(.system(size: 12)).foregroundColor(.secondary)
            }
            
        }
    }
    
    private var songThumbnail: some View {
        Group {
            if let thumbnailURL = song.thumbnailImageUrl {
                AsyncImage(url: thumbnailURL) {
                    image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
                
            }
        }
    }
    
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
             .fill(Color.gray.opacity(0.3))
             .overlay(
                 Image(systemName: "music.note")
                     .foregroundColor(.gray)
             )
    }
}

#Preview {
    SongRow(
        song: Song(
            title: "Amr Diab - Ayyam We Ben'eshha",
            artist: "Rotana",
            duration: 195,
            fileSize: 3_670_016,
            thumbnailImageUrl: nil,
            audioURL: URL(fileURLWithPath: "")
        ),
        onTap: {},
        onAddToNextPlay: {},
        onDelete: {}
    )
}
