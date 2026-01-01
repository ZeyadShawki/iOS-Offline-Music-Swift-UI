//
//  NotificationManager.swift
//  aboutme
//
//  Created by zeyad Shawki on 01/01/2026.
//

import Foundation
import UserNotifications

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    override init() {
        super.init()
        // Set delegate to show notifications while app is in foreground
        UNUserNotificationCenter.current().delegate = self
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [
                .alert,.badge,.sound
            ])
            print("🔔 Notification permission result: \(granted)")
            return granted
        } catch {
            print("🔔 Notification permission error: \(error)")
            return false
        }
    }

    // Show notifications even when app is in foreground
    // Only show banner for complete/failed notifications, progress updates are silent
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let id = notification.request.identifier
        // Only complete/failed notifications show banner, progress updates are silent
        if id.contains("download-complete") || id.contains("download-failed") {
            completionHandler([.banner, .sound])
        } else if id.hasPrefix("download-") {
            // Progress and started notifications - update silently (stays in notification center)
            completionHandler([.list])
        } else {
            completionHandler([.banner, .sound])
        }
    }
    
    func showDownloadStarted(title: String, id: String) {
        print("🔔 Showing download started notification for: \(title)")
        let content = UNMutableNotificationContent()

        content.title = "Downloading"
        content.body = title
        content.sound = nil

        // Same identifier used throughout download lifecycle
        let request = UNNotificationRequest(identifier: "download-\(id)", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 Failed to show notification: \(error)")
            } else {
                print("🔔 Notification scheduled successfully")
            }
        }
    }

    func updateDownloadProgress(title: String, id: String, progress: Int) {
        let content = UNMutableNotificationContent()

        content.title = "Downloading \(progress)%"
        content.body = title
        content.sound = nil

        // Same identifier - updates the existing notification in-place
        let request = UNNotificationRequest(identifier: "download-\(id)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    func showDownloadCompleted(title: String, playlistName: String, id: String) {
        // Remove the download notification
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["download-\(id)"])

        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\(title) saved to \(playlistName)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "download-complete-\(id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func showDownloadFailed(title: String, error: String, id: String) {
        // Remove the download notification
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["download-\(id)"])

        let content = UNMutableNotificationContent()
        content.title = "Download Failed"
        content.body = "\(title): \(error)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "download-failed-\(id)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
    
    
    
}
