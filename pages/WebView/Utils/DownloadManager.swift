//
//  DownloadManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Foundation
internal import Combine

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
    
    override init() {
        self.status = .completed
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.aboutme.download")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }
    
    func startDownload(videoInfo: YouTubeVideoInfo, to playlist: Playlist) {
        print("📥 startDownload called for: \(videoInfo.title)")
        print("📥 Playlist: \(playlist.name)")

        guard let audioURL = videoInfo.audioStreamURL else {
            print("❌ No audio stream URL found")
            return
        }

        print("📥 Audio URL: \(audioURL)")

        let task = DownloadTask(videoInfo: videoInfo, destinationPlaylist: playlist, status: .pending, progress: 0, downloadedBytes: 0, totalBytes: 0,startTime: Date(),error: nil)

        pendingDownloads[task.id] = task
        DispatchQueue.main.async {
            self.activeDownloads.append(task)
            self.isDownloading = true
        }

        // Request notification permission before showing
        Task {
            let granted = await notificationManager.requestPermission()
            print("📥 Notification permission granted: \(granted)")
            self.notificationManager.showDownloadStarted(title: videoInfo.title, id: task.id.uuidString)
        }

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
            let filename = fileHelper.sanitizeFilename((( videoInfo.title) + ".\(String(describing: videoInfo.audioMimeType))"))
            guard let playlistFolder = playlist.folderPath else {
                throw NSError(domain: "DownloadManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Playlist folder not found"])
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
                self.notificationManager.showDownloadCompleted(title: videoInfo.title, playlistName: playlist.name, id: taskId.uuidString)
            }

            } catch {
                task.status = .failed
                task.error = error.localizedDescription
                DispatchQueue.main.async {
                    self.updateTask(task)
                    self.notificationManager.showDownloadFailed(
                        title: videoInfo.title,
                        error: error.localizedDescription,
                        id: taskId.uuidString
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

extension DownloadManager: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("📥 Download finished! Temp location: \(location)")
        guard let taskId = downloadTaskMap[downloadTask] else {
            print("❌ No task ID found for download")
            return
        }
        downloadTaskMap.removeValue(forKey: downloadTask)
        completeDownload(taskId: taskId, tempURL: location)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let taskId = downloadTaskMap[downloadTask], var task = pendingDownloads[taskId] else { return }
        let progress = totalBytesExpectedToWrite > 0 ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) : 0
        let progressPercent = Int(progress * 100)

        print("📥 Progress: \(progressPercent)%")

        task.status = .downloading
        task.progress = progress
        task.downloadedBytes = totalBytesWritten
        task.totalBytes = totalBytesExpectedToWrite
        pendingDownloads[taskId] = task

        // Update notification every 1% to avoid too many updates
        let previousProgress = Int((task.progress - (Double(bytesWritten) / Double(totalBytesExpectedToWrite))) * 100)
        if progressPercent / 1 > previousProgress / 1 || progressPercent == 100 {
            notificationManager.updateDownloadProgress(
                title: task.videoInfo.title,
                id: taskId.uuidString,
                progress: progressPercent
            )
        }

        DispatchQueue.main.async { self.updateTask(task) }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let error = error {
            print("❌ Download error: \(error.localizedDescription)")
        } else {
            print("✅ Download task completed without error")
        }

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
                    error: error.localizedDescription,
                    id: taskId.uuidString
                )
            }
        }
    }
    
    
    
}

