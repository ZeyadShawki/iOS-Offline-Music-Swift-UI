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
