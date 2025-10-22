// NoResultsView.swift
// Empty state view for no search results
// Displays a message when no content matches the search query

import SwiftUI

struct NoResultsView: View {
    /// Search query that returned no results
    let query: String
    
    var body: some View {
        VStack(spacing: .spacingM) {
            /// Icon
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.textSecondary)
            
            /// Title
            Text("no_results.title")
                .font(.headlineLarge)
                .fontWeight(.semibold)
                .foregroundColor(.textPrimary)
            
            /// Message
            Text(String(format: String(localized: "no_results.message"), query))
                .font(.bodyMedium)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingXXL)
            
            /// Suggestion
            Text("no_results.suggestion")
                .font(.captionLarge)
                .foregroundColor(.textSecondary)
                .padding(.top, .spacingS)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.spacingM)
    }
}