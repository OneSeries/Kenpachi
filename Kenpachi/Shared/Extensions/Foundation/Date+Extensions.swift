// Date+Extensions.swift
// Date extensions for formatting and manipulation
// Provides utility methods for common date operations

import Foundation

extension Date {
    
    // MARK: - Formatting
    /// Formats date as "MMM dd, yyyy" (e.g., "Jan 15, 2024")
    var formatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    /// Formats date as "yyyy" (e.g., "2024")
    var year: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: self)
    }
    
    /// Formats date as "MMM yyyy" (e.g., "Jan 2024")
    var monthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: self)
    }
    
    /// Formats date as relative time (e.g., "2 hours ago", "Yesterday")
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - Comparison
    /// Checks if date is today
    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }
    
    /// Checks if date is yesterday
    var isYesterday: Bool {
        return Calendar.current.isDateInYesterday(self)
    }
    
    /// Checks if date is in the past
    var isPast: Bool {
        return self < Date()
    }
    
    /// Checks if date is in the future
    var isFuture: Bool {
        return self > Date()
    }
    
    // MARK: - Manipulation
    /// Adds specified number of days to date
    /// - Parameter days: Number of days to add
    /// - Returns: New date with days added
    func adding(days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }
    
    /// Adds specified number of months to date
    /// - Parameter months: Number of months to add
    /// - Returns: New date with months added
    func adding(months: Int) -> Date {
        return Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
    
    /// Adds specified number of years to date
    /// - Parameter years: Number of years to add
    /// - Returns: New date with years added
    func adding(years: Int) -> Date {
        return Calendar.current.date(byAdding: .year, value: years, to: self) ?? self
    }
    
    /// Returns start of day for the date
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    /// Returns end of day for the date
    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }
}
