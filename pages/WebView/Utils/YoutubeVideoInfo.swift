//
//  YoutubeVideoInfo.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Foundation
import YouTubeKit

struct YouTubeVideoInfo: Identifiable {
    let id: UUID = UUID()
    let title: String
    let channelName: String
    let duration: Int?
    let thumbnailURL: URL?
    let audioStreamURL: URL?
    let audioMimeType: AudioCodec?
}

extension Int? {
    var formattedDuration: String? {
        guard let duration = self else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

extension AudioCodec {
    var fileExtension: String {
        switch self {
        case .mp4a:
            return "m4a"
        case .opus:
            return "opus"
        case .unknown:
            return "m4a"
        case .ec3:
            return "ec3"
        case .ac3:
            return "ac3"
        }
    }
}
