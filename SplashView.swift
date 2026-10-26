//
//  SplashView.swift
//  Bus Buddy
//
//  Premium First Page / Splash Screen:
//  - The school bus is visibly driving down the road with rotating wheels and gentle suspension
//  - Parallax depth: Clouds drift slowly in the sky, trees pass by at medium speed, and road markings scroll
//  - BusBuddy logo and tagline are prominently displayed
//  - Large "Start Tracking" button with haptic feedback
//  - Accelerates forward when tapped, seamlessly launching the live tracking experience
//  - Fully safe-area compatible across all iPhone models (notch, Dynamic Island, or standard top bar)
//

import SwiftUI

struct SplashView: View {

    /// Callback when user taps "Start Tracking".
    var onStart: () -> Void

    // MARK: - Animation States (Driving & Parallax)

    @State private var roadOffset: CGFloat = 0.0
    @State private var treeOffset: CGFloat = 0.0
    @State private var cloudOffset: CGFloat = 0.0
    @State private var wheelRotation: Double = 0.0
    @State private var busSuspensionBounce: CGFloat = 0.0
    @State private var busDriveOff: CGFloat = 0.0
    @State private var buttonPressed = false

    var body: some View {
        ZStack {
            // Soft morning gradient background (sky blue blending into warm cream).
            LinearGradient(
                colors: [
                    Color(red: 0.88, green: 0.93, blue: 1.0),
                    Color(red: 1.0, green: 0.97, blue: 0.90),
                    Color(red: 1.0, green: 0.94, blue: 0.82)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Safe area container: all elements are comfortably placed inside screen bounds.
            VStack(spacing: 0) {
                Spacer()

                // MARK: - Active Parallax Road Scene (Bus Is Moving!)
                parallaxDrivingScene
                    .frame(height: 195)
                    .clipped()

                Spacer()
                    .frame(height: 28)

                // MARK: - Logo & Tagline
                VStack(spacing: 8) {
                    Text("BusBuddy")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.blue)

                    Text("Every child. Every ride. Every moment.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }

                Spacer()

                // MARK: - Start Tracking Button
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()

                    // Bus accelerates forward off-screen as tracking begins
                    withAnimation(.easeInOut(duration: 0.38)) {
                        busDriveOff = 380
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onStart()
                    }
                } label: {
                    Text("Start Tracking")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.blue)
                                .shadow(color: Color.blue.opacity(0.3), radius: 12, y: 6)
                        )
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 28)
                .scaleEffect(buttonPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.3), value: buttonPressed)
            }
        }
        .onAppear {
            startContinuousDrivingMotion()
        }
    }

    // MARK: - Parallax Driving Scene

    private var parallaxDrivingScene: some View {
        ZStack(alignment: .bottom) {
            // Layer 1: Drifting Clouds (Slowest Parallax Speed)
            HStack(spacing: 70) {
                ForEach(0..<6) { i in
                    Image(systemName: "cloud.fill")
                        .font(.system(size: i % 2 == 0 ? 32 : 24))
                        .foregroundStyle(.white.opacity(0.85))
                        .offset(y: i % 2 == 0 ? -125 : -112)
                }
            }
            .offset(x: cloudOffset)

            // Layer 2: Trees Passing By (Medium Parallax Speed)
            HStack(spacing: 50) {
                ForEach(0..<10) { i in
                    Image(systemName: "tree.fill")
                        .font(.system(size: i % 2 == 0 ? 32 : 26))
                        .foregroundStyle(
                            i % 2 == 0
                            ? Color(red: 0.18, green: 0.52, blue: 0.24)
                            : Color(red: 0.24, green: 0.60, blue: 0.30)
                        )
                }
            }
            .offset(x: treeOffset, y: -46)

            // Layer 3: Grass Verge
            Rectangle()
                .fill(Color(red: 0.76, green: 0.88, blue: 0.65))
                .frame(height: 6)
                .offset(y: -44)

            // Layer 4: Asphalt Road Surface with Scrolling Markings
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.24, green: 0.26, blue: 0.30))
                .frame(height: 46)
                .overlay(
                    // Continuously scrolling dashed white road lane markings
                    HStack(spacing: 16) {
                        ForEach(0..<18) { _ in
                            Capsule()
                                .fill(Color.white.opacity(0.85))
                                .frame(width: 20, height: 3)
                        }
                    }
                    .offset(x: roadOffset)
                    .clipped()
                )

            // Layer 5: School Bus (Cruising in the Center, Gently Bobbing)
            sideViewSchoolBus
                .offset(x: busDriveOff, y: -16 + busSuspensionBounce)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Side-View School Bus (With Rotating Wheels)

    private var sideViewSchoolBus: some View {
        ZStack(alignment: .bottomLeading) {
            // Bus Yellow Chassis
            RoundedRectangle(cornerRadius: 7)
                .fill(Color(red: 1.0, green: 0.82, blue: 0.18))
                .frame(width: 94, height: 40)
                .overlay(
                    // Dark bumper & lower trim
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color(red: 0.2, green: 0.2, blue: 0.24))
                            .frame(height: 4)
                    }
                )
                .overlay(
                    // 4 Clean Windows
                    HStack(spacing: 5) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.92))
                                .frame(width: 14, height: 14)
                        }
                        // Front windshield
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.92))
                            .frame(width: 13, height: 16)
                    }
                    .offset(y: -5)
                )
                .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)

            // Two Rotating Wheels
            HStack(spacing: 42) {
                rotatingWheel
                    .offset(x: 12, y: 8)

                rotatingWheel
                    .offset(x: 12, y: 8)
            }
        }
    }

    private var rotatingWheel: some View {
        Circle()
            .fill(Color(red: 0.14, green: 0.14, blue: 0.18))
            .frame(width: 16, height: 16)
            .overlay(
                // Hubcap with spokes that show rotation
                ZStack {
                    Circle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: 8, height: 8)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1.5, height: 8)
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 8, height: 1.5)
                }
                .rotationEffect(.degrees(wheelRotation))
            )
    }

    // MARK: - Continuous Driving Motion

    private func startContinuousDrivingMotion() {
        // Road dashed lane markings scroll smoothly
        withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
            roadOffset = -36
        }

        // Trees pass by at medium speed
        withAnimation(.linear(duration: 3.8).repeatForever(autoreverses: false)) {
            treeOffset = -100
        }

        // Clouds drift slowly in the sky
        withAnimation(.linear(duration: 12.0).repeatForever(autoreverses: false)) {
            cloudOffset = -70
        }

        // Bus wheels rotate continuously
        withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: false)) {
            wheelRotation = 360
        }

        // Gentle road suspension bob
        withAnimation(.easeInOut(duration: 0.35).repeatForever(autoreverses: true)) {
            busSuspensionBounce = -2
        }
    }
}

#Preview {
    SplashView(onStart: {})
}
