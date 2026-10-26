//
//  NotificationManager.swift
//  Bus Buddy
//
//  Handles requesting notification permission and sending local notifications.
//  Local notifications show real banners on the device / simulator.
//

import Foundation
import UserNotifications

/// A simple helper that manages local notifications for BusBuddy.
@Observable
final class NotificationManager {

    /// Whether the user has granted notification permission.
    var isAuthorized = false

    /// Request permission to show notifications.
    /// Call this once when the app first opens.
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            Task { @MainActor in
                self.isAuthorized = granted
            }
        }
    }

    /// Send a local notification with a title and body.
    /// It shows up as a banner if the app is in the background,
    /// or in the notification centre.
    func send(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // Deliver almost immediately (1 second delay so the system can process it)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
