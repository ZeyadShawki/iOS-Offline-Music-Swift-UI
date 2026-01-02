//
//  SongManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 02/01/2026.
//

import Foundation
import AVFoundation
internal import Combine

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
            if let song = await extractMetaData(from: fileURL){
                loadedSongs.append(song)
            }
        }
        
        songs = loadedSongs
        isLoading = false
        return loadedSongs
    }
    
    
    func extractMetaData(from fileURL: URL) async -> Song {
        let asset = AVURLAsset(url: fileURL)
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
            
            title = title?.isEmpty == false ? fileURL.deletingPathExtension().lastPathComponent : title
            artist = artist?.isEmpty == false ? artist! : "Unknown Artist"
            
            let durationSeconds = Int(CMTimeGetSeconds(durationValue))
            let fileSize = FileManagerHelper.getFileSize(from: fileURL)
            
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
                fileSize: FileManagerHelper.getFileSize(from: fileURL),
                thumbnailImageUrl: nil,
                audioURL: fileURL
            )
        }
    }
    
    
    
}
