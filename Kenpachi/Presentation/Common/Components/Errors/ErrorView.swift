// ErrorView.swift
// Common error display view
// Shows error message with retry option

import SwiftUI

struct ErrorView: View {
    /// Error message to display
    let message: String
    /// Optional retry action
    var retryAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: .spacingXL - 4) {
            /// Error icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.error)
            
            /// Error title
            Text("error.title")
                .font(.headlineLarge)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            /// Error message
            Text(message)
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingXXL)
            
            /// Retry button
            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: .spacingS) {
                        Image(systemName: "arrow.clockwise")
                        Text("error.try_again.button")
                    }
                    .font(.labelLarge)
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingL)
                    .padding(.vertical, .spacingS)
                    .background(Color.primaryBlue)
                    .cornerRadius(.radiusM + 2)
                }
                .padding(.top, .spacingS)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.spacingM)
    }
}