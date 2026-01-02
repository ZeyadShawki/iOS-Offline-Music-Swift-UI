# SongManager & AudioManager Implementation Guide

## Overview

This document contains the complete implementation for two manager classes:
1. **SongManager** - Load songs from playlist folders and extract metadata from audio files
2. **AudioManager** - Handle audio playback with background support, queue management, and all standard controls

---

## How to Add Background Audio Capability in Xcode

### Step-by-Step Instructions:

1. **Open your project in Xcode**

2. **Select your project** in the Navigator (left sidebar) - click on the blue project icon at the top

3. **Select your app target** under "TARGETS" (not the project)

4. **Go to "Signing & Capabilities" tab** (at the top, next to "General" and "Build Settings")

5. **Click "+ Capability" button** (top left of the capabilities section)

6. **Search for "Background Modes"** and double-click to add it

7. **Check the box for "Audio, AirPlay, and Picture in Picture"**

That's it! Your app can now play audio in the background.

### What this does:
- Allows audio to continue playing when the app is minimized
- Enables lock screen controls (play, pause, skip)
- Shows your app in Control Center
- Displays Now Playing info on lock screen

---

## Complete SongManager.swift Implementation

**Create file at:** `pages/Managers/SongManager.swift`

```swift
//
//  SongManager.swift
//  aboutme
//

import Foundation
import AVFoundation
import Combine

class SongManager: ObservableObject {
    static let shared = SongManager()

    // MARK: - Published Properties
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    // MARK: - Private Properties
    private let supportedFormats = ["mp3", "m4a", "aac", "wav", "flac"]

    private init() {}

    // MARK: - Public Methods

    /// Load all songs from a playlist folder
    /// - Parameter playlist: The playlist to load songs from
    /// - Returns: Array of Song objects
    @MainActor
    func loadSongs(for playlist: Playlist) async -> [Song] {
        guard let folderPath = playlist.folderPath else {
            errorMessage = "Playlist folder not found"
            return []
        }

        isLoading = true
        errorMessage = nil

        let songFiles = getSongFiles(from: folderPath)
        var loadedSongs: [Song] = []

        for fileURL in songFiles {
            if let song = await extractMetadata(from: fileURL) {
                loadedSongs.append(song)
            }
        }

        songs = loadedSongs
        isLoading = false
        return loadedSongs
    }

    /// Refresh songs for a playlist (for pull-to-refresh)
    /// - Parameter playlist: The playlist to refresh
    @MainActor
    func refreshPlaylist(_ playlist: Playlist) async {
        _ = await loadSongs(for: playlist)
    }

    // MARK: - Private Methods

    /// Get all audio file URLs from a folder
    /// - Parameter folderURL: The folder URL to scan
    /// - Returns: Array of audio file URLs
    private func getSongFiles(from folderURL: URL) -> [URL] {
        let fileManager = FileManager.default

        guard let enumerator = fileManager.enumerator(
            at: folderURL,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        var audioFiles: [URL] = []

        for case let fileURL as URL in enumerator {
            let fileExtension = fileURL.pathExtension.lowercased()
            if supportedFormats.contains(fileExtension) {
                audioFiles.append(fileURL)
            }
        }

        // Sort by filename
        return audioFiles.sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    /// Extract metadata from an audio file using AVAsset
    /// - Parameter fileURL: The audio file URL
    /// - Returns: A Song object with extracted metadata, or nil on failure
    private func extractMetadata(from fileURL: URL) async -> Song? {
        let asset = AVAsset(url: fileURL)

        do {
            let metadata = try await asset.load(.metadata)
            let durationValue = try await asset.load(.duration)

            var title: String?
            var artist: String?
            var artworkData: Data?

            for item in metadata {
                guard let key = item.commonKey else { continue }

                switch key {
                case .commonKeyTitle:
                    title = try? await item.load(.stringValue)
                case .commonKeyArtist:
                    artist = try? await item.load(.stringValue)
                case .commonKeyArtwork:
                    artworkData = try? await item.load(.dataValue)
                default:
                    break
                }
            }

            // Fallback to filename if no title found
            let finalTitle = title?.isEmpty == false ? title! : fileURL.deletingPathExtension().lastPathComponent
            let finalArtist = artist?.isEmpty == false ? artist! : "Unknown Artist"

            // Save artwork to cache if available
            var artworkURL: URL?
            if let data = artworkData {
                artworkURL = saveArtworkToCache(data: data, songId: fileURL.lastPathComponent)
            }

            let durationSeconds = Int(CMTimeGetSeconds(durationValue))
            let fileSize = getFileSize(from: fileURL)

            return Song(
                title: finalTitle,
                artist: finalArtist,
                duration: durationSeconds,
                fileSize: fileSize,
                thumbnailImageUrl: artworkURL,
                audioURL: fileURL
            )
        } catch {
            print("Error extracting metadata from \(fileURL.lastPathComponent): \(error)")

            // Return song with filename as title on error
            return Song(
                title: fileURL.deletingPathExtension().lastPathComponent,
                artist: "Unknown Artist",
                duration: 0,
                fileSize: getFileSize(from: fileURL),
                thumbnailImageUrl: nil,
                audioURL: fileURL
            )
        }
    }

    /// Get file size in MB
    /// - Parameter fileURL: The file URL
    /// - Returns: File size in MB
    private func getFileSize(from fileURL: URL) -> Int {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
            if let size = attributes[.size] as? Int64 {
                // Convert bytes to MB
                return Int(size / (1024 * 1024))
            }
        } catch {
            print("Error getting file size: \(error)")
        }
        return 0
    }

    /// Save artwork data to cache directory and return the URL
    /// - Parameters:
    ///   - data: The image data
    ///   - songId: Unique identifier for the song (usually filename)
    /// - Returns: URL to the cached artwork, or nil on failure
    private func saveArtworkToCache(data: Data, songId: String) -> URL? {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let artworkDir = cacheDir.appendingPathComponent("artwork")

        // Create artwork directory if needed
        do {
            try FileManager.default.createDirectory(at: artworkDir, withIntermediateDirectories: true)
        } catch {
            print("Error creating artwork directory: \(error)")
            return nil
        }

        // Create a safe filename from songId
        let safeFilename = songId.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
        let artworkURL = artworkDir.appendingPathComponent("\(safeFilename).jpg")

        do {
            try data.write(to: artworkURL)
            return artworkURL
        } catch {
            print("Error saving artwork: \(error)")
            return nil
        }
    }
}
```

---

## Complete AudioManager.swift Implementation

**Create file at:** `pages/Managers/AudioManager.swift`

```swift
//
//  AudioManager.swift
//  aboutme
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    // MARK: - Playback State
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0  // 0.0 to 1.0

    // MARK: - Queue State
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var shuffleEnabled = false
    @Published var repeatMode: RepeatMode = .none

    // MARK: - Enums
    enum RepeatMode: CaseIterable {
        case none
        case all
        case one

        /// Icon name for SF Symbols
        var icon: String {
            switch self {
            case .none: return "repeat"
            case .all: return "repeat"
            case .one: return "repeat.1"
            }
        }

        /// Whether repeat is active (for UI highlighting)
        var isActive: Bool {
            self != .none
        }
    }

    // MARK: - Private Properties
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var originalQueue: [Song] = []  // For shuffle toggle
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    private override init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
        setupNotifications()
    }

    deinit {
        removeTimeObserver()
    }

    // MARK: - Audio Session Setup

    /// Configure AVAudioSession for background playback
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Remote Commands Setup (Lock Screen & Control Center)

    /// Setup lock screen and Control Center controls
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // Toggle play/pause (for headphone button)
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        // Next track
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.next()
            return .success
        }

        // Previous track
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previous()
            return .success
        }

        // Seek (for scrubbing in Control Center)
        commandCenter.changePlaybackPositionCommand.isEnabled = true
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
    }

    // MARK: - Notifications Setup

    /// Setup notifications for audio interruptions and route changes
    private func setupNotifications() {
        // Handle interruptions (phone calls, alarms, etc.)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )

        // Handle route changes (headphones unplugged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }

    /// Handle audio interruptions (phone calls, etc.)
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        switch type {
        case .began:
            // Interruption began - pause playback
            pause()
        case .ended:
            // Interruption ended - check if we should resume
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }
        @unknown default:
            break
        }
    }

    /// Handle audio route changes (headphones unplugged)
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }

        // Pause when headphones are unplugged
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    // MARK: - Playback Control

    /// Play a single song
    /// - Parameter song: The song to play
    func play(song: Song) {
        guard let audioURL = song.audioURL else {
            print("No audio URL for song: \(song.title)")
            return
        }

        // Clean up previous player
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)

        // Create new player item
        playerItem = AVPlayerItem(url: audioURL)
        player = AVPlayer(playerItem: playerItem)

        // Setup time observer for progress updates
        setupTimeObserver()

        // Setup end of track notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        // Update state
        currentSong = song

        // Get duration asynchronously
        Task { @MainActor in
            if let item = playerItem {
                do {
                    let durationValue = try await item.asset.load(.duration)
                    duration = CMTimeGetSeconds(durationValue)
                } catch {
                    print("Error loading duration: \(error)")
                    duration = 0
                }
            }
        }

        // Start playback
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    /// Play a list of songs starting at a specific index
    /// - Parameters:
    ///   - songs: Array of songs to play
    ///   - index: Index to start playing from (default 0)
    func play(songs: [Song], startingAt index: Int = 0) {
        guard !songs.isEmpty else { return }

        originalQueue = songs

        if shuffleEnabled {
            // Keep the starting song at the beginning, shuffle the rest
            var shuffledSongs = songs
            if index < songs.count {
                let startingSong = songs[index]
                shuffledSongs.remove(at: index)
                shuffledSongs.shuffle()
                shuffledSongs.insert(startingSong, at: 0)
            } else {
                shuffledSongs.shuffle()
            }
            queue = shuffledSongs
            currentIndex = 0
        } else {
            queue = songs
            currentIndex = min(index, songs.count - 1)
        }

        if let song = queue[safe: currentIndex] {
            play(song: song)
        }
    }

    /// Pause playback
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    /// Resume playback
    func resume() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    /// Toggle play/pause state
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    /// Skip to next song in queue
    func next() {
        guard !queue.isEmpty else { return }

        switch repeatMode {
        case .one:
            // In repeat one mode, next still goes to next song
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else if repeatMode == .all || repeatMode == .one {
                currentIndex = 0
            } else {
                return
            }
        case .all:
            // Loop back to start when reaching end
            currentIndex = (currentIndex + 1) % queue.count
        case .none:
            // Stop at end of queue
            if currentIndex < queue.count - 1 {
                currentIndex += 1
            } else {
                return // End of queue
            }
        }

        if let song = queue[safe: currentIndex] {
            play(song: song)
        }
    }

    /// Go to previous song or restart current song
    /// If more than 3 seconds into the song, restart it. Otherwise go to previous.
    func previous() {
        guard !queue.isEmpty else { return }

        // If more than 3 seconds into the song, restart it
        if currentTime > 3 {
            seek(to: 0)
            return
        }

        // Otherwise go to previous song
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            // Loop to end if repeat all is on
            currentIndex = queue.count - 1
        } else {
            // At start of queue, just restart current song
            seek(to: 0)
            return
        }

        if let song = queue[safe: currentIndex] {
            play(song: song)
        }
    }

    /// Seek to a specific time in seconds
    /// - Parameter time: Time in seconds to seek to
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }

    /// Seek to a progress percentage (0.0 to 1.0)
    /// - Parameter progress: Progress value between 0.0 and 1.0
    func seek(toProgress progress: Double) {
        let clampedProgress = max(0, min(1, progress))
        let targetTime = duration * clampedProgress
        seek(to: targetTime)
    }

    // MARK: - Queue Management

    /// Add a song to the end of the queue
    /// - Parameter song: Song to add
    func addToQueue(_ song: Song) {
        queue.append(song)
        originalQueue.append(song)
    }

    /// Add a song to play next (after current song)
    /// - Parameter song: Song to add
    func playNext(_ song: Song) {
        let insertIndex = currentIndex + 1
        if insertIndex <= queue.count {
            queue.insert(song, at: insertIndex)
            originalQueue.insert(song, at: insertIndex)
        } else {
            addToQueue(song)
        }
    }

    /// Remove a song from the queue at a specific index
    /// - Parameter index: Index to remove
    func removeFromQueue(at index: Int) {
        guard index >= 0 && index < queue.count else { return }

        queue.remove(at: index)

        // Adjust currentIndex if needed
        if index < currentIndex {
            currentIndex -= 1
        } else if index == currentIndex && currentIndex >= queue.count {
            currentIndex = max(0, queue.count - 1)
        }
    }

    /// Clear the entire queue and stop playback
    func clearQueue() {
        queue.removeAll()
        originalQueue.removeAll()
        currentIndex = 0
        currentSong = nil
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        progress = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    /// Toggle shuffle mode
    func toggleShuffle() {
        shuffleEnabled.toggle()

        if shuffleEnabled {
            // Shuffle the queue but keep current song at current position
            guard let currentSong = currentSong else { return }
            var remaining = queue
            remaining.remove(at: currentIndex)
            remaining.shuffle()
            remaining.insert(currentSong, at: currentIndex)
            queue = remaining
        } else {
            // Restore original order
            if let currentSong = currentSong,
               let newIndex = originalQueue.firstIndex(where: { $0.id == currentSong.id }) {
                queue = originalQueue
                currentIndex = newIndex
            }
        }
    }

    /// Cycle through repeat modes: none → all → one → none
    func cycleRepeatMode() {
        switch repeatMode {
        case .none:
            repeatMode = .all
        case .all:
            repeatMode = .one
        case .one:
            repeatMode = .none
        }
    }

    // MARK: - Private Helpers

    /// Setup periodic time observer for progress updates
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = CMTimeGetSeconds(time)
            if self.duration > 0 {
                self.progress = self.currentTime / self.duration
            }
        }
    }

    /// Remove the time observer
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
    }

    /// Called when the current song finishes playing
    @objc private func playerDidFinishPlaying() {
        switch repeatMode {
        case .one:
            // Repeat the same song
            seek(to: 0)
            resume()
        case .all:
            // Go to next song (will loop back to start)
            next()
        case .none:
            // Go to next song or stop at end
            if currentIndex < queue.count - 1 {
                next()
            } else {
                isPlaying = false
                updateNowPlayingInfo()
            }
        }
    }

    /// Update Now Playing info for lock screen and Control Center
    private func updateNowPlayingInfo() {
        guard let song = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }

        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]

        // Add artwork if available
        if let artworkURL = song.thumbnailImageUrl,
           let imageData = try? Data(contentsOf: artworkURL),
           let image = UIImage(data: imageData) {
            let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
            nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
}

// MARK: - Array Safe Subscript Extension

extension Array {
    /// Safely access array element at index, returns nil if out of bounds
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
```

---

## Files to Modify

### 1. Song.swift - Add Hashable Conformance

Add this extension at the end of the file:

```swift
// MARK: - Hashable Conformance
extension Song: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Song, rhs: Song) -> Bool {
        lhs.id == rhs.id
    }
}
```

---

### 2. SongsPage.swift - Complete Modified Version

```swift
import Foundation
import SwiftUI

struct SongsPage: View {
    let playlist: Playlist

    @State private var songs: [Song] = []
    @State private var isLoading = true
    @ObservedObject private var audioManager = AudioManager.shared
    @Environment(\.dismiss) private var dismiss

    init(playlist: Playlist) {
        self.playlist = playlist
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 0) {
                    headerSection
                    if isLoading {
                        ProgressView("Loading songs...")
                            .padding(.top, 40)
                    } else if songs.isEmpty {
                        Text("No songs in this playlist")
                            .foregroundColor(.secondary)
                            .padding(.top, 40)
                    } else {
                        songList
                    }
                }
            }
        }
        .padding(.horizontal)
        .task {
            isLoading = true
            songs = await SongManager.shared.loadSongs(for: playlist)
            isLoading = false
        }
    }

    private var songList: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(songs.enumerated()), id: \.element.id) { index, song in
                Group {
                    SongRow(song: song, onTap: {
                        // Play this song and set queue to all songs
                        audioManager.play(songs: songs, startingAt: index)
                    }, onAddToNextPlay: {
                        audioManager.playNext(song)
                    }, onDelete: {
                        // TODO: Implement delete song from playlist
                    }).padding(.vertical, 10)
                    Divider()
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        // TODO: Implement delete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        audioManager.playNext(song)
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
                Circle().fill(.orange.opacity(0.2)).frame(width: 180, height: 180)
                Circle().fill(.orange).frame(width: 140, height: 140)
                Image(systemName: "play.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundColor(.white)
            }.padding(.top, 20)

            Text(playlist.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Text("\(songs.count) SONGS • \(songs.formattedTotalDuration)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.bottom, 20)
    }
}
```

---

### 3. MiniPlayer.swift - Complete Modified Version

```swift
import SwiftUI

struct MiniPlayer: View {
    @ObservedObject private var audioManager = AudioManager.shared

    var body: some View {
        if let song = audioManager.currentSong {
            VStack {
                // Progress bar with seek gesture
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 10)
                            .cornerRadius(20)

                        Rectangle()
                            .fill(.orange)
                            .frame(width: geometry.size.width * audioManager.progress)
                            .cornerRadius(20)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let progress = value.location.x / geometry.size.width
                                audioManager.seek(toProgress: progress)
                            }
                    )
                }
                .frame(height: 10)

                HStack(spacing: 12) {
                    thumbnail(for: song)
                    songInfo(for: song)
                    Spacer()
                    playControls
                }
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
                Image(systemName: audioManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.primary)
            }

            Button(action: {
                audioManager.next()
            }) {
                Image(systemName: "forward.end.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
            }

            Button(action: {
                // TODO: Show queue sheet
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
            } else {
                thumbnailPlaceholder
            }
        }
        .frame(width: 50, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func songInfo(for song: Song) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(song.title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(2)

            Text(song.artist)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(alignment: .leading)
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
```

---

### 4. ContentView.swift - Complete Modified Version

```swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @ObservedObject private var audioManager = AudioManager.shared

    init(selectedTab: Int = 0) {
        self.selectedTab = selectedTab
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DiscoveryPage(text: "").tabItem {
                    Label("Discovery", systemImage: "safari.fill")
                }
                PlaylistPage(playlists: []).tabItem {
                    Label("PlayList", systemImage: "books.vertical.fill")
                }
                SettingPage().tabItem {
                    Label("Setting", systemImage: "gear")
                }
            }
            .padding(.bottom, audioManager.currentSong != nil ? 80 : 0)

            if audioManager.currentSong != nil {
                MiniPlayer()
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .background(
                        Color(.systemBackground)
                            .opacity(0.95)
                            .ignoresSafeArea()
                    )
            }
        }
    }
}
```

---

## Implementation Order

1. **Add Background Audio Capability** in Xcode (see instructions at top)
2. **Create SongManager.swift** - copy the complete implementation above
3. **Create AudioManager.swift** - copy the complete implementation above
4. **Update Song.swift** - add Hashable extension
5. **Update SongsPage.swift** - replace with modified version
6. **Update MiniPlayer.swift** - replace with modified version
7. **Update ContentView.swift** - replace with modified version
8. **Test** - background playback, lock screen controls, shuffle/repeat

---

## Summary

| Feature | Implementation |
|---------|---------------|
| Play/Pause | `AVPlayer` with `play()`/`pause()` |
| Next/Previous | Queue management with `currentIndex` |
| Seek | `AVPlayer.seek(to:)` with `CMTime` |
| Progress | Periodic time observer every 0.5 seconds |
| Background Audio | `AVAudioSession.setCategory(.playback)` |
| Lock Screen | `MPRemoteCommandCenter` |
| Control Center | `MPNowPlayingInfoCenter` |
| Shuffle | Shuffle queue array, keep original for toggle |
| Repeat | `RepeatMode` enum (none/all/one) |
| Metadata | `AVAsset.load(.metadata)` for ID3/M4A tags |
| Interruptions | Handle phone calls, headphone unplug |
