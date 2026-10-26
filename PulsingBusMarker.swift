//
//  PulsingBusMarker.swift
//  Bus Buddy
//
//  A clean, high-performance animated bus marker for the map:
//  - Stable upright bus icon for immediate legibility
//  - Subtle pulsing radar ring and soft glowing halo
//  - Solid blue puck with crisp white border
//

import SwiftUI

struct PulsingBusMarker: View {

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Outer pulsing radar ring.
            Circle()
                .stroke(Color.blue.opacity(0.32), lineWidth: 2)
                .frame(width: 48, height: 48)
                .scaleEffect(isPulsing ? 1.45 : 1.0)
                .opacity(isPulsing ? 0.0 : 0.65)
                .animation(
                    .easeOut(duration: 1.3).repeatForever(autoreverses: false),
                    value: isPulsing
                )

            // Soft glowing ambient halo.
            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 40, height: 40)

            // Blue circular body with crisp white outline.
            Circle()
                .fill(.blue)
                .frame(width: 34, height: 34)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: 2.5)
                )
                .shadow(color: .blue.opacity(0.4), radius: 6, y: 2)

            // Upright crisp white bus icon.
            Image(systemName: "bus.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
        }
        .onAppear {
            isPulsing = true
        }
    }
}
