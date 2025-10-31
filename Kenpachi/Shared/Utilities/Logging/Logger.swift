// Logger.swift
// Centralized logging utility for the application
// Provides structured logging with different severity levels

import Foundation
import OSLog

/// Log severity levels
enum LogLevel: String {
  /// Debug information for development
  case debug = "DEBUG"
  /// General information
  case info = "INFO"
  /// Warning messages
  case warning = "WARNING"
  /// Error messages
  case error = "ERROR"
  /// Critical failures
  case critical = "CRITICAL"

  /// OSLog type mapping
  var osLogType: OSLogType {
    switch self {
    case .debug: return .debug
    case .info: return .info
    case .warning: return .default
    case .error: return .error
    case .critical: return .fault
    }
  }
}

/// Centralized logger for the application
final class AppLogger {
  /// Shared singleton instance
  static let shared = AppLogger()

  /// OSLog instance for system integration
  private let osLog: OSLog

  /// Whether logging is enabled
  private var isEnabled: Bool = true

  /// Private initializer for singleton
  private init() {
    // Create OSLog with app bundle identifier
    self.osLog = OSLog(
      subsystem: AppConstants.App.bundleIdentifier,
      category: "Application"
    )
  }

  /// Logs a message with the specified level
  /// - Parameters:
  ///   - message: The message to log
  ///   - level: The severity level of the log
  ///   - file: The file where the log was called (auto-filled)
  ///   - function: The function where the log was called (auto-filled)
  ///   - line: The line number where the log was called (auto-filled)
  func log(
    _ message: String,
    level: LogLevel = .info,
    file: String = #file,
    function: String = #function,
    line: Int = #line
  ) {
    guard isEnabled else { return }

    // Extract filename from full path
    let filename = (file as NSString).lastPathComponent

    // Format log message
    let formattedMessage = "[\(level.rawValue)] [\(filename):\(line)] \(function) - \(message)"

    // Log to OSLog
    os_log("%{public}@", log: osLog, type: level.osLogType, formattedMessage)

    // In debug builds, also print to console
    #if DEBUG
      print(formattedMessage)
    #endif
  }

  /// Logs a debug message
  /// - Parameter message: The message to log
  func debug(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
  ) {
    log(message, level: .debug, file: file, function: function, line: line)
  }

  /// Logs an info message
  /// - Parameter message: The message to log
  func info(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
  ) {
    log(message, level: .info, file: file, function: function, line: line)
  }

  /// Logs a warning message
  /// - Parameter message: The message to log
  func warning(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
  ) {
    log(message, level: .warning, file: file, function: function, line: line)
  }

  /// Logs an error message
  /// - Parameter message: The message to log
  func error(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
  ) {
    log(message, level: .error, file: file, function: function, line: line)
  }

  /// Logs a critical message
  /// - Parameter message: The message to log
  func critical(
    _ message: String, file: String = #file, function: String = #function, line: Int = #line
  ) {
    log(message, level: .critical, file: file, function: function, line: line)
  }

  /// Enables or disables logging
  /// - Parameter enabled: Whether logging should be enabled
  func setEnabled(_ enabled: Bool) {
    isEnabled = enabled
  }
}
