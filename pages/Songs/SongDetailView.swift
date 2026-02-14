//
//  SongDetailView.swift
//  aboutme
//
//  Created by zeyad Shawki on 14/02/2026.
//

import SwiftUI
import AVKit

struct SongDetailView: View {
    let song: Song
    @EnvironmentObject var audioManager: AudioManager

    var body: some View {
        VStack(spacing: 0) {
            // Video player
            if let player = audioManager.player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
            } else {
                thumbnailView
            }

            Spacer().frame(height: 24)

            // Song info
            VStack(spacing: 4) {
                Text(song.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                Text(song.artist)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Spacer().frame(height: 24)

            progressSection

            Spacer().frame(height: 16)

            playbackControls

            Spacer()
        }
        .padding(.top, 20)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var thumbnailView: some View {
        Group {
            if let thumbURL = song.thumbnailImageUrl {
                AsyncImage(url: thumbURL) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    thumbnailPlaceholder
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(maxWidth: 300, maxHeight: 300)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 10)
        .padding(.horizontal)
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.gray.opacity(0.3))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Image(systemName: "video.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
            )
    }

    private var progressSection: some View {
        VStack(spacing: 4) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * audioManager.progress)
                        .cornerRadius(4)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let progress = min(max(value.location.x / geometry.size.width, 0), 1)
                            Task {
                                await audioManager.seek(toProgress: progress)
                            }
                        }
                )
            }
            .frame(height: 6)

            HStack {
                Text(formatTime(audioManager.currentTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(song.formattedDuration)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 24)
    }

    private var playbackControls: some View {
        HStack(spacing: 40) {
            Button(action: { audioManager.previous() }) {
                Image(systemName: "backward.end.fill")
                    .font(.system(size: 28))
            }

            Button(action: { audioManager.togglePlayPause() }) {
                Image(systemName: audioManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 56))
            }

            Button(action: { audioManager.next() }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 28))
            }
        }
        .foregroundColor(.primary)
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    SongDetailView(song: .mock)
        .environmentObject(AudioManager(song: .mock))
}
