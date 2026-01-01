//
//  webView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI

struct WebViewPage: View {

    let url: URL?
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @Binding var selectedSearchEngine : IconButtonOption?
    @Binding var searchURL: URL?
    
    // Download state
    @State private var currentURL: String = ""
    @State private var extractedVideoInfo: YouTubeVideoInfo?
    @State private var showPlaylistPicker = false
    @State private var isExtracting = false
    @StateObject private var downloadManager = DownloadManager.shared

    var searchEngineOptions = [
        IconButtonOption(
            title: "YouTube",
            color: .red,
            imageName: "youtube-logo",
            action: {
                print("YouTube option selected")
            },
            searchEngine: .youtube
        ),
        IconButtonOption(
            title: "Google",
            color: nil,
            imageName: "google-logo",
            action: {
                print("Google option selected")
            },
            searchEngine: .google
        )
    ]

    var body: some View {
        VStack(alignment: .leading){
            HStack {
                navigationBar
                ReusableTextField(
                    text: $text,
                    placeHolder: "Search or enter web address",
                    title: nil,
                    buttonOptions: searchEngineOptions,
                    selectedOption: $selectedSearchEngine,
                    onSearch: onSearch
                )
                Spacer().frame(width: 30)
            }
            ZStack(alignment: .topLeading) {
                if let url = url {
                    WebView(url: url,
                            currentURL: ($currentURL)) { newURL in
                                    handleURLChange(newURL)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyStateView
                }

                // Download button - shows when video info extracted
                if extractedVideoInfo?.audioStreamURL != nil {
                    DownloadOverlayButton {
                        showPlaylistPicker = true
                    }
                }

                // Loading indicator while extracting
                if isExtracting {
                    ProgressView()
                        .padding()
                        .background(Color(.systemBackground).opacity(0.8))
                        .cornerRadius(8)
                        .padding(.trailing, 20)
                        .padding(.bottom, 30)
                }

                // Download progress banner
                if let activeDownload = downloadManager.activeDownloads.first(where: { $0.status == .downloading || $0.status == .pending }) {
                    VStack {
                        Spacer()
                        downloadProgressBanner(for: activeDownload)
                    }
                }

            }
            .navigationBarHidden(true)
        }  .sheet(isPresented: $showPlaylistPicker) {
            if let videoInfo = extractedVideoInfo {
                PlaylistPickerSheet(videoInfo: videoInfo) { playlist in
                    downloadManager.startDownload(videoInfo: videoInfo, to: playlist)
                }
            }
        }
    }
    
    private func handleURLChange(_ urlString: String) {
        print("🔗 URL Changed: \(urlString)")

        // Check if it's a YouTube video URL
        let isYouTube = YouTubeExtractor.isYouTubeURL(urlString: urlString)
        let videoID = YouTubeExtractor.extractVideoID(from: urlString)

        print("📺 Is YouTube URL: \(isYouTube)")
        print("🎬 Extracted Video ID: \(videoID ?? "nil")")

        if isYouTube, videoID != nil {
            extractVideoInfo(from: urlString)
        } else {
            print("❌ Not a valid YouTube video URL")
            extractedVideoInfo = nil
        }
    }
    
    private func extractVideoInfo(from urlString: String) {
        print("🚀 Starting extraction for: \(urlString)")
        isExtracting = true
        Task {
            do {
                let videoInfo = try await YouTubeExtractor.extractVideoInfo(from: urlString)
                await MainActor.run {
                    print("✅ Extraction successful!")
                    print("📝 Title: \(videoInfo?.title ?? "nil")")
                    print("🔊 Audio URL: \(videoInfo?.audioStreamURL?.absoluteString ?? "nil")")
                    extractedVideoInfo = videoInfo
                    isExtracting = false
                }
            } catch {
                print("❌ Failed to extract video info: \(error)")
                await MainActor.run {
                    extractedVideoInfo = nil
                    isExtracting = false
                }
            }
        }
    }
    
    func onSearch() {
        guard let selected = selectedSearchEngine else { return }
        let engine = selected.searchEngine
        searchURL = WebViewSearchHelper.buildSearchURL(query: text, engine: engine)
        // Navigate to WebView page
        
    }
    
    private var navigationBar: some View {
        HStack {
            Button(action: {
                dismiss()
            },){
                HStack(alignment: .firstTextBaseline,) {
                    Image(systemName: "chevron.left").font(.system(size: 18,weight: .bold))
                
                }
            }
           
        } .scaledToFit()   .foregroundColor(.blue)
            .padding(.horizontal, 10)
            .padding(.vertical, 10)
           
    
    }
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.primary)
            Text("Invalid URL")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func downloadProgressBanner(for task: DownloadTask) -> some View {
        HStack(spacing: 12) {
            // Thumbnail
            AsyncImage(url: task.videoInfo.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 50, height: 38)
            .clipShape(RoundedRectangle(cornerRadius: 4))

            // Title and progress
            VStack(alignment: .leading, spacing: 4) {
                Text(task.videoInfo.title)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)

                HStack(spacing: 8) {
                    ProgressView(value: task.progress)
                        .progressViewStyle(.linear)

                    Text("\(Int(task.progress * 100))%")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }

            // Status indicator
            if task.status == .pending {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: -2)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

}

#Preview {
    NavigationStack {
        WebViewPage(
            url: URL(string: "https://www.youtube.com/watch?v=YQHsXMglC9A&list=RDYQHsXMglC9A&start_radio=1"),
            text: .constant(""),
            selectedSearchEngine: .constant(nil),
            searchURL: .constant(nil)
        )
    }
}

