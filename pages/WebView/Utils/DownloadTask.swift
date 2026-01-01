//
//  YoutubeExtractor.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Foundation
import YouTubeKit

struct DownloadTask: Identifiable {
    let id: UUID = UUID()
    let videoInfo: YouTubeVideoInfo
    let destinationPlaylist: Playlist
    var status: DownloadStatus
    var progress: Double
    var downloadedBytes: Int64
    var totalBytes: Int64
    var startTime: Date?
    var error: String?
    
    enum DownloadStatus: String {
        case pending
        case downloading
        case completed
        case failed
        case cancelled
    }
    var estimatedTimeRemaining: String? {
        guard let startTime = startTime, progress > 0 && progress < 1 else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = (elapsed / progress) - elapsed
        if remaining < 60 { return "\(Int(remaining))s remaining" }
        return "\(Int(remaining) / 60)m remaining"
    }
    
    
    
}

enum DownloadStatus: String {
    case pending
    case downloading
    case completed
    case failed
    case cancelled
}
