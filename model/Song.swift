//
//  Song.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//
import SwiftUI

struct Song: Identifiable {
    let id: UUID
    let title: String
    let artist: String
    let duration: Int // Duration in seconds
    let fileSize: Int // File size in MB
    let thumbnailImageUrl: URL?
    let audioURL: URL?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String,
        duration: Int,
        fileSize: Int,
        thumbnailImageUrl: URL? = nil,
        audioURL: URL? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.fileSize = fileSize
        self.thumbnailImageUrl = thumbnailImageUrl
        self.audioURL = audioURL
    }

    // Format duration as "MM:SS" (e.g., "03:41")
    var formattedDuration: String {
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // Format file size (e.g., "14.8 MB" or "1.2 GB")
    var formattedFileSize: String {
        if fileSize >= 1024 {
            return String(format: "%.1f GB", Double(fileSize) / 1024.0)
        }
        return "\(fileSize) MB"
    }
}

extension Array where Element == Song {
    // Total duration in seconds
    var totalDuration: Int {
        reduce(0) { $0 + $1.duration }
    }

    // Format total duration as "HH:MM:SS" or "MM:SS"
    var formattedTotalDuration: String {
        let total = totalDuration
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
