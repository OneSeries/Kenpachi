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
        VStack(alignment: .leading, spacing: .spacingS) {
            /// Section title
            Text("cast.crew.title")
                .font(.headlineSmall)
                .foregroundColor(Color.textPrimary)
            
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
            }
        }
    }
}

// MARK: - Cast Member Card
struct CastMemberCard: View {
    /// Cast member to display
    let cast: Cast
    /// Tap callback
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: onTapped) {
            VStack(spacing: .spacingS) {
                /// Profile image
                if let profileURL = cast.fullProfileURL {
                    AsyncImage(url: profileURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        ZStack {
                            Color.surfaceBackground
                            ProgressView()
                                .tint(.primaryBlue)
                        }
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                } else {
                    /// Placeholder
                    ZStack {
                        Color.surfaceBackground
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(Color.textTertiary)
                    }
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                }
                
                /// Name
                Text(cast.name)
                    .font(.captionLarge)
                    .fontWeight(.medium)
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                /// Role
                if let role = cast.displayRole {
                    Text(role)
                        .font(.captionMedium)
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 100)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
