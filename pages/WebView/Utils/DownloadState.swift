import SwiftUI

actor DownloadState {
    var downloadTaskMap: [URLSessionDownloadTask: UUID] = [:]
    var pendingDownloads: [UUID: DownloadTask] = [:]
    
    func setTask(id: UUID, for downloadTask: URLSessionDownloadTask) {
        downloadTaskMap[downloadTask] = id
    }
}
