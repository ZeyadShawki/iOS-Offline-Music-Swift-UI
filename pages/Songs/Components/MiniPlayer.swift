//
//  MiniPlayer.swift
//  aboutme
//
//  Created by zeyad Shawki on 28/12/2025.
//

import SwiftUI

struct MiniPlayer: View {
    @EnvironmentObject var audioManager: AudioManager
    @EnvironmentObject var appRouter: AppRouter

    var body: some View {
        VStack {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track - always visible for tapping anywhere
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .cornerRadius(20)

                    // Progress fill
                    if audioManager.progress > 0 {
                        Rectangle()
                            .fill(.orange)
                            .frame(width: geometry.size.width * audioManager.progress)
                            .cornerRadius(20)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let progress = min(max(value.location.x / geometry.size.width, 0), 1)
                            audioManager.seek(toProgress: progress)
                        }
                )
            }
            .frame(height: 10)
            HStack(spacing: 12) {
                thumbnail(for: audioManager.currentSong)
                songInfo(for:  audioManager.currentSong)
                Spacer()
                playControls
            }
        }
    }
    
    
    private var playControls: some View {
        HStack(spacing: 20) {
            Button(action: {
                audioManager.previous()

            }) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 20))
                .foregroundColor(.primary)
            }
            Button(action: {
                audioManager.togglePlayPause()
            }) {
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill").font(.system(size: 24)).foregroundColor(.primary)
            }
            
            Button(action: {
                audioManager.next()
            }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20))
                .foregroundColor(.primary)
            }
            
            // Queue
                   Button(action: {
                       guard audioManager.currentPlaylist != nil else { return }
                       // Show queue sheet
                       appRouter.navigatePlaylist(to: .songs(playlist: audioManager.currentPlaylist!))
                   }) {
                       Image(systemName: "list.bullet")
                           .font(.system(size: 20))
                           .foregroundColor(.primary)
               }
        }
    }
    
    private func thumbnail(for song: Song?) -> some View {
        Group {
            if let thumbnail = song?.thumbnailImageUrl {
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
    private func songInfo(for song: Song?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song?.title ?? "")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)        .multilineTextAlignment(.leading)
                .lineLimit(2) // allow unlimited lines

            Text(song?.artist ?? "N/A")
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
    MiniPlayer().environmentObject(AudioManager(song: .mock))
}
