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
    @State private var songs: [Song] = []

    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var audioManager: AudioManager

    // Init must use _songs for @State
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
        }.padding(.horizontal).task {
            isLoading = true
            songs = await SongManager.shared.loadSongs(for: playlist)
            isLoading = false
        }
    }
    
    private var songList: some View {
        LazyVStack(spacing: 0) {
            ForEach(songs) { song in
                Group {
                    SongRow(song: song, onTap: {
                        audioManager.initQueue(songsQueue: songs,playlist: playlist)
                        audioManager.play(song: song)
                    }, onAddToNextPlay: {
                        
                    }, onDelete: {
                        
                    }).padding(.vertical,10)
                    Divider()
                }.swipeActions(edge: .trailing,allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }.swipeActions(edge: .leading) {
                    Button {
                        
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
