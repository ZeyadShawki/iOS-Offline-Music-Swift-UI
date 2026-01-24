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
    
    static func getVideoAvailableAudioQualities(from urlString: String) async throws -> [AudioQualityOption] {
        print("🎬 Extracting video ID from: \(urlString)")
        guard let videoID = extractVideoID(from: urlString) else {
            print("❌ Could not extract video ID")
            return []
        }
        print("✅ Video ID: \(videoID)")
        
        // Try .remote only first for better compatibility
        let yt = YouTube(videoID: videoID, methods: [.remote])

        do {
            print("📡 Fetching streams...")
            let streams = try await yt.streams
            print("📹 Total streams: \(streams.count)")
            
            // Get all audio streams
            let audioStreams = streams.filterAudioOnly()
            print("🔊 Audio-only streams: \(audioStreams.count)")
            
            // If no audio-only streams, try to get audio from combined streams
            if audioStreams.isEmpty {
                print("⚠️ No audio-only streams found, checking all streams for audio codecs...")
                let streamsWithAudio = streams.filter { $0.audioCodec != nil }
                print("🔊 Streams with audio codec: \(streamsWithAudio.count)")
                
                // If still nothing, return empty
                if streamsWithAudio.isEmpty {
                    print("❌ No streams with audio found at all")
                    return []
                }
            }
            
            // Group by codec and get unique quality options
            var qualityOptions: [AudioQualityOption] = []
            var seenCodecs = Set<String>()
            
            let streamsToProcess = audioStreams.isEmpty ? streams.filter { $0.audioCodec != nil } : audioStreams
            
            for stream in streamsToProcess {
                guard let audioCodec = stream.audioCodec, let audioBitrate = stream.bitrate  else {
                    print("⚠️ Skipping stream - missing codec or bitrate")
                    continue
                }
                let codecKey = "\(audioCodec.description)-\(audioBitrate)"
                if !seenCodecs.contains(codecKey) {
                    seenCodecs.insert(codecKey)
                    let option = AudioQualityOption(
                        codec: audioCodec,
                        bitrate: audioBitrate,
                        description: "\(audioCodec.description) - \(audioBitrate) kbps"
                    )
                    qualityOptions.append(option)
                    print("➕ Added quality: \(option.description)")
                }
            }
            
            print("✨ Total unique qualities: \(qualityOptions.count)")
            // Sort by bitrate (highest first)
            return qualityOptions.sorted { ($0.bitrate ?? 0) > ($1.bitrate ?? 0) }
        } catch {
            print("❌ YouTubeKit Error fetching streams: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            throw error
        }
    }
        
    static func extractVideoInfo(from urlString: String, audioCodec: AudioCodec) async throws -> YouTubeVideoInfo? {
        print("🎬 extractVideoInfo - Extracting video ID from: \(urlString)")
        guard let videoID = extractVideoID(from: urlString) else {
            print("❌ extractVideoInfo - Could not extract video ID")
            return nil
        }
        print("✅ extractVideoInfo - Video ID: \(videoID)")
        
        let yt = YouTube(videoID: videoID, methods: [.remote])

        do {
            print("📡 extractVideoInfo - Fetching streams and metadata...")
            async let streamsTask = yt.streams
            async let metadataTask = yt.metadata

            let streams = try await streamsTask
            let metadata = try await metadataTask
            
            print("📹 extractVideoInfo - Total streams: \(streams.count)")
            guard let metadata = metadata else {
                print("❌ extractVideoInfo - No metadata available")
                return nil
            }

            // Get the audio stream matching the selected codec
            let audioStreams = streams.filterAudioOnly()
            print("🔊 extractVideoInfo - Audio-only streams: \(audioStreams.count)")
            
            let matchingStreams = audioStreams.filter { $0.audioCodec?.description == audioCodec.description }
            print("🎯 extractVideoInfo - Matching codec streams: \(matchingStreams.count)")
            
            let bestAudio = matchingStreams.highestAudioBitrateStream()

            guard let audioStream = bestAudio else {
                print("❌ extractVideoInfo - No audio stream found for codec: \(audioCodec.description)")
                return nil
            }
            
            print("✅ extractVideoInfo - Found audio stream with codec: \(audioCodec.description)")
            print("✅ extractVideoInfo - Audio URL: \(audioStream.url.absoluteString )")

            // Get thumbnail URL
            var thumbnailURL: URL? = nil
            if let thumbnails = metadata.thumbnail {
                thumbnailURL = thumbnails.url
            }
            
            return YouTubeVideoInfo(
                title: metadata.title,
                channelName: metadata.description,
                duration: nil,
                thumbnailURL: thumbnailURL,
                audioStreamURL: audioStream.url,
                audioMimeType: audioStream.audioCodec
            )
        } catch {
            print("❌ extractVideoInfo - Error: \(error)")
            throw error
        }
    }
}

extension AudioCodec: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.description)
    }
    
    var description: String {
        switch self {
        case .ac3:
            return "AC3"
        case .ec3:
            return "EC3"
        case .mp4a(let version):
            return "M4A (AAC)"
        case .opus:
            return "Opus"
        case .unknown(let codec):
            return "Unknown (\(codec))"
        }
    }
}

struct AudioQualityOption: Hashable {
    let codec: AudioCodec
    let bitrate: Int?
    let description: String
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(codec)
    }
}
