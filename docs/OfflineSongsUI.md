# Offline Songs Page - SwiftUI Implementation Guide

This documentation provides complete SwiftUI code to build the Offline Songs page with all required components including the song list, context menu, and mini player.

## Table of Contents
1. [Overview](#overview)
2. [Data Models](#data-models)
3. [Main Page - OfflineSongsPage](#main-page---offlinesongspage)
4. [Song Row Component](#song-row-component)
5. [Context Menu](#context-menu)
6. [Mini Player](#mini-player)
7. [Supporting Components](#supporting-components)
8. [Audio Player Manager](#audio-player-manager)
9. [Integration](#integration)

---

## Overview

The Offline Songs page displays a playlist's songs with the following features:
- Header with playlist icon, name, and stats
- Play All / Shuffle Play buttons
- Sortable song list
- Context menu for each song (Add to Next Play, Delete)
- Mini player at the bottom

**Color Scheme:**
- Background: Black (`Color.black` or `Color(.systemBackground)`)
- Accent: Orange/Yellow (`Color.orange`)
- Secondary text: Gray (`Color.secondary`)

---

## Data Models

### Updated Song Model (if needed)

```swift
// model/Song.swift
import Foundation
import SwiftUI

struct Song: Identifiable, Equatable {
    let id: UUID
    let title: String
    let artist: String
    let duration: TimeInterval // in seconds
    let fileSize: Int64 // in bytes
    let thumbnailURL: URL?
    let audioURL: URL

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        duration: TimeInterval,
        fileSize: Int64,
        thumbnailURL: URL? = nil,
        audioURL: URL
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.fileSize = fileSize
        self.thumbnailURL = thumbnailURL
        self.audioURL = audioURL
    }

    // Formatted duration string (e.g., "03:15")
    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Formatted file size string (e.g., "3.5 MB")
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
```

### Playlist Extension for Duration Calculation

```swift
// Extension to calculate total playlist duration
extension Array where Element == Song {
    var totalDuration: String {
        let total = self.reduce(0) { $0 + $1.duration }
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let seconds = Int(total) % 60

        if hours > 0 {
            return "\(hours)h \(minutes)m \(seconds)s"
        } else {
            return "\(minutes)m \(seconds)s"
        }
    }
}
```

---

## Main Page - OfflineSongsPage

```swift
// pages/Songs/OfflineSongsPage.swift
import SwiftUI

struct OfflineSongsPage: View {
    let playlist: Playlist
    @State private var songs: [Song] = []
    @State private var sortOption: SortOption = .default
    @State private var showSortMenu = false
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    // Reference to audio player
    @StateObject private var audioPlayer = AudioPlayerManager.shared

    enum SortOption: String, CaseIterable {
        case `default` = "Default"
        case title = "Title"
        case artist = "Artist"
        case duration = "Duration"
        case recentlyAdded = "Recently Added"
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            ScrollView {
                VStack(spacing: 0) {
                    // Header Section
                    headerSection

                    // Action Buttons
                    actionButtons

                    // Sort Button
                    sortButton

                    // Songs List
                    songsList
                }
                .padding(.bottom, 80) // Space for mini player
            }
            .background(Color.black)

            // Mini Player
            if audioPlayer.currentSong != nil {
                MiniPlayer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Playlists")
                    }
                    .foregroundColor(.orange)
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { /* Show playlist options */ }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.orange)
                }
            }
        }
        .task {
            await loadSongs()
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            // Playlist Icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.2))
                    .frame(width: 180, height: 180)

                Circle()
                    .fill(Color.orange)
                    .frame(width: 140, height: 140)

                Image(systemName: "checkmark")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.top, 20)

            // Playlist Title
            Text(playlist.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Song Count & Duration
            Text("\(songs.count) SONGS • \(songs.totalDuration)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Play All Button
            PlayAllButton {
                audioPlayer.playAll(songs: songs)
            }

            // Shuffle Play Button
            ShufflePlayButton {
                audioPlayer.shufflePlay(songs: songs)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Sort Button
    private var sortButton: some View {
        HStack {
            Spacer()

            Menu {
                ForEach(SortOption.allCases, id: \.self) { option in
                    Button(action: {
                        sortOption = option
                        sortSongs()
                    }) {
                        HStack {
                            Text(option.rawValue)
                            if sortOption == option {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal.decrease")
                    Text("Sort by \(sortOption.rawValue)")
                    Image(systemName: "chevron.down")
                }
                .font(.subheadline)
                .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Songs List
    private var songsList: some View {
        LazyVStack(spacing: 0) {
            ForEach(songs) { song in
                SongRow(
                    song: song,
                    onTap: {
                        audioPlayer.play(song: song, from: songs)
                    },
                    onAddToNextPlay: {
                        audioPlayer.addToNextPlay(song: song)
                    },
                    onDelete: {
                        deleteSong(song)
                    }
                )

                Divider()
                    .background(Color.gray.opacity(0.3))
                    .padding(.leading, 80)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Helper Functions
    private func loadSongs() async {
        isLoading = true
        // Load songs from playlist folder
        // This would integrate with your FileManagerHelper
        // For now, using sample data
        songs = [] // Replace with actual loading logic
        isLoading = false
    }

    private func sortSongs() {
        switch sortOption {
        case .default:
            break // Keep original order
        case .title:
            songs.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .artist:
            songs.sort { $0.artist.localizedCompare($1.artist) == .orderedAscending }
        case .duration:
            songs.sort { $0.duration < $1.duration }
        case .recentlyAdded:
            break // Would need date added property
        }
    }

    private func deleteSong(_ song: Song) {
        withAnimation {
            songs.removeAll { $0.id == song.id }
        }
        // Also delete from file system using FileManagerHelper
    }
}
```

---

## Song Row Component

```swift
// pages/Songs/Components/SongRow.swift
import SwiftUI

struct SongRow: View {
    let song: Song
    let onTap: () -> Void
    let onAddToNextPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Tap area for playing song
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Thumbnail
                    songThumbnail

                    // Song Info
                    songInfo
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            // Context Menu Button
            contextMenuButton
        }
        .padding(.vertical, 8)
    }

    // MARK: - Thumbnail
    private var songThumbnail: some View {
        Group {
            if let thumbnailURL = song.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 60, height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "music.note")
                    .foregroundColor(.gray)
            )
    }

    // MARK: - Song Info
    private var songInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Title
            Text(song.title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            // Artist | Duration | File Size
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 10))
                    .foregroundColor(.orange)

                Text(song.artist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("|")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(song.formattedDuration)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text("|")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Text(song.formattedFileSize)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Context Menu Button
    private var contextMenuButton: some View {
        Menu {
            Button(action: onAddToNextPlay) {
                Label("Add to Next Play", systemImage: "text.line.first.and.arrowtriangle.forward")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44)
        }
    }
}

// MARK: - Preview
#Preview {
    SongRow(
        song: Song(
            title: "Amr Diab - Ayyam We Ben'eshha",
            artist: "Rotana",
            duration: 195,
            fileSize: 3_670_016,
            audioURL: URL(fileURLWithPath: "")
        ),
        onTap: {},
        onAddToNextPlay: {},
        onDelete: {}
    )
    .background(Color.black)
}
```

---

## Context Menu

The context menu is integrated into the `SongRow` component using SwiftUI's `Menu` view. Here's the standalone version if you need it separately:

```swift
// pages/Songs/Components/SongContextMenu.swift
import SwiftUI

struct SongContextMenu: View {
    let onAddToNextPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button(action: onAddToNextPlay) {
                Label("Add to Next Play", systemImage: "text.line.first.and.arrowtriangle.forward")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .frame(width: 44, height: 44)
        }
    }
}
```

### Alternative: Swipe Actions

If you prefer swipe-to-delete functionality:

```swift
// In your list, wrap SongRow with swipe actions
ForEach(songs) { song in
    SongRow(song: song, onTap: { /* play */ }, onAddToNextPlay: {}, onDelete: {})
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                deleteSong(song)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                audioPlayer.addToNextPlay(song: song)
            } label: {
                Label("Next", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
            .tint(.orange)
        }
}
```

---

## Mini Player

```swift
// pages/Components/MiniPlayer.swift
import SwiftUI

struct MiniPlayer: View {
    @StateObject private var audioPlayer = AudioPlayerManager.shared

    var body: some View {
        if let song = audioPlayer.currentSong {
            VStack(spacing: 0) {
                // Progress bar (optional)
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.orange)
                        .frame(width: geometry.size.width * audioPlayer.progress)
                }
                .frame(height: 2)

                // Player content
                HStack(spacing: 12) {
                    // Thumbnail
                    thumbnail(for: song)

                    // Song Info
                    songInfo(for: song)

                    Spacer()

                    // Controls
                    playerControls
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6).opacity(0.95))
            }
            .onTapGesture {
                // Navigate to full player
            }
        }
    }

    // MARK: - Thumbnail
    private func thumbnail(for song: Song) -> some View {
        Group {
            if let thumbnailURL = song.thumbnailURL {
                AsyncImage(url: thumbnailURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    thumbnailPlaceholder
                }
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var thumbnailPlaceholder: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color.gray.opacity(0.3))
            .overlay(
                Image(systemName: "music.note")
                    .foregroundColor(.gray)
            )
    }

    // MARK: - Song Info
    private func songInfo(for song: Song) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            Text(song.artist)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: 150, alignment: .leading)
    }

    // MARK: - Player Controls
    private var playerControls: some View {
        HStack(spacing: 20) {
            // Play/Pause
            Button(action: {
                audioPlayer.togglePlayPause()
            }) {
                Image(systemName: audioPlayer.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }

            // Next
            Button(action: {
                audioPlayer.playNext()
            }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }

            // Queue
            Button(action: {
                // Show queue
            }) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack {
        Spacer()
        MiniPlayer()
    }
    .background(Color.black)
}
```

---

## Supporting Components

### Play All Button

```swift
// pages/Songs/Components/PlayAllButton.swift
import SwiftUI

struct PlayAllButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                Text("Play All")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.orange)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }
}
```

### Shuffle Play Button

```swift
// pages/Songs/Components/ShufflePlayButton.swift
import SwiftUI

struct ShufflePlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "shuffle")
                    .font(.system(size: 14))
                Text("Shuffle Play")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.orange)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.orange, lineWidth: 2)
            )
        }
    }
}
```

### Sort Dropdown (Standalone)

```swift
// pages/Songs/Components/SortDropdown.swift
import SwiftUI

struct SortDropdown: View {
    @Binding var selectedOption: SortOption

    enum SortOption: String, CaseIterable {
        case `default` = "Default"
        case title = "Title"
        case artist = "Artist"
        case duration = "Duration"
        case recentlyAdded = "Recently Added"
    }

    var body: some View {
        Menu {
            ForEach(SortOption.allCases, id: \.self) { option in
                Button(action: {
                    selectedOption = option
                }) {
                    HStack {
                        Text(option.rawValue)
                        if selectedOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                Text("Sort by \(selectedOption.rawValue)")
                Image(systemName: "chevron.down")
            }
            .font(.subheadline)
            .foregroundColor(.orange)
        }
    }
}
```

---

## Audio Player Manager

```swift
// pages/Managers/AudioPlayerManager.swift
import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var progress: Double = 0.0
    @Published var currentTime: TimeInterval = 0
    @Published var queue: [Song] = []

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var playlist: [Song] = []
    private var currentIndex: Int = 0

    private init() {
        setupAudioSession()
    }

    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Playback Controls
    func play(song: Song, from playlist: [Song]) {
        self.playlist = playlist
        self.currentIndex = playlist.firstIndex(where: { $0.id == song.id }) ?? 0
        playSong(song)
    }

    func playAll(songs: [Song]) {
        guard !songs.isEmpty else { return }
        playlist = songs
        currentIndex = 0
        playSong(songs[0])
    }

    func shufflePlay(songs: [Song]) {
        guard !songs.isEmpty else { return }
        playlist = songs.shuffled()
        currentIndex = 0
        playSong(playlist[0])
    }

    func togglePlayPause() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
    }

    func playNext() {
        // Check queue first
        if !queue.isEmpty {
            let nextSong = queue.removeFirst()
            playSong(nextSong)
            return
        }

        // Then go to next in playlist
        guard currentIndex + 1 < playlist.count else { return }
        currentIndex += 1
        playSong(playlist[currentIndex])
    }

    func playPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
        playSong(playlist[currentIndex])
    }

    func addToNextPlay(song: Song) {
        queue.insert(song, at: 0)
    }

    func seek(to progress: Double) {
        guard let duration = player?.currentItem?.duration else { return }
        let targetTime = CMTimeMultiplyByFloat64(duration, multiplier: progress)
        player?.seek(to: targetTime)
    }

    // MARK: - Private Methods
    private func playSong(_ song: Song) {
        // Remove previous observer
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }

        currentSong = song
        let playerItem = AVPlayerItem(url: song.audioURL)
        player = AVPlayer(playerItem: playerItem)

        // Add time observer
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600),
            queue: .main
        ) { [weak self] time in
            guard let self = self,
                  let duration = self.player?.currentItem?.duration,
                  !duration.seconds.isNaN else { return }

            self.currentTime = time.seconds
            self.progress = time.seconds / duration.seconds
        }

        // Observe when song ends
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(songDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        player?.play()
        isPlaying = true
    }

    @objc private func songDidFinish() {
        playNext()
    }
}
```

---

## Integration

### 1. Navigate from PlaylistPage to OfflineSongsPage

Update your `PlaylistPage.swift` to navigate:

```swift
// In PlaylistPage.swift
NavigationLink(destination: OfflineSongsPage(playlist: playlist)) {
    PlayistRow(playlist: playlist)
}
```

### 2. Add MiniPlayer to ContentView

Wrap your TabView with ZStack to show mini player globally:

```swift
// ContentView.swift
struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var audioPlayer = AudioPlayerManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DiscoveryPage()
                    .tabItem { /* ... */ }
                    .tag(0)

                PlaylistPage(playlists: [])
                    .tabItem { /* ... */ }
                    .tag(1)

                SettingPage()
                    .tabItem { /* ... */ }
                    .tag(2)
            }
            .padding(.bottom, audioPlayer.currentSong != nil ? 60 : 0)

            // Global Mini Player
            if audioPlayer.currentSong != nil {
                MiniPlayer()
            }
        }
    }
}
```

### 3. File Structure

```
pages/
├── Songs/
│   ├── OfflineSongsPage.swift
│   └── Components/
│       ├── SongRow.swift
│       ├── PlayAllButton.swift
│       ├── ShufflePlayButton.swift
│       └── SortDropdown.swift
├── Components/
│   └── MiniPlayer.swift
└── Managers/
    └── AudioPlayerManager.swift
```

---

## Preview Examples

```swift
#Preview("OfflineSongsPage") {
    NavigationStack {
        OfflineSongsPage(
            playlist: Playlist(
                name: "Offline Songs",
                songCount: 199,
                iconName: "checkmark",
                overlayColor: .orange,
                folderPath: nil
            )
        )
    }
    .preferredColorScheme(.dark)
}

#Preview("MiniPlayer") {
    VStack {
        Spacer()
        MiniPlayer()
    }
    .background(Color.black)
    .preferredColorScheme(.dark)
}
```

---

## Notes

1. **AsyncImage**: Used for loading thumbnails. For local images, use `Image(uiImage:)` with FileManager.
2. **Dark Mode**: All components designed for dark mode. Use `.preferredColorScheme(.dark)`.
3. **AVFoundation**: Required for audio playback. Add to Info.plist if needed.
4. **Background Audio**: Enable "Audio, AirPlay, and Picture in Picture" in Signing & Capabilities.

---

## Required Imports Summary

```swift
import SwiftUI
import AVFoundation
import Combine
```
