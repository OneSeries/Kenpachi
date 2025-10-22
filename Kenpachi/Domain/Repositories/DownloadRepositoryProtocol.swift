// DownloadRepositoryProtocol.swift
// Protocol defining download repository interface
// Abstracts download data access and management

import Foundation

/// Protocol for download repository operations
protocol DownloadRepositoryProtocol {
  /// Fetch all downloads
  func fetchDownloads() async throws -> [Download]
  
  /// Fetch download by ID
  func fetchDownload(id: String) async throws -> Download?
  
  /// Create new download
  func createDownload(_ download: Download) async throws -> Download
  
  /// Update existing download
  func updateDownload(_ download: Download) async throws -> Download
  
  /// Delete download
  func deleteDownload(id: String) async throws
  
  /// Start download
  func startDownload(id: String) async throws
  
  /// Pause download
  func pauseDownload(id: String) async throws
  
  /// Resume download
  func resumeDownload(id: String) async throws
  
  /// Cancel download
  func cancelDownload(id: String) async throws
  
  /// Get storage info
  func getStorageInfo() async throws -> (used: Int64, available: Int64)
  
  /// Clear completed downloads
  func clearCompletedDownloads() async throws
}
