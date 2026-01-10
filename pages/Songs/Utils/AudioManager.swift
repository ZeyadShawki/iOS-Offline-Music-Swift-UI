//
//  AudioManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 10/01/2026.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine

class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()
    
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var duration: TimeInterval = 0
    
    @Published var queue: [Song] = []
    @Published var currentIndex: Int = 0
    @Published var shuffleEnabled = false
    
    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
    }
    
    deinit {
        
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback,mode: .default,options: [])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session \(error)")
        }
    }
    
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
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
    
    private func setupNotifications() {
        // Handle interruptions (phone calls, alarms, etc.)
        NotificationCenter.default.addObserver(self, selector:  #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        
        // Handle route changes (headphones unplugged)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
    }
    
    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo, let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                resume()
            }
            
        default:
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
        
        if reason == .oldDeviceUnavailable {
            pause()
        }
        
    }
    
    func play(song: Song) {
        guard let audioURL = song.audioURL else {
            print("No audio  URL for song: \(song.title)")
            return
        }
        removeTimeObserver()
        NotificationCenter.default.removeObserver(self, name: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem)
        
        playerItem = AVPlayerItem(url: audioURL)
        player = AVPlayer(playerItem: playerItem)
        
        setupTimeObserver()
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying), name: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem)
        currentSong = song
        
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
        
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    func play(songs: [Song], startingAt index: Int = 0) {
        guard index > songs.count - 1 else {
            print("index out of range")
            return
        }
        guard songs.isEmpty else {
            return
        }
        if shuffleEnabled {
            var shuffledSongs = songs
       
            let startingSong = songs[index]
            shuffledSongs.remove(at: index)
            shuffledSongs.shuffle()
            shuffledSongs.insert(startingSong, at: 0)
            queue = shuffledSongs
            currentIndex = 0
        } else {
            queue = songs
            currentIndex = min(index,songs.count - 1)
        }
       let song = queue[currentIndex]
       play(song: song)
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
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
    
    func next() {
        guard !queue.isEmpty else {
            return
        }
        currentIndex = currentIndex < queue.count - 1 ? currentIndex + 1 : 0
        let song = queue[currentIndex]
        play(song: song)
    }
    
    func previous() {
        guard !queue.isEmpty else {
            return
        }
        currentIndex = currentIndex < queue.count - 1 ? currentIndex - 1 : queue.count - 1
        let song = queue[currentIndex]
        play(song: song)
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds:time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
    }
    
    func seek(toProgress progress: Double) {
        let clampedProgress = max(0, min(1,progress))
        let targetTime = duration * clampedProgress
        seek(to: targetTime)
    }
    
    func addToQueue(song: Song) {
        queue.append(song)
    }
    
    func removeFromQueue(at index: Int) {
        guard index < queue.count - 1 else {
            return
        }
        queue.remove(at: index)
        if currentIndex == index {
            next()
        }
    }
    
    func clearQueue() {
        queue.removeAll()
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
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else {
                return
            }
            
            self.currentTime = CMTimeGetSeconds(time)
            if self.duration > 0 {
                self.progress = self.currentTime / self.duration
            }
        }
    }
    
    private func removeTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
    
    /// Called when the current song finishes playing
    @objc private func playerDidFinishPlaying() {
        next()
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
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
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
