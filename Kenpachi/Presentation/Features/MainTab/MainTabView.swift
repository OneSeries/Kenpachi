// MainTabView.swift
// Main tab bar navigation view
// Provides bottom tab navigation between main app sections

import ComposableArchitecture
import SwiftUI

struct MainTabView: View {
  /// TCA store for main tab feature
  @Bindable var store: StoreOf<MainTabFeature>

  var body: some View {
    TabView(selection: $store.selectedTab.sending(\.tabSelected)) {
      // Home Tab
      HomeView(store: store.scope(state: \.home, action: \.home))
        .tabItem {
          Label(
            MainTabFeature.State.Tab.home.displayName,
            systemImage: MainTabFeature.State.Tab.home.iconName
          )
        }
        .tag(MainTabFeature.State.Tab.home)

      // Search Tab
      SearchView(store: store.scope(state: \.search, action: \.search))
        .tabItem {
          Label(
            MainTabFeature.State.Tab.search.displayName,
            systemImage: MainTabFeature.State.Tab.search.iconName
          )
        }
        .tag(MainTabFeature.State.Tab.search)

      // Downloads Tab
      DownloadsView(store: store.scope(state: \.downloads, action: \.downloads))
        .tabItem {
          Label(
            MainTabFeature.State.Tab.downloads.displayName,
            systemImage: MainTabFeature.State.Tab.downloads.iconName
          )
        }
        .tag(MainTabFeature.State.Tab.downloads)

      // MySpace Tab
      MySpaceView(store: store.scope(state: \.mySpace, action: \.mySpace))
        .tabItem {
          Label(
            MainTabFeature.State.Tab.mySpace.displayName,
            systemImage: MainTabFeature.State.Tab.mySpace.iconName
          )
        }
        .tag(MainTabFeature.State.Tab.mySpace)
    }
    .tint(.primaryBlue)
    .fullScreenCover(
      item: $store.scope(state: \.contentDetail, action: \.contentDetail)
    ) { detailStore in
      NavigationStack {
        ContentDetailView(store: detailStore)
          .navigationBarTitleDisplayMode(.inline)
          .toolbarBackground(.hidden, for: .navigationBar)
          .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
              Button {
                store.send(.contentDetail(.dismiss))
              } label: {
                Image(systemName: "chevron.left")
                  .font(.title3.weight(.semibold))
                  .foregroundColor(.white)
                  .shadow(color: .black.opacity(0.5), radius: 3, x: 0, y: 1)
              }
            }
          }
      }
    }
  }
}


