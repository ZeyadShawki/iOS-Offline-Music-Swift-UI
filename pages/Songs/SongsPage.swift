//
//  SongsPage.swift
//  aboutme
//
//  Created by zeyad Shawki on 28/12/2025.
//

import Foundation
import SwiftUI

struct SongsPage: View {
    let playlist: Playlist
    private let songManager = SongManager()
    private let fileManager = FileManagerHelper()
    private let playlistManager = PlaylistManager()
    @State private var songs: [Song] = []

    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appRouter: AppRouter
    @EnvironmentObject var audioManager: AudioManager
    @State var errorMessage: String?
    @State private var showPlaylistPicker = false
    @State private var selectedSongForList: Song?
    @State private var availablePlaylists: [Playlist] = []

    init(playlist: Playlist, songs: [Song] = []) {
        self.playlist = playlist
        _songs = State(initialValue: songs)
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0){
                    if isLoading {
                        ProgressView("Loading Songs...").padding(.top,40)
                    } else if songs.isEmpty {
                        Text("No Songs in this playlist").foregroundColor(.secondary).padding(.top, 40)
                    } else {
                        headerSection
                        songList
                    }
                }
            }
        }.padding(.horizontal)
        .task {
            isLoading = true
            do {
                songs = try await songManager.loadSongs(for: playlist)
            } catch SongError.customMessage(let message) {
                print("Error: \(message)")
            } catch {
                print("Other error: \(error)")
            }
            isLoading = false
        }
        .sheet(isPresented: $showPlaylistPicker) {
            SongPlaylistPickerSheet(
                playlists: availablePlaylists,
                onSelect: { targetPlaylist in
                    copyToPlaylist(song: selectedSongForList, playlist: targetPlaylist)
                    showPlaylistPicker = false
                }
            )
        }
    }
    
    private var songList: some View {
        LazyVStack(spacing: 0) {
            ForEach(songs) { song in
                Group {
                    SongRow(song: song, onTap: {
                        audioManager.initQueue(songsQueue: songs,playlist: playlist)
                        audioManager.loadSong(song: song)
                        appRouter.navigatePlaylist(to: .songDetail(song: song))
                    }, onAddToNextPlay: {
                        audioManager.addToQueue(song: song)
                    }, onAddToList: {
                        selectedSongForList = song
                        Task {
                            availablePlaylists = await playlistManager.fetchPlaylists().filter { $0.id != playlist.id }
                        }
                        showPlaylistPicker = true
                    }, onDelete: {
                        deleteSong(song)
                    }).padding(.vertical,10)
                    Divider()
                }.swipeActions(edge: .trailing,allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteSong(song)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }.swipeActions(edge: .leading) {
                    Button {
                        audioManager.addToQueue(song: song)
                    } label: {
                        Label("Next", systemImage: "text.line.first.and.arrowtriangle.forward")
                    }
                    .tint(.orange)
                }
            }

        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(.orange.opacity(0.2)).frame(width: 180,height: 180)
                Circle().fill(.orange).frame(width: 140,height: 140)
                Image(systemName: "play.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }.padding(.top, 20)
            // Playlist Title
            Text(playlist.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            // Song Count & Duration
            Text("\(songs.count) SONGS • \(songs.formattedTotalDuration)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)

    }

    private func deleteSong(_ song: Song) {
        guard let audioURL = song.audioURL else { return }
        if fileManager.deleteSongFile(at: audioURL) {
            withAnimation {
                songs.removeAll { $0.id == song.id }
            }
            if audioManager.currentSong?.id == song.id {
                audioManager.next()
            }
            audioManager.queue.removeAll { $0.id == song.id }
        }
    }

    private func copyToPlaylist(song: Song?, playlist targetPlaylist: Playlist) {
        guard let song = song,
              let sourceURL = song.audioURL,
              let destinationFolder = targetPlaylist.folderPath else { return }
        fileManager.copySongFile(from: sourceURL, to: destinationFolder)
    }
}

struct SongPlaylistPickerSheet: View {
    let playlists: [Playlist]
    let onSelect: (Playlist) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(playlists) { playlist in
                Button(action: {
                    onSelect(playlist)
                    dismiss()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: playlist.iconName)
                            .font(.title2)
                            .foregroundColor(playlist.overlayColor)
                            .frame(width: 40, height: 40)
                        VStack(alignment: .leading) {
                            Text(playlist.name)
                                .font(.body)
                                .foregroundColor(.primary)
                            Text("\(playlist.songCount) songs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Add to List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}



#Preview {
    NavigationStack {
        SongsPage(
            playlist: Playlist(
                name: "Offline Songs",
                songCount: 199,
                iconName: "checkmark",
                overlayColor: .orange,
                folderPath: nil
            ),
            songs:  [
                Song(
                    title: "Amr Diab - Ayyam We Ben'eshha",
                    artist: "Rotana",
                    duration: 195,
                    fileSize: 3_670_016,
                    thumbnailImageUrl: nil,
                    audioURL: URL(fileURLWithPath: "")
                ),
                Song(
                    title: "Amr Diab - Ayyam We Ben'eshha",
                    artist: "Rotana",
                    duration: 195,
                    fileSize: 3_670_016,
                    thumbnailImageUrl: nil,
                    audioURL: URL(fileURLWithPath: "")
                ),
            ]
                            
        )
    }
    
}
