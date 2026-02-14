//
//  webView.swift
//  aboutme
//
//  Created by zeyad Shawki on 06/12/2025.
//

import SwiftUI

struct WebViewPage: View {
    @EnvironmentObject var appRouter: AppRouter
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var webViewModel: WebViewModel
    
    // Download state
    @State private var currentURL: String = ""
    @State private var extractedVideoInfo: YouTubeVideoInfo?
    @State private var isLoading = false
    @StateObject private var downloadManager = DownloadManager.shared
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
                            downloadVideo()
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
            .sheet(item: $extractedVideoInfo) { videoInfo in
                PlaylistPickerSheet(videoInfo: videoInfo) { playlist in
                    Task { @MainActor in
                        await downloadManager.startDownload(videoInfo: videoInfo, to: playlist)
                    }
                }
            }
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
    
    private func downloadVideo() {
        isLoading = true
        Task {
            do {
                let videoInfo = try await YouTubeExtractor.extractVideoInfo(from: currentURL)
                await MainActor.run {
                    extractedVideoInfo = videoInfo
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
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

