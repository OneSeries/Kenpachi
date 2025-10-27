// Logger.swift
// Centralized logging utility using OSLog
// Provides structured logging for debugging and monitoring

import Foundation
import OSLog

/// Log level enum for categorizing log messages
enum LogLevel: Int {
    /// Debug level for detailed debugging information
    case debug = 0
    /// Info level for general informational messages
    case info = 1
    /// Warning level for potentially problematic situations
    case warning = 2
    /// Error level for error events
    case error = 3
    /// Critical level for severe error events
    case critical = 4
    
    /// OSLogType equivalent for the log level
    var osLogType: OSLogType {
        switch self {
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .default
        case .error:
            return .error
        case .critical:
            return .fault
        }
    }
    
    /// Emoji prefix for console output
    var emoji: String {
        switch self {
        case .debug:
            return "🔍"
        case .info:
            return "ℹ️"
        case .warning:
            return "⚠️"
        case .error:
            return "❌"
        case .critical:
            return "🔥"
        }
    }
}

/// Application logger using OSLog for system integration
/// Provides centralized logging with different log levels
final class AppLogger {
    /// Shared singleton instance
    static let shared = AppLogger()
    
    /// OSLog logger instance
    private let logger: Logger
    /// Subsystem identifier for logs
    private let subsystem = AppConstants.App.bundleIdentifier
    /// Category for logs
    private let category = "Kenpachi"
    
    /// Minimum log level to output (debug in development, info in production)
    private var minimumLogLevel: LogLevel = .debug
    
    /// Private initializer for singleton
    private init() {
        // Initialize OSLog logger with subsystem and category
        logger = Logger(subsystem: subsystem, category: category)
        
        // Set minimum log level based on build configuration
        #if DEBUG
        minimumLogLevel = .debug
        #else
        minimumLogLevel = .info
        #endif
    }
    
    /// Logs a message with specified level
    /// - Parameters:
    ///   - message: Message to log
    ///   - level: Log level (default: .info)
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func log(
        _ message: String,
        level: LogLevel = .info,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // Check if message should be logged based on minimum level
        guard level.rawValue >= minimumLogLevel.rawValue else { return }
        
        // Extract filename from full path
        let filename = (file as NSString).lastPathComponent
        
        // Format log message with context
        let formattedMessage = "[\(filename):\(line)] \(function) - \(message)"
        
        // Log to OSLog with appropriate type
        logger.log(level: level.osLogType, "\(formattedMessage)")
        
        // Also print to console in debug builds for easier debugging
        #if DEBUG
        print("\(level.emoji) [\(level)] \(formattedMessage)")
        #endif
    }
    
    /// Logs a debug message
    /// - Parameters:
    ///   - message: Debug message
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func debug(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .debug, file: file, function: function, line: line)
    }
    
    /// Logs an info message
    /// - Parameters:
    ///   - message: Info message
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func info(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .info, file: file, function: function, line: line)
    }
    
    /// Logs a warning message
    /// - Parameters:
    ///   - message: Warning message
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func warning(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .warning, file: file, function: function, line: line)
    }
    
    /// Logs an error message
    /// - Parameters:
    ///   - message: Error message
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func error(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .error, file: file, function: function, line: line)
    }
    
    /// Logs a critical message
    /// - Parameters:
    ///   - message: Critical message
    ///   - file: Source file (automatically captured)
    ///   - function: Function name (automatically captured)
    ///   - line: Line number (automatically captured)
    func critical(
        _ message: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(message, level: .critical, file: file, function: function, line: line)
    }
    
    /// Sets the minimum log level
    /// - Parameter level: Minimum log level to output
    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
        log("Minimum log level set to: \(level)", level: .info)
    }
}
