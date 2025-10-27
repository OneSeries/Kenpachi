// NotificationService.swift
// Push notification service using APNs
// Manages notification registration, delivery, and user preferences

import Foundation
import UserNotifications
import UIKit

/// Notification service for managing push notifications
/// Handles APNs registration and notification preferences
@Observable
final class NotificationService: NSObject {
    /// Shared singleton instance
    static let shared = NotificationService()
    
    /// Current authorization status for notifications
    var authorizationStatus: UNAuthorizationStatus = .notDetermined
    /// Device token for APNs (hex string)
    var deviceToken: String?
    /// Whether notifications are enabled
    var notificationsEnabled: Bool = false
    
    /// Notification center instance
    private let notificationCenter = UNUserNotificationCenter.current()
    
    /// Private initializer for singleton
    private override init() {
        super.init()
        // Set self as notification center delegate
        notificationCenter.delegate = self
        // Check current authorization status
        checkAuthorizationStatus()
    }
    
    /// Requests notification authorization from user
    /// Prompts user with permission dialog
    func requestAuthorization() {
        // Define requested notification options
        let options: UNAuthorizationOptions = [.alert, .badge, .sound, .provisional]
        
        // Request authorization from user
        notificationCenter.requestAuthorization(options: options) { [weak self] granted, error in
            // Update authorization status on main thread
            DispatchQueue.main.async {
                // Update enabled flag based on grant status
                self?.notificationsEnabled = granted
                
                // Log authorization result
                if let error = error {
                    AppLogger.shared.log(
                        "Notification authorization error: \(error.localizedDescription)",
                        level: .error
                    )
                } else {
                    AppLogger.shared.log(
                        "Notification authorization: \(granted ? "granted" : "denied")",
                        level: .info
                    )
                }
                
                // Check updated authorization status
                self?.checkAuthorizationStatus()
            }
        }
    }
    
    /// Registers for remote notifications with APNs
    /// Must be called after authorization is granted
    func registerForRemoteNotifications() {
        // Register on main thread as required by UIApplication
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Checks current notification authorization status
    /// Updates authorizationStatus property
    func checkAuthorizationStatus() {
        // Get notification settings asynchronously
        notificationCenter.getNotificationSettings { [weak self] settings in
            // Update status on main thread
            DispatchQueue.main.async {
                // Store authorization status
                self?.authorizationStatus = settings.authorizationStatus
                // Update enabled flag
                self?.notificationsEnabled = settings.authorizationStatus == .authorized
                
                // Log current status
                AppLogger.shared.log(
                    "Notification authorization status: \(settings.authorizationStatus.rawValue)",
                    level: .debug
                )
            }
        }
    }
    
    /// Handles successful APNs registration
    /// - Parameter deviceToken: Device token data from APNs
    func didRegisterForRemoteNotifications(withDeviceToken deviceToken: Data) {
        // Convert device token to hex string
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        // Store device token
        self.deviceToken = tokenString
        
        // Log successful registration
        AppLogger.shared.log(
            "Registered for remote notifications. Token: \(tokenString)",
            level: .info
        )
        
        // Send device token to backend server
        sendDeviceTokenToServer(tokenString)
    }
    
    /// Handles APNs registration failure
    /// - Parameter error: Registration error
    func didFailToRegisterForRemoteNotifications(withError error: Error) {
        // Log registration failure
        AppLogger.shared.log(
            "Failed to register for remote notifications: \(error.localizedDescription)",
            level: .error
        )
    }
    
    /// Sends device token to backend server
    /// - Parameter token: Device token hex string
    private func sendDeviceTokenToServer(_ token: String) {
        // TODO: Implement backend API call to register device token
        // This would typically send the token to your backend server
        // for storing and sending push notifications
        
        // Log token ready for backend
        AppLogger.shared.log(
            "Device token ready for backend registration",
            level: .debug
        )
    }
    
    /// Schedules a local notification
    /// - Parameters:
    ///   - title: Notification title
    ///   - body: Notification body text
    ///   - timeInterval: Time interval before delivery
    ///   - identifier: Unique notification identifier
    func scheduleLocalNotification(
        title: String,
        body: String,
        timeInterval: TimeInterval,
        identifier: String
    ) {
        // Create notification content
        let content = UNMutableNotificationContent()
        // Set notification title
        content.title = title
        // Set notification body
        content.body = body
        // Set notification sound
        content.sound = .default
        // Set badge number
        content.badge = 1
        
        // Create time interval trigger
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        // Create notification request
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )
        
        // Add notification request to center
        notificationCenter.add(request) { error in
            if let error = error {
                // Log scheduling error
                AppLogger.shared.log(
                    "Failed to schedule notification: \(error.localizedDescription)",
                    level: .error
                )
            } else {
                // Log successful scheduling
                AppLogger.shared.log(
                    "Scheduled notification: \(identifier)",
                    level: .debug
                )
            }
        }
    }
    
    /// Removes pending notifications by identifier
    /// - Parameter identifiers: Array of notification identifiers to remove
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        // Remove pending notification requests
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
        
        // Log removal
        AppLogger.shared.log(
            "Removed pending notifications: \(identifiers.joined(separator: ", "))",
            level: .debug
        )
    }
    
    /// Removes all pending notifications
    func removeAllPendingNotifications() {
        // Remove all pending notification requests
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Log removal
        AppLogger.shared.log("Removed all pending notifications", level: .debug)
    }
    
    /// Clears app badge number
    func clearBadge() {
        // Clear badge on main thread
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationService: UNUserNotificationCenterDelegate {
    /// Called when notification is received while app is in foreground
    /// - Parameters:
    ///   - center: Notification center
    ///   - notification: Received notification
    ///   - completionHandler: Completion handler with presentation options
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Log notification received in foreground
        AppLogger.shared.log(
            "Notification received in foreground: \(notification.request.identifier)",
            level: .debug
        )
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    /// Called when user interacts with notification
    /// - Parameters:
    ///   - center: Notification center
    ///   - response: User's response to notification
    ///   - completionHandler: Completion handler
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Get notification user info
        let userInfo = response.notification.request.content.userInfo
        
        // Log notification interaction
        AppLogger.shared.log(
            "User interacted with notification: \(response.notification.request.identifier)",
            level: .debug
        )
        
        // Handle notification action based on user info
        handleNotificationAction(userInfo: userInfo)
        
        // Call completion handler
        completionHandler()
    }
    
    /// Handles notification action based on payload
    /// - Parameter userInfo: Notification user info dictionary
    private func handleNotificationAction(userInfo: [AnyHashable: Any]) {
        // Extract content ID from notification payload
        if let contentId = userInfo["contentId"] as? String,
           let contentType = userInfo["contentType"] as? String {
            // Navigate to content detail screen
            // TODO: Implement deep link navigation
            AppLogger.shared.log(
                "Navigate to content: \(contentId) type: \(contentType)",
                level: .debug
            )
        }
    }
}
