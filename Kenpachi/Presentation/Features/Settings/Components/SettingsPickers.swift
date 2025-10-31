// SettingsPickers.swift
// Picker views for settings options
// Provides selection UI for various settings

import SwiftUI

// MARK: - Theme Picker
struct ThemePicker: View {
  @Binding var selection: ThemeMode

  var body: some View {
    List {
      ForEach(ThemeMode.allCases, id: \.self) { theme in
        Button {
          selection = theme
        } label: {
          HStack {
            Image(systemName: iconForTheme(theme))
              .font(.title3)
              .foregroundColor(.primaryBlue)
              .frame(width: 28)

            Text(theme.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == theme {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.general.theme")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func iconForTheme(_ theme: ThemeMode) -> String {
    switch theme {
    case .light: return "sun.max.fill"
    case .dark: return "moon.fill"
    case .system: return "circle.lefthalf.filled"
    }
  }
}

// MARK: - Accent Color Picker
struct AccentColorPicker: View {
  @Binding var selection: AccentColorOption

  var body: some View {
    List {
      ForEach(AccentColorOption.allCases, id: \.self) { color in
        Button {
          selection = color
        } label: {
          HStack {
            Circle()
              .fill(colorForOption(color))
              .frame(width: 28, height: 28)

            Text(color.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == color {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.general.accent_color")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func colorForOption(_ option: AccentColorOption) -> Color {
    switch option {
    case .blue: return .blue
    case .purple: return .purple
    case .pink: return .pink
    case .red: return .red
    case .orange: return .orange
    case .yellow: return .yellow
    case .green: return .green
    case .teal: return .teal
    }
  }
}

// MARK: - Auto Lock Picker
struct AutoLockPicker: View {
  @Binding var selection: AutoLockTimeout

  var body: some View {
    List {
      ForEach(AutoLockTimeout.allCases, id: \.self) { timeout in
        Button {
          selection = timeout
        } label: {
          HStack {
            Text(timeout.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == timeout {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.security.auto_lock")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Scraper Source Picker
struct ScraperSourcePicker: View {
  @Binding var selection: ScraperSource

  var body: some View {
    List {
      ForEach(ScraperSource.allCases, id: \.self) { source in
        Button {
          selection = source
        } label: {
          HStack {
            Image(systemName: "server.rack")
              .font(.title3)
              .foregroundColor(.primaryBlue)
              .frame(width: 28)

            VStack(alignment: .leading, spacing: .spacingXS) {
              Text(source.displayName)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

              Text(descriptionForSource(source))
                .font(.captionLarge)
                .foregroundColor(.textSecondary)
            }

            Spacer()

            if selection == source {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.content.scraper_source")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func descriptionForSource(_ source: ScraperSource) -> String {
    switch source {
    case .FlixHQ: return "High quality streams, reliable"
    case .Movies111: return "Fast streaming, HD quality"
    case .VidSrc: return "Fast streaming, multiple servers"
    case .VidRock: return "Encrypted streams, secure playback"
    case .VidFast: return "Fast encrypted streams, HD quality"
    case .VidNest: return "Multiple servers, adaptive quality"
    case .AnimeKai: return "Anime focused, high quality"
    case .GogoAnime: return "Popular anime source"
    case .HiAnime: return "Premium anime streaming"
    }
  }
}

// MARK: - Language Picker
struct LanguagePicker: View {
  @Binding var selection: ContentLanguage

  var body: some View {
    List {
      ForEach(ContentLanguage.allCases, id: \.self) { language in
        Button {
          selection = language
        } label: {
          HStack {
            Text(language.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == language {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.content.language")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Quality Picker
struct QualityPicker: View {
  @Binding var selection: VideoQuality

  var body: some View {
    List {
      ForEach(VideoQuality.allCases, id: \.self) { quality in
        Button {
          selection = quality
        } label: {
          HStack {
            VStack(alignment: .leading, spacing: .spacingXS) {
              Text(quality.displayName)
                .font(.bodyMedium)
                .foregroundColor(.textPrimary)

              if quality == .auto {
                Text("settings.quality.auto_description")
                  .font(.captionLarge)
                  .foregroundColor(.textSecondary)
              }
            }

            Spacer()

            if selection == quality {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.player.default_quality")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Subtitle Language Picker
struct SubtitleLanguagePicker: View {
  @Binding var selection: SubtitleLanguage

  var body: some View {
    List {
      ForEach(SubtitleLanguage.allCases, id: \.self) { language in
        Button {
          selection = language
        } label: {
          HStack {
            Text(language.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == language {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.player.subtitle_language")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Audio Language Picker
struct AudioLanguagePicker: View {
  @Binding var selection: AudioLanguage

  var body: some View {
    List {
      ForEach(AudioLanguage.allCases, id: \.self) { language in
        Button {
          selection = language
        } label: {
          HStack {
            Text(language.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == language {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.player.audio_language")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Playback Speed Picker
struct PlaybackSpeedPicker: View {
  @Binding var selection: PlaybackSpeed

  var body: some View {
    List {
      ForEach(PlaybackSpeed.allCases, id: \.self) { speed in
        Button {
          selection = speed
        } label: {
          HStack {
            Text(speed.displayName)
              .font(.bodyMedium)
              .foregroundColor(.textPrimary)

            Spacer()

            if selection == speed {
              Image(systemName: "checkmark")
                .font(.bodyMedium)
                .foregroundColor(.primaryBlue)
            }
          }
          .padding(.vertical, .spacingXS)
        }
      }
    }
    .navigationTitle("settings.player.playback_speed")
    .navigationBarTitleDisplayMode(.inline)
  }
}
