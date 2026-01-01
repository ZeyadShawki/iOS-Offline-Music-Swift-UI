//
//  YoutubeExtractor.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Foundation
import YouTubeKit

class YouTubeExtractor {
    
    static func extractVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let host = url.host?.lowercased() ?? ""

        // Handle youtu.be short URLs
        if host.contains("youtu.be") {
            // Format: youtu.be/VIDEO_ID
            if let videoID = url.pathComponents.last, videoID != "/" {
                return videoID
            }
        }

        // Handle youtube.com URLs (including m.youtube.com, www.youtube.com, music.youtube.com)
        if host.contains("youtube.com") {
            // Check for ?v= parameter (most common format)
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }

            // Check for /embed/VIDEO_ID format
            if url.pathComponents.contains("embed"),
               let embedIndex = url.pathComponents.firstIndex(of: "embed"),
               embedIndex + 1 < url.pathComponents.count {
                return url.pathComponents[embedIndex + 1]
            }

            // Check for /shorts/VIDEO_ID format
            if url.pathComponents.contains("shorts"),
               let shortsIndex = url.pathComponents.firstIndex(of: "shorts"),
               shortsIndex + 1 < url.pathComponents.count {
                return url.pathComponents[shortsIndex + 1]
            }
        }

        return nil
    }
    
    static func isYouTubeURL(urlString: String) -> Bool {
        guard let url = URL(string: urlString) else {
            return false
        }
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be") || host.contains("music.youtube.com")
    }
        
    static func extractVideoInfo(from urlString: String)async throws  -> YouTubeVideoInfo? {
        guard let videoID = extractVideoID(from: urlString) else { return nil }
        let yt = YouTube(videoID: videoID, methods: [.local, .remote])

        async let streamsTask = yt.streams
        async let metadataTask = yt.metadata

        let streams = try await streamsTask
        let metadata = try await metadataTask

        // Get the best audio stream (prefer m4a format)
        let audioStreams = streams.filterAudioOnly()
        let m4aStreams = audioStreams.filter { $0.audioCodec == .mp4a }
        let bestAudio = m4aStreams.highestAudioBitrateStream() ?? audioStreams.highestAudioBitrateStream()

        guard let audioStream = bestAudio else {
             return nil
         }
        guard let metadata = metadata else { return nil }

         // Get thumbnail URL
        var thumbnailURL: URL? = nil
        if let thumbnails = metadata.thumbnail {
             thumbnailURL = thumbnails.url
         }
        
        return YouTubeVideoInfo(
            title: metadata.title,
            channelName: metadata.description ,
            duration: nil,
            thumbnailURL: thumbnailURL,
            audioStreamURL: audioStream.url,
            audioMimeType: audioStream.audioCodec,
        )
    }
}
