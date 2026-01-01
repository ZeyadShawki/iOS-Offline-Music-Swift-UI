# YouTube Music Download Feature - Implementation Plan

## Overview

Add YouTube video detection and audio download capability to the WebView with:
- Context overlay download button (appears when YouTube video detected)
- Playlist picker sheet for selecting download destination
- System notifications for download progress
- Clean file organization in playlist folders
- **Client-side only** - using YouTubeKit library

---

## Approach: YouTubeKit Library

We use the **YouTubeKit** Swift package (https://github.com/alexeichhorn/YouTubeKit.git) which provides:

1. **Native Swift API** for extracting video/audio stream URLs
2. **Automatic stream filtering** - easily get audio-only streams
3. **Metadata extraction** - title, channel, duration, thumbnails
4. **Format selection** - prefer M4A format for better compatibility

**Advantages over JavaScript injection:**
- More reliable than parsing HTML/JS
- Handles signature deciphering automatically
- Cleaner Swift-native code
- Better maintained

**Limitations:**
- Age-restricted or private videos won't work without auth
- YouTube API changes may require library updates

---

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      WebViewPage                            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    WebView                           │   │
│  │  - Detects YouTube URL navigation                    │   │
│  │  - Triggers YouTubeExtractor on video pages          │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────┐  (shows when video info extracted)   │
│  │ Download Button  │──────────────────────────────────┐   │
│  └──────────────────┘                                  │   │
└────────────────────────────────────────────────────────│───┘
                                                         │
                    ┌────────────────────────────────────┘
                    ▼
        ┌───────────────────────┐
        │  YouTubeExtractor     │
        │  - Uses YouTubeKit    │
        │  - Gets audio streams │
        │  - Extracts metadata  │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │  PlaylistPickerSheet  │
        │  - Video info header  │
        │  - Playlist list      │
        │  - Select destination │
        └───────────┬───────────┘
                    │
                    ▼
        ┌───────────────────────┐
        │   DownloadManager     │
        │  - URLSession download│
        │  - Save to playlist   │
        │  - Send notifications │
        └───────────────────────┘
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `pages/WebView/YouTubeExtractor.swift` | YouTubeKit wrapper + YouTubeVideoInfo model |
| `model/DownloadTask.swift` | Download state tracking |
| `pages/Managers/DownloadManager.swift` | Core download orchestration |
| `pages/Managers/NotificationManager.swift` | System notification handling |
| `pages/WebView/Components/DownloadOverlayButton.swift` | Floating download button |
| `pages/Download/PlaylistPickerSheet.swift` | Playlist selection bottom sheet |
| `pages/Download/Components/PlaylistPickerRow.swift` | Playlist row in picker |

## Files to Modify

| File | Changes |
|------|---------|
| `pages/WebView/WebView.swift` | Add URL change detection, trigger extraction |
| `pages/WebView/WebViewPage.swift` | Add download button overlay, sheet |
| `pages/Managers/FileManagerHelper.swift` | Add audio file saving methods |
| `aboutmeApp.swift` | Request notification permissions |

---

## Implementation Steps

### Phase 1: YouTubeExtractor with YouTubeKit

#### 1.1 Create `pages/WebView/YouTubeExtractor.swift`

```swift
import Foundation
import YouTubeKit

struct YouTubeVideoInfo: Identifiable {
    let id: String
    let title: String
    let channelName: String
    let duration: Int?
    let thumbnailURL: URL?
    let videoURL: URL
    let audioStreamURL: URL?
    let audioMimeType: String?
    let contentLength: Int64?

    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let minutes = duration / 60
        let seconds = duration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var fileExtension: String {
        if let mime = audioMimeType {
            if mime.contains("mp4") || mime.contains("m4a") {
                return "m4a"
            } else if mime.contains("webm") {
                return "webm"
            }
        }
        return "m4a"
    }
}

class YouTubeExtractor {

    static func extractVideoID(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        let host = url.host?.lowercased() ?? ""

        // Handle youtube.com URLs
        if host.contains("youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }
            // Handle /embed/ URLs
            if url.pathComponents.contains("embed"), let videoID = url.pathComponents.last {
                return videoID
            }
        }

        // Handle youtu.be URLs
        if host.contains("youtu.be") {
            let videoID = url.pathComponents.last
            return videoID
        }

        // Handle music.youtube.com URLs
        if host.contains("music.youtube.com") {
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               let videoID = components.queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }
        }

        return nil
    }

    static func isYouTubeURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let host = url.host?.lowercased() ?? ""
        return host.contains("youtube.com") || host.contains("youtu.be") || host.contains("music.youtube.com")
    }

    static func extractVideoInfo(from urlString: String) async throws -> YouTubeVideoInfo? {
        guard let videoID = extractVideoID(from: urlString),
              let originalURL = URL(string: urlString) else {
            return nil
        }

        let youtube = YouTube(videoID: videoID)

        async let streamsTask = youtube.streams
        async let metadataTask = youtube.metadata

        let streams = try await streamsTask
        let metadata = try await metadataTask

        // Get the best audio stream (prefer m4a format)
        let audioStreams = streams.filterAudioOnly()
        let m4aStreams = audioStreams.filter { $0.subtype == "mp4" }
        let bestAudio = m4aStreams.highestAudioBitrateStream() ?? audioStreams.highestAudioBitrateStream()

        guard let audioStream = bestAudio else {
            return nil
        }

        // Get thumbnail URL
        var thumbnailURL: URL? = nil
        if let thumbnails = metadata.thumbnails, let bestThumbnail = thumbnails.last {
            thumbnailURL = bestThumbnail.url
        }

        return YouTubeVideoInfo(
            id: videoID,
            title: metadata.title ?? "Unknown Title",
            channelName: metadata.author ?? "Unknown Channel",
            duration: metadata.duration,
            thumbnailURL: thumbnailURL,
            videoURL: originalURL,
            audioStreamURL: audioStream.url,
            audioMimeType: audioStream.mimeType,
            contentLength: audioStream.contentLength
        )
    }
}
```

---

### Phase 2: Download Infrastructure

#### 2.1 Create `model/DownloadTask.swift`

```swift
import Foundation

struct DownloadTask: Identifiable {
    let id: UUID
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
        guard let startTime = startTime,
              progress > 0 && progress < 1 else { return nil }
        let elapsed = Date().timeIntervalSince(startTime)
        let remaining = (elapsed / progress) - elapsed
        if remaining < 60 { return "\(Int(remaining))s remaining" }
        return "\(Int(remaining) / 60)m remaining"
    }
}
```

#### 2.2 Create `pages/Managers/NotificationManager.swift`

```swift
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func showDownloadStarted(title: String) {
        let content = UNMutableNotificationContent()
        content.title = "Downloading"
        content.body = title
        content.sound = nil

        let request = UNNotificationRequest(
            identifier: "download-started-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func showDownloadCompleted(title: String, playlistName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\(title) saved to \(playlistName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "download-complete-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func showDownloadFailed(title: String, error: String) {
        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "\(title): \(error)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "download-failed-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
```

#### 2.3 Create `pages/Managers/DownloadManager.swift`

```swift
import Foundation
import Combine

class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [DownloadTask] = []
    @Published var isDownloading = false

    private var backgroundSession: URLSession!
    private var downloadTaskMap: [URLSessionDownloadTask: UUID] = [:]
    private var pendingDownloads: [UUID: DownloadTask] = [:]

    private let fileHelper = FileManagerHelper()
    private let notificationManager = NotificationManager.shared

    override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.aboutme.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func startDownload(videoInfo: YouTubeVideoInfo, to playlist: Playlist) {
        guard let audioURL = videoInfo.audioStreamURL else {
            notificationManager.showDownloadFailed(title: videoInfo.title, error: "No audio stream found")
            return
        }

        let task = DownloadTask(
            id: UUID(),
            videoInfo: videoInfo,
            destinationPlaylist: playlist,
            status: .downloading,
            progress: 0,
            downloadedBytes: 0,
            totalBytes: 0,
            startTime: Date(),
            error: nil
        )

        pendingDownloads[task.id] = task
        DispatchQueue.main.async {
            self.activeDownloads.append(task)
            self.isDownloading = true
        }

        notificationManager.showDownloadStarted(title: videoInfo.title)

        var request = URLRequest(url: audioURL)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let downloadTask = backgroundSession.downloadTask(with: request)
        downloadTaskMap[downloadTask] = task.id
        downloadTask.resume()
    }

    private func completeDownload(taskId: UUID, tempURL: URL) {
        guard var task = pendingDownloads[taskId] else { return }

        let videoInfo = task.videoInfo
        let playlist = task.destinationPlaylist

        do {
            let filename = fileHelper.sanitizeFilename(videoInfo.title) + ".\(videoInfo.fileExtension)"
            guard let playlistFolder = playlist.folderPath else {
                throw NSError(domain: "DownloadManager", code: 1,
                              userInfo: [NSLocalizedDescriptionKey: "Playlist folder not found"])
            }

            let destinationURL = playlistFolder.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            task.status = .completed
            task.progress = 1.0

            DispatchQueue.main.async {
                self.updateTask(task)
                self.notificationManager.showDownloadCompleted(
                    title: videoInfo.title,
                    playlistName: playlist.name
                )
            }
        } catch {
            task.status = .failed
            task.error = error.localizedDescription
            DispatchQueue.main.async {
                self.updateTask(task)
                self.notificationManager.showDownloadFailed(
                    title: videoInfo.title,
                    error: error.localizedDescription
                )
            }
        }

        pendingDownloads.removeValue(forKey: taskId)
    }

    private func updateTask(_ task: DownloadTask) {
        if let index = activeDownloads.firstIndex(where: { $0.id == task.id }) {
            activeDownloads[index] = task
        }
        isDownloading = activeDownloads.contains { $0.status == .downloading }
    }
}

// MARK: - URLSessionDownloadDelegate
extension DownloadManager: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        guard let taskId = downloadTaskMap[downloadTask] else { return }
        downloadTaskMap.removeValue(forKey: downloadTask)
        completeDownload(taskId: taskId, tempURL: location)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let taskId = downloadTaskMap[downloadTask],
              var task = pendingDownloads[taskId] else { return }

        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0

        task.progress = progress
        task.downloadedBytes = totalBytesWritten
        task.totalBytes = totalBytesExpectedToWrite
        pendingDownloads[taskId] = task

        DispatchQueue.main.async { self.updateTask(task) }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let downloadTask = task as? URLSessionDownloadTask,
              let taskId = downloadTaskMap[downloadTask],
              let error = error else { return }

        downloadTaskMap.removeValue(forKey: downloadTask)
        if var task = pendingDownloads[taskId] {
            task.status = .failed
            task.error = error.localizedDescription
            pendingDownloads.removeValue(forKey: taskId)
            DispatchQueue.main.async {
                self.updateTask(task)
                self.notificationManager.showDownloadFailed(
                    title: task.videoInfo.title,
                    error: error.localizedDescription
                )
            }
        }
    }
}
```

#### 2.4 Modify `pages/Managers/FileManagerHelper.swift`

Add these methods:

```swift
func sanitizeFilename(_ filename: String) -> String {
    let invalidChars = CharacterSet(charactersIn: "/\\?%*|\"<>:")
    return filename.components(separatedBy: invalidChars).joined(separator: "_")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

func generateUniqueFilename(_ base: String, ext: String, in folder: URL) -> String {
    var filename = "\(base).\(ext)"
    var counter = 1
    while FileManager.default.fileExists(atPath: folder.appendingPathComponent(filename).path) {
        filename = "\(base) (\(counter)).\(ext)"
        counter += 1
    }
    return filename
}
```

---

### Phase 3: UI Components

#### 3.1 Create `pages/WebView/Components/DownloadOverlayButton.swift`

```swift
import SwiftUI

struct DownloadOverlayButton: View {
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 56, height: 56)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                Image(systemName: "arrow.down.to.line.alt")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
        .padding(.trailing, 20)
        .padding(.bottom, 30)
    }
}
```

#### 3.2 Create `pages/Download/Components/PlaylistPickerRow.swift`

```swift
import SwiftUI

struct PlaylistPickerRow: View {
    let playlist: Playlist

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(playlist.overlayColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                Image(systemName: playlist.iconName)
                    .foregroundColor(playlist.overlayColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .medium))
                Text("\(playlist.songCount) songs")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
```

#### 3.3 Create `pages/Download/PlaylistPickerSheet.swift`

```swift
import SwiftUI

struct PlaylistPickerSheet: View {
    let videoInfo: YouTubeVideoInfo
    var onPlaylistSelected: (Playlist) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var playlists: [Playlist] = []
    @State private var isLoading = true

    private let playlistManager = PlaylistManager()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Video info header
                videoHeader
                    .padding()
                    .background(Color(.systemGray6))

                Divider()

                // Playlist list
                if isLoading {
                    ProgressView("Loading playlists...")
                        .frame(maxHeight: .infinity)
                } else if playlists.isEmpty {
                    emptyState
                } else {
                    List(playlists) { playlist in
                        PlaylistPickerRow(playlist: playlist)
                            .onTapGesture {
                                onPlaylistSelected(playlist)
                                dismiss()
                            }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Save to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .task {
            playlistManager.fetchPlaylists { fetched in
                playlists = fetched
                isLoading = false
            }
        }
    }

    private var videoHeader: some View {
        HStack(spacing: 12) {
            AsyncImage(url: videoInfo.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.3))
            }
            .frame(width: 80, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(videoInfo.title)
                    .font(.system(size: 15, weight: .medium))
                    .lineLimit(2)
                Text(videoInfo.channelName)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                if let duration = videoInfo.formattedDuration {
                    Text(duration)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Playlists")
                .font(.headline)
            Text("Create a playlist first to save downloads")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
}
```

---

### Phase 4: Integration

#### 4.1 Modify `pages/WebView/WebView.swift`

```swift
import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    let url: URL?
    @Binding var currentURL: String
    var onURLChange: ((String) -> Void)?

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("Page started loading!")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("Page finished loading!")
            if let urlString = webView.url?.absoluteString {
                DispatchQueue.main.async {
                    self.parent.currentURL = urlString
                    self.parent.onURLChange?(urlString)
                }
            }
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let urlString = navigationAction.request.url?.absoluteString {
                DispatchQueue.main.async {
                    self.parent.currentURL = urlString
                    self.parent.onURLChange?(urlString)
                }
            }
            decisionHandler(.allow)
        }
    }
}
```

#### 4.2 Modify `pages/WebView/WebViewPage.swift`

```swift
import SwiftUI

struct WebViewPage: View {

    let url: URL?
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @Binding var selectedSearchEngine: IconButtonOption?
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
            action: { print("YouTube option selected") },
            searchEngine: .youtube
        ),
        IconButtonOption(
            title: "Google",
            color: nil,
            imageName: "google-logo",
            action: { print("Google option selected") },
            searchEngine: .google
        )
    ]

    var body: some View {
        VStack(alignment: .leading) {
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

            ZStack(alignment: .bottomTrailing) {
                if let url = url {
                    WebView(url: url, currentURL: $currentURL) { newURL in
                        handleURLChange(newURL)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showPlaylistPicker) {
            if let videoInfo = extractedVideoInfo {
                PlaylistPickerSheet(videoInfo: videoInfo) { playlist in
                    downloadManager.startDownload(videoInfo: videoInfo, to: playlist)
                }
            }
        }
    }

    private func handleURLChange(_ urlString: String) {
        // Check if it's a YouTube video URL
        if YouTubeExtractor.isYouTubeURL(urlString),
           YouTubeExtractor.extractVideoID(from: urlString) != nil {
            extractVideoInfo(from: urlString)
        } else {
            extractedVideoInfo = nil
        }
    }

    private func extractVideoInfo(from urlString: String) {
        isExtracting = true
        Task {
            do {
                let videoInfo = try await YouTubeExtractor.extractVideoInfo(from: urlString)
                await MainActor.run {
                    extractedVideoInfo = videoInfo
                    isExtracting = false
                }
            } catch {
                print("Failed to extract video info: \(error)")
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
    }

    private var navigationBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                HStack(alignment: .firstTextBaseline) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                }
            }
        }
        .scaledToFit()
        .foregroundColor(.blue)
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
}

#Preview {
    NavigationStack {
        WebViewPage(
            url: URL(string: "https://www.google.com"),
            text: .constant(""),
            selectedSearchEngine: .constant(nil),
            searchURL: .constant(nil)
        )
    }
}
```

#### 4.3 Modify `aboutmeApp.swift`

```swift
import SwiftUI

@main
struct aboutmeApp: App {

    init() {
        Task {
            await NotificationManager.shared.requestPermission()
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Implementation Order

1. `pages/WebView/YouTubeExtractor.swift` (includes YouTubeVideoInfo model)
2. `model/DownloadTask.swift`
3. `pages/Managers/NotificationManager.swift`
4. Modify `pages/Managers/FileManagerHelper.swift`
5. `pages/Managers/DownloadManager.swift`
6. Modify `pages/WebView/WebView.swift`
7. `pages/WebView/Components/DownloadOverlayButton.swift`
8. `pages/Download/Components/PlaylistPickerRow.swift`
9. `pages/Download/PlaylistPickerSheet.swift`
10. Modify `pages/WebView/WebViewPage.swift`
11. Modify `aboutmeApp.swift`

---

## Notification Flow

1. **Download Started**: "Downloading: [Song Title]"
2. **Download Complete**: "[Song Title] saved to [Playlist Name]"
3. **Download Failed**: "[Song Title]: [Error message]"

---

## Limitations & Notes

1. **Age-restricted/Private videos**: Cannot be downloaded without authentication
2. **YouTubeKit updates**: Library may need updates when YouTube changes their API
3. **Audio format**: Downloads are in M4A or WebM format as provided by YouTube
4. **Background downloads**: URLSession continues even if app is suspended
5. **Stream expiration**: Audio stream URLs expire after some time - download should start promptly
