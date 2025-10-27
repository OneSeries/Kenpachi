// Dependencies.swift
// Provides mock implementations for testing and TCA dependency registrations

import ComposableArchitecture
import Foundation

// MARK: - Mock Implementations for Testing

/// Mock UserRepository for testing
final class MockUserRepository {
  func fetchUserProfile() async throws -> Any? { nil }
  func updateUserProfile(_ profile: Any) async throws -> Any { profile }
  func fetchWatchlist() async throws -> Any { () }
  func addToWatchlist(contentId: String) async throws {}
  func removeFromWatchlist(contentId: String) async throws {}
  func isInWatchlist(contentId: String) async throws -> Bool { false }
  func fetchWatchHistory() async throws -> Any { () }
  func updateWatchHistoryEntry(_ entry: Any) async throws {}
  func removeWatchHistoryEntry(id: String) async throws {}
  func clearWatchHistory() async throws {}
  func getUserStatistics() async throws -> (
    watchTime: TimeInterval, contentCount: Int, favoriteGenres: [String]
  ) {
    (0, 0, [])
  }
  func fetchUserPreferences() async throws -> Any { () }
  func updateUserPreferences(_ preferences: Any) async throws {}
  func fetchAppState() async throws -> Any { () }
  func updateAppState(_ state: Any) async throws {}
}

/// Mock ContentRepository for testing
final class MockContentRepository {
  func fetchTrendingContent() async throws -> [Any] { [] }
  func fetchHomeContent() async throws -> [Any] { [] }
  func searchContent(query: String, page: Int) async throws -> Any {
    ()
  }
  func fetchContentDetails(id: String, type: ContentType?) async throws -> Any? { nil }
  func extractStreamingLinks(contentId: String, seasonId: String?, episodeId: String?) async throws
    -> [Any]
  { [] }
}

/// Mock CacheManager for testing
final class MockCacheManager {
  func getCacheSize() async -> Int64 { 0 }
  func clearCache() async -> Int64 { 0 }
}

/// Mock BiometricAuthService for testing
final class MockBiometricAuthService {
  func canUseBiometrics() -> Bool { false }
  func authenticate() async throws -> Bool { false }
}

// MARK: - TCA Dependency Keys

/// UserDefaults dependency key
private enum UserDefaultsKey: DependencyKey {
  static let liveValue = UserDefaults.standard
  static let testValue = UserDefaults.standard
  
  nonisolated(unsafe) static let previewValue = UserDefaults.standard
}

/// UserRepository dependency key
private enum UserRepositoryKey: DependencyKey {
  static let liveValue = MockUserRepository()
  static let testValue = MockUserRepository()
}

/// ContentRepository dependency key
private enum ContentRepositoryKey: DependencyKey {
  static let liveValue = MockContentRepository()
  static let testValue = MockContentRepository()
}

/// CacheManager dependency key
private enum CacheManagerKey: DependencyKey {
  static let liveValue = MockCacheManager()
  static let testValue = MockCacheManager()
}

/// BiometricAuth dependency key
private enum BiometricAuthKey: DependencyKey {
  static let liveValue = MockBiometricAuthService()
  static let testValue = MockBiometricAuthService()
}

// MARK: - DependencyValues Extension

extension DependencyValues {
  /// UserDefaults dependency
  var userDefaults: UserDefaults {
    get { self[UserDefaultsKey.self] }
    set { self[UserDefaultsKey.self] = newValue }
  }

  /// UserRepository dependency
  var userRepository: MockUserRepository {
    get { self[UserRepositoryKey.self] }
    set { self[UserRepositoryKey.self] = newValue }
  }

  /// ContentRepository dependency
  var contentRepository: MockContentRepository {
    get { self[ContentRepositoryKey.self] }
    set { self[ContentRepositoryKey.self] = newValue }
  }

  /// CacheManager dependency
  var cacheManager: MockCacheManager {
    get { self[CacheManagerKey.self] }
    set { self[CacheManagerKey.self] = newValue }
  }

  /// BiometricAuth dependency
  var biometricAuth: MockBiometricAuthService {
    get { self[BiometricAuthKey.self] }
    set { self[BiometricAuthKey.self] = newValue }
  }
}
