// NotificationConstants.swift
// Constants for push notifications and local notifications
// Defines notification categories, identifiers, and actions

import Foundation

/// Enum containing all notification-related constants
enum NotificationConstants {
    
    // MARK: - Notification Categories
    /// Notification category identifiers
    enum Category {
        /// Category for new content availability notifications
        static let newContent = "NEW_CONTENT"
        /// Category for download completion notifications
        static let downloadComplete = "DOWNLOAD_COMPLETE"
        /// Category for recommendation notifications
        static let recommendation = "RECOMMENDATION"
        /// Category for watchlist updates
        static let watchlistUpdate = "WATCHLIST_UPDATE"
        /// Category for new episode releases
        static let newEpisode = "NEW_EPISODE"
    }
    
    // MARK: - Notification Actions
    /// Notification action identifiers
    enum Action {
        /// Action to watch content immediately
        static let watchNow = "WATCH_NOW"
        /// Action to add to watchlist
        static let addToWatchlist = "ADD_TO_WATCHLIST"
        /// Action to dismiss notification
        static let dismiss = "DISMISS"
        /// Action to view downloads
        static let viewDownloads = "VIEW_DOWNLOADS"
    }
    
    // MARK: - Notification Identifiers
    /// Unique identifiers for different notification types
    enum Identifier {
        /// Identifier for new content notifications
        static let newContent = "com.kenpachi.notification.newContent"
        /// Identifier for download complete notifications
        static let downloadComplete = "com.kenpachi.notification.downloadComplete"
        /// Identifier for recommendation notifications
        static let recommendation = "com.kenpachi.notification.recommendation"
        /// Identifier for new episode notifications
        static let newEpisode = "com.kenpachi.notification.newEpisode"
    }
    
    // MARK: - Notification User Info Keys
    /// Keys for notification payload data
    enum UserInfoKey {
        /// Key for content ID in notification payload
        static let contentId = "contentId"
        /// Key for content type in notification payload
        static let contentType = "contentType"
        /// Key for content title in notification payload
        static let contentTitle = "contentTitle"
        /// Key for deep link URL in notification payload
        static let deepLink = "deepLink"
    }
}
