//
//  DownloadOverlayButton.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import SwiftUI
import YouTubeKit

struct PlaylistPickerSheet:
    View {
    
    let videoInfo: YouTubeVideoInfo
    var onPlaylistSelected: (Playlist) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var playlists: [Playlist] = []
    @State private var isLoading = false

    private let playlistManager = PlaylistManager()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 5) {
                videoHeader
                      .padding()
                      .background(Color(.systemGray6))
                Divider()

                if isLoading {
                    ProgressView("Loading playlists...").frame(maxWidth: .infinity)
                } else if playlists.isEmpty {
                    emptyState
                } else {
                    List(playlists) { playlist in
                        PlaylistPickerRow(playlist: playlist
                        ).onTapGesture {
                            print("🎵 Playlist selected: \(playlist.name)")
                            onPlaylistSelected(playlist)
                            dismiss()
                        }
                    }.listStyle(.plain)
                }
            }
            .navigationTitle("Save to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task {
                isLoading = true
                playlists = await playlistManager.fetchPlaylists()
                isLoading = false
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Playlists")
                .font(.headline)
            Text("Create a playlist first to save downloads")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var videoHeader: some View {
        HStack (spacing: 12,) {
            AsyncImage(url: videoInfo.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                .fill(.gray.opacity(0.3))            }.frame(width: 80,height: 60).clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                    Text(videoInfo.title)
                        .font(.system(size: 15, weight: .medium))
                        .lineLimit(2)
                    Text(videoInfo.channelName)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                if let duration = videoInfo.duration.formattedDuration {
                        Text(duration)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            Spacer()

        }
    }
}

#Preview {
    PlaylistPickerSheet(videoInfo:  YouTubeVideoInfo(
        title: "SwiftUI Tutorial for Beginners",
        channelName: "Zeyad Dev Channel",
        duration: 372, // 6 min 12 sec
        thumbnailURL: URL(string: "https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg"),
        videoStreamURL: URL(string: "https://example.com/video.mp4"),
        videoCodec: .avc1(version: "640028")
    ), onPlaylistSelected: { playlist in

    })
}
