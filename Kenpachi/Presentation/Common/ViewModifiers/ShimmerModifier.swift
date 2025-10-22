// ShimmerModifier.swift
// Shimmer loading effect modifier
// Provides animated loading placeholder effect

import SwiftUI

/// View modifier that adds a shimmer loading effect
struct ShimmerModifier: ViewModifier {
  @State private var phase: CGFloat = 0

  func body(content: Self.Content) -> some View {
    ZStack {
      content

      GeometryReader { geometry in
        LinearGradient(
          colors: [
            Color.clear,
            Color.white.opacity(0.3),
            Color.clear,
          ],
          startPoint: .leading,
          endPoint: .trailing
        )
        .frame(width: geometry.size.width * 2)
        .offset(x: phase - geometry.size.width)
      }
      .allowsHitTesting(false)
    }
    .clipped()
    .onAppear {
      withAnimation(
        Animation.linear(duration: 1.5)
          .repeatForever(autoreverses: false)
      ) {
        phase = 300
      }
    }
  }
}
