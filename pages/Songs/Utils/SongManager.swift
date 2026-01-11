//
//  SongManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 02/01/2026.
//

import Foundation
import AVFoundation
import Combine

class SongManager: ObservableObject {
    
    static let shared = SongManager()
    
    @Published var songs: [Song] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    let fileManagerHelper: FileManagerHelper = FileManagerHelper()
    private let supportedFormats = ["mp3", "m4a", "aac", "wav", "flac"]

    
    @MainActor
    func loadSongs(for playlist: Playlist) async -> [Song] {
        guard let folderPath = playlist.folderPath else {
            errorMessage = "Playlist folder not found"
            return []
        }
        isLoading = true
        errorMessage = nil
        let songFiles = fileManagerHelper.getURLsFromFolder(from: folderPath,supportedFormats: supportedFormats)
        var loadedSongs: [Song] = []
        
        for fileURL in songFiles {
            let song = await extractMetaData(from: fileURL)
            loadedSongs.append(song)

        }
        
        songs = loadedSongs
        isLoading = false
        return loadedSongs
    }
    
    
    func extractMetaData(from fileURL: URL) async -> Song {
        let asset = AVURLAsset(url: fileURL)
        do {
            // Load metadata
            let metadata = try await asset.load(.metadata)

            // Get actual duration using AVAudioFile (calculates from sample count, ignores bad metadata)
            let durationSeconds = getAudioFileDuration(from: fileURL)

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

            if title == nil || title?.isEmpty == true {
                title = fileURL.deletingPathExtension().lastPathComponent
            }
            if artist == nil || artist?.isEmpty == true {
                artist = "Unknown Artist"
            }

            let fileSize = fileManagerHelper.getFileSize(from: fileURL)
            
            return Song(
                title: title ?? "N/A",
                artist: artist ?? "N/A",
                duration: durationSeconds,
                fileSize: fileSize,
                thumbnailImageUrl: nil,
                audioURL: fileURL
            )
        } catch {
            print("Error extracting metadata from \(fileURL.lastPathComponent): \(error)")

            // Return song with filename as title on error
            return Song(
                title: fileURL.deletingPathExtension().lastPathComponent,
                artist: "Unknown Artist",
                duration: 0,
                fileSize: fileManagerHelper.getFileSize(from: fileURL),
                thumbnailImageUrl: nil,
                audioURL: fileURL
            )
        }
    }

    /// Calculate actual audio duration from sample count (ignores incorrect metadata)
    private func getAudioFileDuration(from fileURL: URL) -> Double {
        do {
            let audioFile = try AVAudioFile(forReading: fileURL)
            let sampleRate = audioFile.processingFormat.sampleRate
            let frameCount = audioFile.length

            guard sampleRate > 0 else { return 0 }

            let duration = Double(frameCount) / sampleRate
            return duration
        } catch {
            print("Error reading audio file for duration: \(error)")
            return 0
        }
    }
}
