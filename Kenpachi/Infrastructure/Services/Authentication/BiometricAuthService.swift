// BiometricAuthService.swift
// Biometric authentication service using Face ID / Touch ID
// Provides secure app access through device biometrics

import Foundation
import LocalAuthentication

/// Biometric authentication service for Face ID and Touch ID
/// Manages biometric authentication and availability checking
@Observable
final class BiometricAuthService {
    /// Shared singleton instance
    static let shared = BiometricAuthService()
    
    /// Whether biometric authentication is available on device
    var isAvailable: Bool = false
    /// Type of biometric authentication available
    var biometricType: BiometricType = .none
    /// Whether biometric auth is enabled in settings
    var isEnabled: Bool = false
    
    /// Local authentication context
    private var context = LAContext()
    
    /// Enum representing biometric types
    enum BiometricType {
        /// No biometric authentication available
        case none
        /// Face ID available
        case faceID
        /// Touch ID available
        case touchID
        
        /// Display name for biometric type
        var displayName: String {
            switch self {
            case .none:
                return "None"
            case .faceID:
                return "Face ID"
            case .touchID:
                return "Touch ID"
            }
        }
        
        /// SF Symbol icon name for biometric type
        var iconName: String {
            switch self {
            case .none:
                return "lock.fill"
            case .faceID:
                return "faceid"
            case .touchID:
                return "touchid"
            }
        }
    }
    
    /// Authentication result enum
    enum AuthResult {
        /// Authentication successful
        case success
        /// Authentication failed with error
        case failure(Error)
        /// Authentication cancelled by user
        case cancelled
    }
    
    /// Private initializer for singleton
    private init() {
        // Load biometric enabled preference from UserDefaults
        isEnabled = UserDefaults.standard.bool(
            forKey: AppConstants.StorageKeys.biometricAuthEnabled
        )
        // Check biometric availability on initialization
        checkAvailability()
    }
    
    /// Checks if biometric authentication is available
    /// Updates isAvailable and biometricType properties
    func checkAvailability() {
        // Create new context for fresh evaluation
        context = LAContext()
        
        // Variable to store evaluation error
        var error: NSError?
        
        // Check if device can evaluate biometric policy
        let canEvaluate = context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &error
        )
        
        // Update availability status
        isAvailable = canEvaluate
        
        // Determine biometric type if available
        if canEvaluate {
            // Check biometric type based on iOS version
            switch context.biometryType {
            case .faceID:
                biometricType = .faceID
            case .touchID:
                biometricType = .touchID
            case .none:
                biometricType = .none
            @unknown default:
                biometricType = .none
            }
            
            // Log biometric availability
            AppLogger.shared.log(
                "Biometric authentication available: \(biometricType.displayName)",
                level: .info
            )
        } else {
            // No biometric available
            biometricType = .none
            
            // Log unavailability reason
            if let error = error {
                AppLogger.shared.log(
                    "Biometric authentication unavailable: \(error.localizedDescription)",
                    level: .warning
                )
            }
        }
    }
    
    /// Authenticates user using biometrics
    /// - Parameter reason: Reason string shown to user
    /// - Returns: Authentication result
    func authenticate(reason: String = "Authenticate to access Kenpachi") async -> AuthResult {
        // Check if biometric auth is enabled in settings
        guard isEnabled else {
            // Log authentication skipped
            AppLogger.shared.log(
                "Biometric authentication skipped (disabled in settings)",
                level: .debug
            )
            return .success
        }
        
        // Check if biometric auth is available
        guard isAvailable else {
            // Log authentication unavailable
            AppLogger.shared.log(
                "Biometric authentication unavailable",
                level: .warning
            )
            return .failure(BiometricError.notAvailable)
        }
        
        // Create new context for authentication
        context = LAContext()
        
        // Set fallback button title
        context.localizedFallbackTitle = "Use Passcode"
        
        // Set cancel button title
        context.localizedCancelTitle = "Cancel"
        
        do {
            // Evaluate biometric policy
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            // Check authentication result
            if success {
                // Log successful authentication
                AppLogger.shared.log(
                    "Biometric authentication successful",
                    level: .info
                )
                return .success
            } else {
                // Log failed authentication
                AppLogger.shared.log(
                    "Biometric authentication failed",
                    level: .warning
                )
                return .failure(BiometricError.authenticationFailed)
            }
        } catch let error as LAError {
            // Handle specific LAError cases
            switch error.code {
            case .userCancel, .appCancel, .systemCancel:
                // User cancelled authentication
                AppLogger.shared.log(
                    "Biometric authentication cancelled",
                    level: .debug
                )
                return .cancelled
                
            case .userFallback:
                // User chose fallback option
                AppLogger.shared.log(
                    "User selected fallback authentication",
                    level: .debug
                )
                return .failure(BiometricError.fallbackSelected)
                
            case .biometryNotAvailable:
                // Biometry not available
                AppLogger.shared.log(
                    "Biometry not available",
                    level: .warning
                )
                return .failure(BiometricError.notAvailable)
                
            case .biometryNotEnrolled:
                // No biometrics enrolled
                AppLogger.shared.log(
                    "No biometrics enrolled",
                    level: .warning
                )
                return .failure(BiometricError.notEnrolled)
                
            case .biometryLockout:
                // Too many failed attempts
                AppLogger.shared.log(
                    "Biometry locked out",
                    level: .warning
                )
                return .failure(BiometricError.lockout)
                
            default:
                // Other authentication error
                AppLogger.shared.log(
                    "Biometric authentication error: \(error.localizedDescription)",
                    level: .error
                )
                return .failure(error)
            }
        } catch {
            // Handle unexpected errors
            AppLogger.shared.log(
                "Unexpected biometric authentication error: \(error.localizedDescription)",
                level: .error
            )
            return .failure(error)
        }
    }
    
    /// Enables biometric authentication
    /// Saves preference to UserDefaults
    func enableBiometricAuth() {
        // Update enabled flag
        isEnabled = true
        // Save to UserDefaults
        UserDefaults.standard.set(
            true,
            forKey: AppConstants.StorageKeys.biometricAuthEnabled
        )
        // Log enablement
        AppLogger.shared.log(
            "Biometric authentication enabled",
            level: .info
        )
    }
    
    /// Disables biometric authentication
    /// Saves preference to UserDefaults
    func disableBiometricAuth() {
        // Update enabled flag
        isEnabled = false
        // Save to UserDefaults
        UserDefaults.standard.set(
            false,
            forKey: AppConstants.StorageKeys.biometricAuthEnabled
        )
        // Log disablement
        AppLogger.shared.log(
            "Biometric authentication disabled",
            level: .info
        )
    }
}

// MARK: - BiometricError
/// Custom errors for biometric authentication
enum BiometricError: LocalizedError {
    /// Biometric authentication not available
    case notAvailable
    /// No biometrics enrolled on device
    case notEnrolled
    /// Authentication failed
    case authenticationFailed
    /// User selected fallback option
    case fallbackSelected
    /// Too many failed attempts (lockout)
    case lockout
    
    /// Error description for user display
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Biometric authentication is not available on this device."
        case .notEnrolled:
            return "No biometrics are enrolled. Please set up Face ID or Touch ID in Settings."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .fallbackSelected:
            return "Fallback authentication selected."
        case .lockout:
            return "Too many failed attempts. Please try again later or use your passcode."
        }
    }
}
