//
//  SongManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 02/01/2026.
//

import Foundation
import AVFoundation
import UIKit
import CoreMedia

class SongManager {
        
    let fileManagerHelper: FileManagerHelper = FileManagerHelper()
    private let supportedFormats = ["mp4", "webm", "mov"]
    
    @MainActor
    func loadSongs(for playlist: Playlist) async throws -> [Song] {
        guard let folderPath = playlist.folderPath else {
            throw SongError.customMessage("No Playlist Found")
        }
        let songFiles = fileManagerHelper.getURLsFromFolder(from: folderPath,supportedFormats: supportedFormats)
        var loadedSongs: [Song] = []
        
        for fileURL in songFiles {
            let song = await extractMetaData(from: fileURL)
            loadedSongs.append(song)
        }
        return loadedSongs
    }
    
    
    func extractMetaData(from fileURL: URL) async -> Song {
        let asset = AVURLAsset(url: fileURL)
        do {
            let metadata = try await asset.load(.metadata)
            let durationSeconds = await getVideoDuration(from: fileURL)

            var title: String?
            var artist: String?

            for item in metadata {
                guard let key = item.commonKey else { continue }
                switch key {
                case .commonKeyTitle:
                    title = try? await item.load(.stringValue)
                case .commonKeyArtist:
                    artist = try? await item.load(.stringValue)
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

            let thumbnailURL = fileManagerHelper.generateVideoThumbnail(from: fileURL)
            let fileSize = fileManagerHelper.getFileSize(from: fileURL)

            return Song(
                title: title ?? "N/A",
                artist: artist ?? "N/A",
                duration: durationSeconds,
                fileSize: fileSize,
                thumbnailImageUrl: thumbnailURL,
                audioURL: fileURL
            )
        } catch {
            print("Error extracting metadata from \(fileURL.lastPathComponent): \(error)")
            let thumbnailURL = fileManagerHelper.generateVideoThumbnail(from: fileURL)
            return Song(
                title: fileURL.deletingPathExtension().lastPathComponent,
                artist: "Unknown Artist",
                duration: 0,
                fileSize: fileManagerHelper.getFileSize(from: fileURL),
                thumbnailImageUrl: thumbnailURL,
                audioURL: fileURL
            )
        }
    }

    /// Get duration from video file using AVURLAsset
    private func getVideoDuration(from fileURL: URL) async -> Double {
        do {
            let asset = AVURLAsset(url: fileURL)
            let duration = try await asset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            print("Error getting video duration: \(error)")
            return 0
        }
    }
}
enum SongError: Error {
    case customMessage(String)
}
