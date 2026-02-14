//
//  YoutubeExtractor.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Foundation
@preconcurrency import YouTubeKit

class YouTubeExtractor {

    static func extractVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let host = url.host?.lowercased() ?? ""

        // Handle youtu.be short URLs
        if host.contains("youtu.be") {
            if let videoID = url.pathComponents.last, videoID != "/" {
                return videoID
            }
        }

        // Handle youtube.com URLs (including m.youtube.com, www.youtube.com, music.youtube.com)
        if host.contains("youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }

            if url.pathComponents.contains("embed"),
               let embedIndex = url.pathComponents.firstIndex(of: "embed"),
               embedIndex + 1 < url.pathComponents.count {
                return url.pathComponents[embedIndex + 1]
            }

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

    /// Fetches streams + metadata in parallel, auto-picks the best natively playable stream.
    static func extractVideoInfo(from urlString: String) async throws -> YouTubeVideoInfo? {
        guard let videoID = extractVideoID(from: urlString) else {
            return nil
        }

        // .local uses on-device JavaScriptCore (fast), .remote is fallback
        let yt = YouTube(videoID: videoID, methods: [.local, .remote])

        async let streamsTask = yt.streams
        async let metadataTask = yt.metadata

        let streams = try await streamsTask
        let metadata = try await metadataTask

        // Prefer video-only (adaptive, higher res), fall back to progressive (video+audio)
        let videoOnly = streams.filterVideoOnly()
        let progressive = streams.filterVideoAndAudio()
        let allVideo = videoOnly + progressive

        // Pick the best stream: highest resolution among natively playable, fallback to any
        let best = allVideo
            .filter { $0.isNativelyPlayable }
            .sorted { ($0.videoResolution ?? 0) > ($1.videoResolution ?? 0) }
            .first
            ?? allVideo
                .sorted { ($0.videoResolution ?? 0) > ($1.videoResolution ?? 0) }
                .first

        guard let videoStream = best else {
            return nil
        }

        return YouTubeVideoInfo(
            title: metadata?.title ?? "Unknown",
            channelName: metadata?.description ?? "Unknown",
            duration: nil,
            thumbnailURL: metadata?.thumbnail?.url,
            videoStreamURL: videoStream.url,
            videoCodec: videoStream.videoCodec
        )
    }
}

extension VideoCodec: Hashable {
    public static func == (lhs: VideoCodec, rhs: VideoCodec) -> Bool {
        lhs.codecDescription == rhs.codecDescription
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.codecDescription)
    }

    var codecDescription: String {
        switch self {
        case .avc1:
            return "H.264"
        case .mp4v:
            return "MP4V"
        case .vp9:
            return "VP9"
        case .av1:
            return "AV1"
        case .unknown(let codec):
            return "Unknown (\(codec))"
        }
    }
}

