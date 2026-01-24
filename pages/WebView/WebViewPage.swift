//
//  webView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI
import YouTubeKit

struct WebViewPage: View {
    @EnvironmentObject var appRouter: AppRouter
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var webViewModel: WebViewModel
    
    // Download state
    @State private var currentURL: String = ""
    @State private var extractedVideoInfo: YouTubeVideoInfo?
    @State private var showPlaylistPicker = false
    @State private var isLoading = false
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var showQualityPicker = false
    @State private var availableQualities: [AudioQualityOption] = []
    @State private var isValidYoutubeVideo = false

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
        LoadingView(isShowing: $isLoading) {
            VStack(alignment: .leading){
                topBar
                ZStack(alignment: .topLeading) {
                    webview
                    
                    // Download button - shows when video info extracted
                    if isValidYoutubeVideo {
                        DownloadOverlayButton {
                            getAudioQualities()
                        }
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
            }
            .alert("Select Audio Quality", isPresented: $showQualityPicker) {
                qualityPickerButtons
            }
            .sheet(isPresented: $showPlaylistPicker) {
                if let videoInfo = extractedVideoInfo {
                    PlaylistPickerSheet(videoInfo: videoInfo) { playlist in
                        downloadManager.startDownload(videoInfo: videoInfo, to: playlist)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    var qualityPickerButtons: some View {
        Group {
            ForEach(availableQualities, id: \.self) { option in
                Button(option.description) {
                    extractVideoInfo(from: currentURL, audioCodec: option.codec)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    var webview: some View {
        Group {
            if let url = webViewModel.searchURL {
                WebView(url: url,
                        currentURL: $currentURL){ url in
                    isValidYoutubeVideo = YouTubeExtractor.isYouTubeURL(urlString: url)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyStateView
            }
        }
    }
    
    var topBar: some View {
        HStack {
            navigationBar
            ReusableTextField(
                text: $webViewModel.text,
                placeHolder: "Search or enter web address",
                title: nil,
                buttonOptions: searchEngineOptions,
                selectedOption: $webViewModel.selectedSearchEngine,
                onSearch: onSearch
            )
            Spacer().frame(width: 30)
        }
    }
    
    private func extractVideoInfo(from urlString: String,audioCodec: AudioCodec) {
        print("🚀 Starting extraction for: \(urlString)")
        isLoading = true
        Task {
            do {
                let videoInfo = try await YouTubeExtractor.extractVideoInfo(from: urlString,audioCodec: audioCodec)
                await MainActor.run {
                    if let videoInfo = videoInfo {
                        print("✅ Extraction successful!")
                        print("📝 Title: \(videoInfo.title)")
                        print("🔊 Audio URL: \(videoInfo.audioStreamURL?.absoluteString ?? "nil")")
                        extractedVideoInfo = videoInfo
                        showPlaylistPicker = true
                    } else {
                        print("❌ Extraction returned nil video info")
                        extractedVideoInfo = nil
                    }
                    isLoading = false
                }
            } catch {
                print("❌ Failed to extract video info: \(error)")
                await MainActor.run {
                    extractedVideoInfo = nil
                    isLoading = false
                }
            }
        }
    }
    
    func getAudioQualities() {
        print("🔍 Getting audio qualities for URL: \(currentURL)")
        isLoading = true
        Task {
            do {
                let qualities = try await YouTubeExtractor.getVideoAvailableAudioQualities(from: currentURL)
                print("✅ Found \(qualities.count) qualities: \(qualities.map { $0.description })")
                await MainActor.run {
                    availableQualities = qualities
                    if qualities.isEmpty {
                        print("⚠️ No qualities available, not showing picker")
                    } else {
                        print("📱 Showing quality picker with \(qualities.count) options")
                        showQualityPicker = true
                    }
                    isLoading = false

                }
            } catch {
                print("❌ Error getAudioQualities: \(error)")
                await MainActor.run {
                    availableQualities = []
                }
                isLoading = false
            }
        }
    }
    
    func onSearch() {
        guard let selected = webViewModel.selectedSearchEngine else { return }
        webViewModel.searchURL = WebViewSearchHelper.buildSearchURL(query: webViewModel.text, engine: selected.searchEngine)
        if let search = webViewModel.searchURL {
            currentURL = search.absoluteString
        }
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
            webViewModel: WebViewModel(
                text: "",
                selectedSearchEngine: nil,
                searchURL: URL(string: "https://www.youtube.com/watch?v=YQHsXMglC9A&list=RDYQHsXMglC9A&start_radio=1")
            )
        )
    }
}

