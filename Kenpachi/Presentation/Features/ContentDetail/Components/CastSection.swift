// CastSection.swift
// Component for displaying cast and crew members
// Shows actor profiles with horizontal scrolling

import SwiftUI

struct CastSection: View {
    /// Cast members to display
    let cast: [Cast]
    /// Cast member tap callback
    let onCastTapped: (Cast) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingS + 4) {
            /// Section title (Hotstar style)
            Text("content.cast_crew")
                .font(.headlineSmall)
                .foregroundColor(.textPrimary)
                .padding(.horizontal, .spacingL - 4)
            
            /// Horizontal scrolling cast list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: .spacingM) {
                    ForEach(cast.prefix(15)) { member in
                        CastMemberCard(
                            cast: member,
                            onTapped: { onCastTapped(member) }
                        )
                    }
                }
                .padding(.horizontal, .spacingL - 4)
            }
        }
    }
}

// MARK: - Cast Member Card (Hotstar Style)
struct CastMemberCard: View {
    /// Cast member to display
    let cast: Cast
    /// Tap callback
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: .spacingS) {
                /// Profile image (circular)
                if let profileURL = cast.fullProfileURL {
                    AsyncImage(url: profileURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Color.cardBackground
                            ProgressView()
                                .tint(.textTertiary)
                        }
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                } else {
                    /// Placeholder
                    ZStack {
                        Color.cardBackground
                        Image(systemName: "person.fill")
                            .font(.headlineLarge)
                            .foregroundColor(.textTertiary)
                    }
                    .frame(width: 80, height: 80)
                    .clipShape(Circle())
                }
                
                /// Name
                Text(cast.name)
                    .font(.labelSmall)
                    .foregroundColor(.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                /// Role
                if let role = cast.displayRole {
                    Text(role)
                        .font(.captionLarge)
                        .foregroundColor(.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 80)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
