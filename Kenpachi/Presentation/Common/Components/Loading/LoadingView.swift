// LoadingView.swift
// Common loading indicator view
// Displays a centered progress indicator with optional message

import SwiftUI

struct LoadingView: View {
    /// Optional loading message
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: .spacingM) {
            /// Progress indicator
            ProgressView()
                .scaleEffect(1.5)
                .tint(.primaryBlue)
            
            /// Loading message
            Text(message)
                .font(.labelMedium)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
