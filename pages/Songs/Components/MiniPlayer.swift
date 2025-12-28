//
//  MiniPlayer.swift
//  aboutme
//
//  Created by zeyad Shawki on 28/12/2025.
//

import SwiftUI

struct MiniPlayer: View {
    var song: Song
    init(song: Song) {
        self.song = song
    }
    
    var body: some View {
        VStack {
            GeometryReader { geometry in
                Rectangle().fill(.orange)
                    .frame(width: geometry.size.width * 0.3,
                    ).cornerRadius(20)
            }.frame(height: 10)
            
            HStack(spacing: 12) {
                thumbnail( for :song)
                songInfo(for: song)
                Spacer()
                playControls
            }
        }
    }
    
    
    private var playControls: some View {
        HStack(spacing: 20) {
            Button(action: {}) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 20))
                .foregroundColor(.primary)
            }
            Button(action: {
                
            }) {
                Image(systemName: true ? "pause.fill" : "play.fill").font(.system(size: 24)).foregroundColor(.primary)
            }
            
            Button(action: {}) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20))
                .foregroundColor(.primary)
            }
            
            // Queue
                   Button(action: {
                       // Show queue sheet
                   }) {
                       Image(systemName: "list.bullet")
                           .font(.system(size: 20))
                           .foregroundColor(.primary)
               }
        }
    }
    
    private func thumbnail(for song: Song) -> some View {
        Group {
            if let thumbnail = song.thumbnailImageUrl {
                AsyncImage(url: thumbnail) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
            }else {
                thumbnailPlaceholder
            }
        }.frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 6))
    }
    // MARK: - Song Info
    private func songInfo(for song: Song) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)        .multilineTextAlignment(.leading)
                .lineLimit(2) // allow unlimited lines

            Text(song.artist ?? "N/A")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame( alignment: .leading)
    }
    
    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "music.note")
                    .foregroundColor(.gray)
            )
    }
    
}

#Preview {
    MiniPlayer(
        song: Song(
            title: "Amr Diab - Ayyam We Ben'eshha",
            artist: "Rotana",
            duration: 195,
            fileSize: 3_670_016,
            thumbnailImageUrl: nil,
            audioURL: URL(fileURLWithPath: "")
        ),
    )
}
