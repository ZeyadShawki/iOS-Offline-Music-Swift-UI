//
//  DownloadManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Combine
import Foundation

@MainActor
class DownloadManager: NSObject, ObservableObject {
    static let shared = DownloadManager()

    @Published var activeDownloads: [DownloadTask] = []
    @Published var isDownloading = false
    var status: DownloadStatus

    private var backgroundSession: URLSession!
    private var downloadTaskMap: [URLSessionDownloadTask: UUID] = [:]
    private var pendingDownloads: [UUID: DownloadTask] = [:]

    private let fileHelper = FileManagerHelper()
    private let notificationManager = NotificationManager.shared
    private var sessionDelegate: DownloadSessionDelegate!

    override init() {
        self.status = .completed
        super.init()
        let config = URLSessionConfiguration.background(
            withIdentifier: "com.aboutme.download"
        )
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true

        sessionDelegate = DownloadSessionDelegate(onDownloadFinished: { [weak self] downloadTask, tempURL in
            Task { @MainActor in
                               self?.handleDownloadFinished(downloadTask: downloadTask, tempURL: tempURL)
            }
        }, onProgressUpdate: {  [weak self] urlSessionDownloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
            Task { @MainActor in
                                self?.handleProgressUpdate(
                                    downloadTask: urlSessionDownloadTask,
                                    bytesWritten: bytesWritten,
                                    totalBytesWritten: totalBytesWritten,
                                    totalBytesExpectedToWrite: totalBytesExpectedToWrite)
            }
        }, onDownloadFailed: { [weak self] downloadTask, error in
            Task { @MainActor in
                self?.handleDownloadFailed(downloadTask: downloadTask, error: error)
            }
        })
        backgroundSession = URLSession(
            configuration: config,
            delegate: sessionDelegate,
            delegateQueue: nil
        )
    }
    
    private func handleDownloadFinished(downloadTask: URLSessionDownloadTask, tempURL: URL){
        guard let taskID = downloadTaskMap[downloadTask] else {
            print("❌ No task ID found for download")
            return
        }
        downloadTaskMap.removeValue(forKey: downloadTask)
        completeDownload(taskId: taskID, tempURL: tempURL)
    }
    
    private func handleProgressUpdate(
        downloadTask: URLSessionDownloadTask,
        bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let taskId = downloadTaskMap[downloadTask],
              var task = pendingDownloads[taskId] else { return }
        
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0
        let progressPercent = Int(progress * 100)
        print("📥 Progress: \(progressPercent)%")
        task.status = .downloading
        task.progress = progress
        task.downloadedBytes = totalBytesWritten
        task.totalBytes = totalBytesExpectedToWrite
        pendingDownloads[taskId] = task
        notificationManager.updateDownloadProgress(
                    title: task.videoInfo.title,
                    id: taskId.uuidString,
                    progress: progressPercent
                )
                
        updateTask(task)
    }
    
    private func handleDownloadFailed(downloadTask: URLSessionDownloadTask, error: Error) {
        print("❌ Download error: \(error.localizedDescription)")
        
        guard let taskId = downloadTaskMap[downloadTask],
              var task = pendingDownloads[taskId] else { return }
        
        downloadTaskMap.removeValue(forKey: downloadTask)
        task.status = .failed
        task.error = error.localizedDescription
        pendingDownloads.removeValue(forKey: taskId)
        
        updateTask(task)
        notificationManager.showDownloadFailed(
            title: task.videoInfo.title,
            error: error.localizedDescription,
            id: taskId.uuidString
        )
    }

    func startDownload(videoInfo: YouTubeVideoInfo, to playlist: Playlist) async
    {
        print("📥 startDownload called for: \(videoInfo.title)")
        print("📥 Playlist: \(playlist.name)")

        guard let audioURL = videoInfo.audioStreamURL else {
            print("❌ No audio stream URL found")
            return
        }

        print("📥 Audio URL: \(audioURL)")

        let task = DownloadTask(
            videoInfo: videoInfo,
            destinationPlaylist: playlist,
            status: .pending,
            progress: 0,
            downloadedBytes: 0,
            totalBytes: 0,
            startTime: Date(),
            error: nil
        )

        pendingDownloads[task.id] = task
            self.activeDownloads.append(task)
            self.isDownloading = true

        let granted = await notificationManager.requestPermission()
        print("📥 Notification permission granted: \(granted)")
        self.notificationManager.showDownloadStarted(
            title: videoInfo.title,
            id: task.id.uuidString
        )

        var request = URLRequest(url: audioURL)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let downloadTask = backgroundSession.downloadTask(with: request)
        downloadTaskMap[downloadTask] = task.id
        downloadTask.resume()
        print("📥 Download task started")
    }

    private func completeDownload(taskId: UUID, tempURL: URL) {
        guard var task = pendingDownloads[taskId] else { return }

        let videoInfo = task.videoInfo
        let playlist = task.destinationPlaylist

        do {
            let fileExtension = videoInfo.audioMimeType?.fileExtension ?? "m4a"
            let filename =
                fileHelper.sanitizeFilename(videoInfo.title)
                + ".\(fileExtension)"
            guard let playlistFolder = playlist.folderPath else {
                throw NSError(
                    domain: "DownloadManager",
                    code: 1,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Playlist folder not found"
                    ]
                )
            }

            let destinationURL = playlistFolder.appendingPathComponent(filename)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)

            task.status = .completed
            task.progress = 1.0

                self.updateTask(task)
                self.notificationManager.showDownloadCompleted(
                    title: videoInfo.title,
                    playlistName: playlist.name,
                    id: taskId.uuidString
                )
        } catch {
            task.status = .failed
            task.error = error.localizedDescription
                self.updateTask(task)
                self.notificationManager.showDownloadFailed(
                    title: videoInfo.title,
                    error: error.localizedDescription,
                    id: taskId.uuidString
                )
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
