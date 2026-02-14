//
//  DownloadSessionDelegate.swift
//  aboutme
//
//  Created by zeyad Shawki on 14/02/2026.
//

import Foundation

final class DownloadSessionDelegate: NSObject, URLSessionDownloadDelegate,@unchecked Sendable {
    
    private let onDownloadFinished: @Sendable (URLSessionDownloadTask, URL) -> Void
    private let onProgressUpdate: @Sendable (URLSessionDownloadTask, Int64, Int64, Int64) -> Void
    private let onDownloadFailed: @Sendable (URLSessionDownloadTask, Error) -> Void
    private let fileManager: FileManager
    init(
        onDownloadFinished: @escaping @Sendable (URLSessionDownloadTask, URL) -> Void,
        onProgressUpdate: @escaping @Sendable (URLSessionDownloadTask, Int64, Int64, Int64) -> Void,
        onDownloadFailed: @escaping @Sendable (URLSessionDownloadTask, Error) -> Void,
        fileManager: FileManager = .default
    ) {
        self.onDownloadFinished = onDownloadFinished
        self.onProgressUpdate = onProgressUpdate
        self.onDownloadFailed = onDownloadFailed
        self.fileManager = fileManager
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        let tempDir = fileManager.temporaryDirectory
        let tempCopy = tempDir.appendingPathComponent(UUID().uuidString + ".tmp")
        do {
            try fileManager.copyItem(at: location, to: tempCopy)
            onDownloadFinished(downloadTask,tempCopy)
        } catch {
            onDownloadFailed(downloadTask,error)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        onProgressUpdate(downloadTask, bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)

    }

    func urlSession(_ session: URLSession,
                        task: URLSessionTask,
                        didCompleteWithError error: (any Error)?) {
            guard let downloadTask = task as? URLSessionDownloadTask,
                  let error = error else { return }
            onDownloadFailed(downloadTask, error)
    }
}
