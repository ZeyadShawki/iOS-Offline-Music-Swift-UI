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
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
    
    func showDownloadStarted(title: String) {
        print("🔔 Showing download started notification for: \(title)")
        let content = UNMutableNotificationContent()

        content.title = "Downloading"
        content.body = title
        content.sound = nil

        let request = UNNotificationRequest(identifier: "download-started-\(UUID().uuidString)", content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("🔔 Failed to show notification: \(error)")
            } else {
                print("🔔 Notification scheduled successfully")
            }
        }
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
