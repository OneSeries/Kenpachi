// SplashView.swift
// Disney+ style splash screen with animated logo and loading indicator
// Provides polished launch experience with smooth transitions

import SwiftUI
import ComposableArchitecture

struct SplashView: View {
    /// TCA store for splash feature
    let store: StoreOf<SplashFeature>
    
    /// Animation state for logo scale
    @State private var logoScale: CGFloat = 0.5
    /// Animation state for logo opacity
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.black, Color.primaryBlue.opacity(0.3), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: .spacingXL) {
                Spacer()
                
                // App logo
                Text("app.name")
                    .font(.displayLarge)
                    .foregroundColor(.white)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                
                // Error message if any
                if let errorMessage = store.errorMessage {
                    Text(errorMessage)
                        .font(.bodySmall)
                        .foregroundColor(.error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingXXL)
                }
                
                Spacer()
                
                // App version
                Text(String(format: String(localized: "splash.version"), AppConstants.App.version))
                    .font(.captionSmall)
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, .spacingXL)
            }
        }
        .onAppear {
            // Trigger splash logic
            store.send(.onAppear)
            
            // Animate logo
            withAnimation(.easeOut(duration: 1.0)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
        }
    }
}