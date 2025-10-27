// SettingsView.swift
// Settings screen UI
// Comprehensive settings similar to Disney Plus Hotstar

import ComposableArchitecture
import SwiftUI

struct SettingsView: View {
  /// TCA store for Settings feature
  @Bindable var store: StoreOf<SettingsFeature>
  /// SwiftUI environment dismiss action
  @SwiftUI.Environment(\.dismiss) var dismiss: DismissAction

  var body: some View {
    NavigationStack {
      contentView
        .navigationTitle("settings.title")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("settings.done") {
              dismiss()
            }
          }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
          store.send(.onAppear)
        }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    ZStack {
      Color.appBackground.ignoresSafeArea()

      if store.isLoadingSettings {
        LoadingView()
      } else {
        ScrollView {
          VStack(spacing: .spacingL) {
            /// General section
            SettingsSection(title: "settings.general.title") {
              SettingsRow(
                icon: "paintbrush.fill",
                title: "settings.general.theme",
                value: store.selectedTheme.displayName
              ) {
                ThemePicker(selection: $store.selectedTheme.sending(\.themeChanged))
              }

              SettingsRow(
                icon: "paintpalette.fill",
                title: "settings.general.accent_color",
                value: store.accentColor.displayName
              ) {
                AccentColorPicker(selection: $store.accentColor.sending(\.accentColorChanged))
              }
            }

            /// Security section
            SettingsSection(title: "settings.security.title") {
              SettingsToggleRow(
                icon: "faceid",
                title: "settings.security.biometric_auth",
                subtitle: "settings.security.biometric_auth_subtitle",
                isOn: $store.biometricAuthEnabled.sending(\.biometricAuthToggled)
              )

              if store.biometricAuthEnabled {
                SettingsRow(
                  icon: "lock.fill",
                  title: "settings.security.auto_lock",
                  value: store.autoLockTimeout.displayName
                ) {
                  AutoLockPicker(
                    selection: $store.autoLockTimeout.sending(\.autoLockTimeoutChanged))
                }
              }
            }

            /// Content preferences section
            SettingsSection(title: "settings.content.title") {
              SettingsRow(
                icon: "server.rack",
                title: "settings.content.scraper_source",
                subtitle: "settings.content.scraper_source_subtitle",
                value: store.defaultScraperSource.displayName
              ) {
                ScraperSourcePicker(
                  selection: $store.defaultScraperSource.sending(\.scraperSourceChanged))
              }

              SettingsRow(
                icon: "globe",
                title: "settings.content.language",
                value: store.preferredLanguage.displayName
              ) {
                LanguagePicker(
                  selection: $store.preferredLanguage.sending(\.preferredLanguageChanged))
              }

              SettingsToggleRow(
                icon: "18.circle.fill",
                title: "settings.content.adult_content",
                subtitle: "settings.content.adult_content_subtitle",
                isOn: $store.showAdultContent.sending(\.showAdultContentToggled)
              )
            }

            /// Parental Controls section
            SettingsSection(title: "settings.parental_controls.title") {
              SettingsToggleRow(
                icon: "person.2.fill",
                title: "settings.parental_controls.enable",
                isOn: $store.parentalControlsEnabled.sending(\.parentalControlsToggled)
              )

              if store.parentalControlsEnabled {
                SettingsRow(
                  icon: "shield.lefthalf.filled",
                  title: "settings.parental_controls.allowed_rating",
                  value: store.allowedContentRating.displayName
                ) {
                  ContentRatingPicker(
                    selection: $store.allowedContentRating.sending(\.allowedContentRatingChanged))
                }
              }
            }

            /// Player settings section
            SettingsSection(title: "settings.player.title") {
              SettingsToggleRow(
                icon: "play.circle.fill",
                title: "settings.player.autoplay",
                subtitle: "settings.player.autoplay_subtitle",
                isOn: $store.autoPlayEnabled.sending(\.autoPlayToggled)
              )

              SettingsToggleRow(
                icon: "film.fill",
                title: "settings.player.autoplay_trailers",
                subtitle: "settings.player.autoplay_trailers_subtitle",
                isOn: $store.autoPlayTrailers.sending(\.autoPlayTrailersToggled)
              )

              SettingsRow(
                icon: "video.fill",
                title: "settings.player.default_quality",
                value: store.defaultQuality.displayName
              ) {
                QualityPicker(selection: $store.defaultQuality.sending(\.defaultQualityChanged))
              }

              SettingsToggleRow(
                icon: "captions.bubble.fill",
                title: "settings.player.subtitles",
                isOn: $store.subtitlesEnabled.sending(\.subtitlesToggled)
              )

              if store.subtitlesEnabled {
                SettingsRow(
                  icon: "text.bubble.fill",
                  title: "settings.player.subtitle_language",
                  value: store.preferredSubtitleLanguage.displayName
                ) {
                  SubtitleLanguagePicker(
                    selection: $store.preferredSubtitleLanguage.sending(\.subtitleLanguageChanged)
                  )
                }
              }

              SettingsRow(
                icon: "speaker.wave.2.fill",
                title: "settings.player.audio_language",
                value: store.preferredAudioLanguage.displayName
              ) {
                AudioLanguagePicker(
                  selection: $store.preferredAudioLanguage.sending(\.audioLanguageChanged))
              }

              SettingsRow(
                icon: "speedometer",
                title: "settings.player.playback_speed",
                value: store.playbackSpeed.displayName
              ) {
                PlaybackSpeedPicker(
                  selection: $store.playbackSpeed.sending(\.playbackSpeedChanged))
              }
            }

            /// Download settings section
            SettingsSection(title: "settings.downloads.title") {
              SettingsRow(
                icon: "arrow.down.circle.fill",
                title: "settings.downloads.quality",
                value: store.downloadQuality.displayName
              ) {
                QualityPicker(
                  selection: $store.downloadQuality.sending(\.downloadQualityChanged))
              }

              SettingsToggleRow(
                icon: "antenna.radiowaves.left.and.right",
                title: "settings.downloads.cellular",
                subtitle: "settings.downloads.cellular_subtitle",
                isOn: $store.downloadOverCellular.sending(\.downloadOverCellularToggled)
              )

              SettingsToggleRow(
                icon: "trash.fill",
                title: "settings.downloads.auto_delete",
                subtitle: "settings.downloads.auto_delete_subtitle",
                isOn: $store.autoDeleteWatchedDownloads.sending(\.autoDeleteWatchedToggled)
              )
            }

            /// Notifications section
            SettingsSection(title: "settings.notifications.title") {
              SettingsToggleRow(
                icon: "bell.fill",
                title: "settings.notifications.push",
                subtitle: "settings.notifications.push_subtitle",
                isOn: $store.pushNotificationsEnabled.sending(\.pushNotificationsToggled)
              )

              if store.pushNotificationsEnabled {
                SettingsToggleRow(
                  icon: "sparkles",
                  title: "settings.notifications.new_content",
                  isOn: $store.newContentNotifications.sending(\.newContentNotificationsToggled)
                )

                SettingsToggleRow(
                  icon: "checkmark.circle.fill",
                  title: "settings.notifications.downloads",
                  isOn: $store.downloadCompleteNotifications.sending(
                    \.downloadNotificationsToggled)
                )

                SettingsToggleRow(
                  icon: "star.fill",
                  title: "settings.notifications.recommendations",
                  isOn: $store.recommendationNotifications.sending(
                    \.recommendationNotificationsToggled)
                )
              }
            }

            /// Streaming section
            SettingsSection(title: "settings.streaming.title") {
              SettingsToggleRow(
                icon: "airplayvideo",
                title: "settings.streaming.airplay",
                subtitle: "settings.streaming.airplay_subtitle",
                isOn: $store.airPlayEnabled.sending(\.airPlayToggled)
              )

              SettingsToggleRow(
                icon: "tv.fill",
                title: "settings.streaming.chromecast",
                subtitle: "settings.streaming.chromecast_subtitle",
                isOn: $store.chromecastEnabled.sending(\.chromecastToggled)
              )

              SettingsToggleRow(
                icon: "pip.fill",
                title: "settings.streaming.pip",
                subtitle: "settings.streaming.pip_subtitle",
                isOn: $store.pipEnabled.sending(\.pipToggled)
              )
            }

            /// Privacy section
            SettingsSection(title: "settings.privacy.title") {
              SettingsToggleRow(
                icon: "chart.bar.fill",
                title: "settings.privacy.analytics",
                subtitle: "settings.privacy.analytics_subtitle",
                isOn: $store.analyticsEnabled.sending(\.analyticsToggled)
              )

              SettingsToggleRow(
                icon: "exclamationmark.triangle.fill",
                title: "settings.privacy.crash_reporting",
                subtitle: "settings.privacy.crash_reporting_subtitle",
                isOn: $store.crashReportingEnabled.sending(\.crashReportingToggled)
              )

              SettingsToggleRow(
                icon: "sparkles.rectangle.stack.fill",
                title: "settings.privacy.personalized",
                subtitle: "settings.privacy.personalized_subtitle",
                isOn: $store.personalizedRecommendations.sending(
                  \.personalizedRecommendationsToggled)
              )

              SettingsToggleRow(
                icon: "clock.arrow.circlepath",
                title: "settings.privacy.search_history",
                subtitle: "settings.privacy.search_history_subtitle",
                isOn: $store.searchHistoryEnabled.sending(\.searchHistoryToggled)
              )

              if store.searchHistoryEnabled {
                SettingsButtonRow(
                  icon: "trash.fill",
                  title: "settings.privacy.clear_search_history",
                  style: .destructive
                ) {
                  store.send(.clearSearchHistoryTapped)
                }
              }
            }

            /// Storage section
            SettingsSection(title: "settings.storage.title") {
              StorageInfoRow(
                icon: "internaldrive.fill",
                title: "settings.storage.total_used",
                size: store.totalStorageUsed
              )

              StorageInfoRow(
                icon: "square.stack.3d.up.fill",
                title: "settings.storage.cache",
                size: store.cacheSize
              )

              StorageInfoRow(
                icon: "arrow.down.circle.fill",
                title: "settings.storage.downloads",
                size: store.downloadsSize
              )

              SettingsButtonRow(
                icon: "trash.fill",
                title: "settings.storage.clear_cache",
                style: .destructive,
                isLoading: store.isClearingCache
              ) {
                store.send(.clearCacheTapped)
              }
            }

            /// About section
            SettingsSection(title: "settings.about.title") {
              SettingsInfoRow(
                icon: "info.circle.fill",
                title: "settings.about.version",
                value: "\(store.appVersion) (\(store.buildNumber))"
              )

              SettingsButtonRow(
                icon: "questionmark.circle.fill",
                title: "settings.about.help"
              ) {
                store.send(.helpTapped)
              }

              SettingsButtonRow(
                icon: "doc.text.fill",
                title: "settings.about.privacy_policy"
              ) {
                store.send(.privacyPolicyTapped)
              }

              SettingsButtonRow(
                icon: "doc.plaintext.fill",
                title: "settings.about.terms"
              ) {
                store.send(.termsOfServiceTapped)
              }
            }

            /// Logout button
            Button {
              store.send(.logoutTapped)
            } label: {
              HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("settings.logout")
              }
              .font(.bodyMedium)
              .foregroundColor(.error)
              .frame(maxWidth: .infinity)
              .padding(.spacingM)
              .background(Color.cardBackground)
              .cornerRadius(.radiusM)
            }
            .padding(.horizontal, .spacingM)
            .padding(.vertical, .spacingM)
          }
        }
      }
    }
  }
}

// MARK: - Settings Section
struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: .spacingS) {
      Text(LocalizedStringKey(title))
        .font(.labelLarge)
        .foregroundColor(.textSecondary)
        .padding(.horizontal, .spacingM)

      VStack(spacing: 1) {
        content()
      }
      .background(Color.cardBackground)
      .cornerRadius(.radiusM)
      .padding(.horizontal, .spacingM)
    }
  }
}

// MARK: - Settings Info Row (non-navigable)
struct SettingsInfoRow: View {
  let icon: String
  let title: String
  var subtitle: String?
  var value: String?

  var body: some View {
    HStack(spacing: .spacingM) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(.primaryBlue)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: .spacingXS) {
        Text(LocalizedStringKey(title))
          .font(.bodyMedium)
          .foregroundColor(.textPrimary)

        if let subtitle = subtitle {
          Text(LocalizedStringKey(subtitle))
            .font(.captionLarge)
            .foregroundColor(.textSecondary)
        }
      }

      Spacer()

      if let value = value {
        Text(value)
          .font(.bodySmall)
          .foregroundColor(.textSecondary)
      }
    }
    .padding(.spacingM)
  }
}

// MARK: - Settings Row (navigable)
struct SettingsRow<Destination: View>: View {
  let icon: String
  let title: String
  var subtitle: String?
  var value: String?
  @ViewBuilder var destination: () -> Destination

  var body: some View {
    NavigationLink {
      destination()
    } label: {
      HStack(spacing: .spacingM) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(.primaryBlue)
          .frame(width: 28)

        VStack(alignment: .leading, spacing: .spacingXS) {
          Text(LocalizedStringKey(title))
            .font(.bodyMedium)
            .foregroundColor(.textPrimary)

          if let subtitle = subtitle {
            Text(LocalizedStringKey(subtitle))
              .font(.captionLarge)
              .foregroundColor(.textSecondary)
          }
        }

        Spacer()

        if let value = value {
          Text(value)
            .font(.bodySmall)
            .foregroundColor(.textSecondary)
        }

        Image(systemName: "chevron.right")
          .font(.captionLarge)
          .foregroundColor(.textTertiary)
      }
      .padding(.spacingM)
    }
  }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
  let icon: String
  let title: String
  var subtitle: String?
  @Binding var isOn: Bool

  var body: some View {
    HStack(spacing: .spacingM) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(.primaryBlue)
        .frame(width: 28)

      VStack(alignment: .leading, spacing: .spacingXS) {
        Text(LocalizedStringKey(title))
          .font(.bodyMedium)
          .foregroundColor(.textPrimary)

        if let subtitle = subtitle {
          Text(LocalizedStringKey(subtitle))
            .font(.captionLarge)
            .foregroundColor(.textSecondary)
        }
      }

      Spacer()

      Toggle("", isOn: $isOn)
        .labelsHidden()
    }
    .padding(.spacingM)
  }
}

// MARK: - Settings Button Row
struct SettingsButtonRow: View {
  let icon: String
  let title: String
  var style: ButtonStyle = .normal
  var isLoading: Bool = false
  let action: () -> Void

  enum ButtonStyle {
    case normal
    case destructive
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: .spacingM) {
        Image(systemName: icon)
          .font(.title3)
          .foregroundColor(style == .destructive ? .error : .primaryBlue)
          .frame(width: 28)

        Text(LocalizedStringKey(title))
          .font(.bodyMedium)
          .foregroundColor(style == .destructive ? .error : .textPrimary)

        Spacer()

        if isLoading {
          ProgressView()
            .tint(.textSecondary)
        } else {
          Image(systemName: "chevron.right")
            .font(.captionLarge)
            .foregroundColor(.textTertiary)
        }
      }
      .padding(.spacingM)
    }
    .disabled(isLoading)
  }
}

// MARK: - Storage Info Row
struct StorageInfoRow: View {
  let icon: String
  let title: String
  let size: Int64

  var body: some View {
    HStack(spacing: .spacingM) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundColor(.primaryBlue)
        .frame(width: 28)

      Text(LocalizedStringKey(title))
        .font(.bodyMedium)
        .foregroundColor(.textPrimary)

      Spacer()

      Text(formatBytes(size))
        .font(.bodySmall)
        .foregroundColor(.textSecondary)
    }
    .padding(.spacingM)
  }

  private func formatBytes(_ bytes: Int64) -> String {
    let formatter = ByteCountFormatter()
    formatter.countStyle = .file
    return formatter.string(fromByteCount: bytes)
  }
}

// MARK: - Display Name Extensions
extension ThemeMode {
  var displayName: String {
    switch self {
    case .light: return "Light"
    case .dark: return "Dark"
    case .system: return "System"
    }
  }
}

extension AccentColorOption {
  var displayName: String {
    rawValue.capitalized
  }
}

extension AutoLockTimeout {
  var displayName: String {
    switch self {
    case .oneMinute: return "1 Minute"
    case .fiveMinutes: return "5 Minutes"
    case .tenMinutes: return "10 Minutes"
    case .thirtyMinutes: return "30 Minutes"
    case .never: return "Never"
    }
  }
}

extension ScraperSource {
  var displayName: String {
    switch self {
    case .FlixHQ: return "FlixHQ"
    case .Movies111: return "Movies111"
    case .VidSrc: return "VidSrc"
    case .VidRock: return "VidRock"
    case .VidFast: return "VidFast"
    case .VidNest: return "VidNest"
    case .AnimeKai: return "AnimeKai"
    case .GogoAnime: return "GogoAnime"
    case .HiAnime: return "HiAnime"
    }
  }
}

extension ContentLanguage {
  var displayName: String {
    rawValue.capitalized
  }
}

extension VideoQuality {
  var displayName: String {
    switch self {
    case .auto: return "Auto"
    case .sd480: return "480p"
    case .hd720: return "720p"
    case .hd1080: return "1080p"
    case .uhd4k: return "4K"
    }
  }
}

extension SubtitleLanguage {
  var displayName: String {
    rawValue.capitalized
  }
}

extension AudioLanguage {
  var displayName: String {
    rawValue.capitalized
  }
}

extension PlaybackSpeed {
  var displayName: String {
    "\(rawValue)x"
  }
}
