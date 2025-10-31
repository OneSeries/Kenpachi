// PlayerView.swift
// Disney Plus style video player
// Clean, minimal design with smooth animations

import AVKit
import Combine
import ComposableArchitecture
import SwiftUI

struct PlayerView: View {
  let store: StoreOf<PlayerFeature>
  
  @SwiftUI.Environment(\.dismiss) private var dismiss: DismissAction
  @State private var player: AVPlayer?
  @State private var controlsTimer: Timer?
  @State private var cancellables = Set<AnyCancellable>()
  @State private var lastSeekTime: TimeInterval = 0
  @State private var shouldSeek = false
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        Color.black.ignoresSafeArea()
        
        /// Video player
        if let player = player {
          VideoPlayer(player: player)
            .ignoresSafeArea()
            .overlay(
              /// Transparent tap area to capture gestures
              Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                  withAnimation(.easeInOut(duration: 0.25)) {
                    viewStore.send(.toggleControls)
                  }
                  if viewStore.showControls {
                    resetControlsTimer(viewStore: viewStore)
                  }
                }
            )
        } else if viewStore.isLoading {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.5)
        }
        
        /// Buffering indicator
        if viewStore.isBuffering {
          ProgressView()
            .tint(.white)
            .scaleEffect(1.2)
        }
        
        /// Controls overlay
        if viewStore.showControls {
          DisneyPlayerControls(
            store: store,
            onDismiss: { dismiss() },
            onSeek: { time in
              seekPlayer(to: time)
            }
          )
          .transition(.opacity)
        }
        
        /// Settings panel
        if viewStore.showSettings {
          DisneySettingsPanel(store: store)
            .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        
        /// Error overlay
        if let error = viewStore.errorMessage {
          ErrorOverlay(message: error, onDismiss: { dismiss() })
        }
      }
      .statusBar(hidden: true)
      .persistentSystemOverlays(.hidden)
      .onAppear {
        setOrientation(.landscapeRight)
        viewStore.send(.onAppear)
        setupPlayer(viewStore: viewStore)
        resetControlsTimer(viewStore: viewStore)
      }
      .onDisappear {
        setOrientation(.portrait)
        viewStore.send(.onDisappear)
        cleanupPlayer()
      }
      .onChange(of: viewStore.selectedLink) { _, link in
        if let link = link { updatePlayerItem(with: link) }
      }
      .onChange(of: viewStore.isPlaying) { _, isPlaying in
        isPlaying ? player?.play() : player?.pause()
        isPlaying ? resetControlsTimer(viewStore: viewStore) : controlsTimer?.invalidate()
      }
      .onChange(of: viewStore.playbackSpeed) { _, speed in
        player?.rate = speed
      }
      .onChange(of: viewStore.volume) { _, volume in
        player?.volume = volume
      }
      .onChange(of: viewStore.isMuted) { _, isMuted in
        player?.isMuted = isMuted
      }
    }
  }
  
  /// Performs seek on the player
  /// - Parameter time: Target time in seconds
  private func seekPlayer(to time: TimeInterval) {
    guard let player = player else { return }
    let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    player.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
  }
  
  private func setupPlayer(viewStore: ViewStoreOf<PlayerFeature>) {
    guard let link = viewStore.selectedLink,
          let url = URL(string: link.url) else {
      viewStore.send(.errorOccurred("Invalid streaming URL"))
      return
    }
    
    var asset = AVURLAsset(url: url)
    if link.requiresReferer, let headers = link.headers {
      asset = AVURLAsset(url: url, options: ["AVURLAssetHTTPHeaderFieldsKey": headers])
    }
    
    let playerItem = AVPlayerItem(asset: asset)
    let newPlayer = AVPlayer(playerItem: playerItem)
    newPlayer.allowsExternalPlayback = true
    
    let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
      let current = time.seconds
      let duration = playerItem.duration.seconds
      if !current.isNaN && !duration.isNaN {
        viewStore.send(.timeUpdated(current: current, duration: duration))
      }
    }
    
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: playerItem,
      queue: .main
    ) { _ in
      viewStore.send(.playbackStateChanged(false))
    }
    
    playerItem.publisher(for: \.status)
      .sink { status in
        if status == .failed {
          viewStore.send(.tryNextStream)
        }
      }
      .store(in: &cancellables)
    
    self.player = newPlayer
    newPlayer.play()
    viewStore.send(.playbackStateChanged(true))
  }
  
  private func updatePlayerItem(with link: ExtractedLink) {
    guard let url = URL(string: link.url) else { return }
    let playerItem = AVPlayerItem(url: url)
    player?.replaceCurrentItem(with: playerItem)
    player?.play()
  }
  
  private func cleanupPlayer() {
    player?.pause()
    player = nil
    controlsTimer?.invalidate()
    cancellables.removeAll()
  }
  
  private func resetControlsTimer(viewStore: ViewStoreOf<PlayerFeature>) {
    controlsTimer?.invalidate()
    guard viewStore.isPlaying else { return }
    
    controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
      if viewStore.isPlaying && viewStore.showControls {
        withAnimation(.easeInOut(duration: 0.25)) {
          viewStore.send(.toggleControls)
        }
      }
    }
  }
  
  private func setOrientation(_ orientation: UIInterfaceOrientation) {
    if #available(iOS 16.0, *) {
      guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
      scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation.toMask))
    } else {
      UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
  }
}

extension UIInterfaceOrientation {
  var toMask: UIInterfaceOrientationMask {
    switch self {
    case .portrait: return .portrait
    case .landscapeLeft: return .landscapeLeft
    case .landscapeRight: return .landscapeRight
    default: return .all
    }
  }
}

// MARK: - Video Player
struct VideoPlayer: UIViewControllerRepresentable {
  let player: AVPlayer
  
  func makeUIViewController(context: Context) -> AVPlayerViewController {
    let controller = AVPlayerViewController()
    controller.player = player
    controller.showsPlaybackControls = false
    controller.videoGravity = .resizeAspect
    return controller
  }
  
  func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

// MARK: - Disney Player Controls
struct DisneyPlayerControls: View {
  let store: StoreOf<PlayerFeature>
  let onDismiss: () -> Void
  let onSeek: (TimeInterval) -> Void
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack(spacing: 0) {
        /// Top bar
        HStack {
          Button(action: onDismiss) {
            Image(systemName: "chevron.left")
              .font(.title2)
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text(viewStore.content.title)
              .font(.headline)
              .foregroundColor(.white)
            
            if let episode = viewStore.episode {
              Text(episode.formattedEpisodeId)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            }
          }
          
          Spacer()
          
          if viewStore.isAirPlayAvailable {
            AirPlayButton()
              .frame(width: 44, height: 44)
          }
          
          Button {
            viewStore.send(.toggleSettings)
          } label: {
            Image(systemName: "gearshape.fill")
              .font(.title3)
              .foregroundColor(.white)
              .frame(width: 44, height: 44)
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .background(
          LinearGradient(
            colors: [.black.opacity(0.6), .clear],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 120)
        )
        
        Spacer()
        
        /// Center controls
        HStack(spacing: 80) {
          Button {
            let newTime = max(viewStore.currentTime - 10, 0)
            viewStore.send(.skipBackward(10))
            onSeek(newTime)
          } label: {
            Image(systemName: "gobackward.10")
              .font(.system(size: 40))
              .foregroundColor(.white)
          }
          
          Button {
            viewStore.send(.playPauseTapped)
          } label: {
            Image(systemName: viewStore.isPlaying ? "pause.fill" : "play.fill")
              .font(.system(size: 50))
              .foregroundColor(.white)
          }
          
          Button {
            let newTime = min(viewStore.currentTime + 10, viewStore.duration)
            viewStore.send(.skipForward(10))
            onSeek(newTime)
          } label: {
            Image(systemName: "goforward.10")
              .font(.system(size: 40))
              .foregroundColor(.white)
          }
        }
        
        Spacer()
        
        /// Bottom bar
        VStack(spacing: 12) {
          DisneyProgressBar(
            currentTime: viewStore.currentTime,
            duration: viewStore.duration,
            onSeek: { time in
              viewStore.send(.seekTo(time))
              onSeek(time)
            },
            onSeekingChanged: { viewStore.send(.seekingStateChanged($0)) }
          )
          
          HStack {
            Text(formatTime(viewStore.currentTime))
              .font(.caption)
              .foregroundColor(.white)
            
            Spacer()
            
            Text(formatTime(viewStore.duration))
              .font(.caption)
              .foregroundColor(.white)
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .background(
          LinearGradient(
            colors: [.clear, .black.opacity(0.6)],
            startPoint: .top,
            endPoint: .bottom
          )
          .frame(height: 120)
        )
      }
    }
  }
  
  private func formatTime(_ time: TimeInterval) -> String {
    guard !time.isNaN && !time.isInfinite else { return "0:00" }
    let hours = Int(time) / 3600
    let minutes = Int(time) / 60 % 60
    let seconds = Int(time) % 60
    return hours > 0 ? String(format: "%d:%02d:%02d", hours, minutes, seconds) : String(format: "%d:%02d", minutes, seconds)
  }
}

// MARK: - Disney Progress Bar
struct DisneyProgressBar: View {
  let currentTime: TimeInterval
  let duration: TimeInterval
  let onSeek: (TimeInterval) -> Void
  let onSeekingChanged: (Bool) -> Void
  
  @State private var isDragging = false
  @State private var dragValue: Double = 0
  
  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        /// Background
        Capsule()
          .fill(Color.white.opacity(0.3))
          .frame(height: isDragging ? 6 : 3)
        
        /// Progress
        Capsule()
          .fill(Color.white)
          .frame(width: progressWidth(in: geometry.size.width), height: isDragging ? 6 : 3)
        
        /// Thumb
        Circle()
          .fill(Color.white)
          .frame(width: isDragging ? 16 : 0, height: isDragging ? 16 : 0)
          .offset(x: progressWidth(in: geometry.size.width) - (isDragging ? 8 : 0))
      }
      .animation(.easeOut(duration: 0.2), value: isDragging)
      .gesture(
        DragGesture(minimumDistance: 0)
          .onChanged { value in
            if !isDragging {
              isDragging = true
              onSeekingChanged(true)
            }
            let progress = min(max(0, value.location.x / geometry.size.width), 1)
            dragValue = progress * duration
          }
          .onEnded { value in
            isDragging = false
            onSeekingChanged(false)
            let progress = min(max(0, value.location.x / geometry.size.width), 1)
            onSeek(progress * duration)
          }
      )
    }
    .frame(height: 30)
  }
  
  private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
    guard duration > 0 else { return 0 }
    let progress = isDragging ? dragValue / duration : currentTime / duration
    return totalWidth * CGFloat(progress)
  }
}

// MARK: - Disney Settings Panel
struct DisneySettingsPanel: View {
  let store: StoreOf<PlayerFeature>
  
  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      HStack {
        Spacer()
        
        VStack(spacing: 0) {
          /// Header
          HStack {
            Text("player.settings")
              .font(.headline)
              .foregroundColor(.white)
            
            Spacer()
            
            Button {
              viewStore.send(.toggleSettings)
            } label: {
              Image(systemName: "xmark")
                .foregroundColor(.white)
            }
          }
          .padding()
          .background(Color.black.opacity(0.95))
          
          ScrollView {
            VStack(spacing: 0) {
              /// Quality
              PlayerSettingsSection(title: "Quality") {
                ForEach(viewStore.availableQualities, id: \.self) { quality in
                  SettingsButton(
                    title: quality,
                    isSelected: quality == viewStore.selectedQuality
                  ) {
                    viewStore.send(.qualitySelected(quality))
                  }
                }
              }
              
              Divider().background(Color.white.opacity(0.2))
              
              /// Speed
              PlayerSettingsSection(title: "Speed") {
                ForEach(viewStore.availablePlaybackSpeeds, id: \.self) { speed in
                  SettingsButton(
                    title: speed == 1.0 ? "Normal" : "\(String(format: "%.2fx", speed))",
                    isSelected: speed == viewStore.playbackSpeed
                  ) {
                    viewStore.send(.playbackSpeedChanged(speed))
                  }
                }
              }
            }
          }
        }
        .frame(width: 260)
        .background(Color.black.opacity(0.95))
        .cornerRadius(12)
        .padding()
      }
    }
  }
}

struct PlayerSettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal)
        .padding(.top, 12)
      
      content
    }
  }
}

struct SettingsButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void
  
  var body: some View {
    Button(action: action) {
      HStack {
        Text(title)
          .foregroundColor(.white)
        
        Spacer()
        
        if isSelected {
          Image(systemName: "checkmark")
            .foregroundColor(.blue)
        }
      }
      .padding()
      .background(isSelected ? Color.white.opacity(0.1) : Color.clear)
    }
  }
}

// MARK: - AirPlay Button
struct AirPlayButton: UIViewRepresentable {
  func makeUIView(context: Context) -> AVRoutePickerView {
    let picker = AVRoutePickerView()
    picker.tintColor = .white
    return picker
  }
  
  func updateUIView(_ uiView: AVRoutePickerView, context: Context) {}
}

// MARK: - Error Overlay
struct ErrorOverlay: View {
  let message: String
  let onDismiss: () -> Void
  
  var body: some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 50))
        .foregroundColor(.red)
      
      Text("player.error.title")
        .font(.title2.bold())
        .foregroundColor(.white)
      
      Text(message)
        .font(.body)
        .foregroundColor(.white.opacity(0.8))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      
      Button(action: onDismiss) {
        Text("player.close")
          .font(.headline)
          .foregroundColor(.white)
          .padding(.horizontal, 32)
          .padding(.vertical, 12)
          .background(Color.blue)
          .cornerRadius(8)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black.opacity(0.95))
  }
}
