//
//  ContentView.swift
//  Bus Buddy
//
//  The main container view.
//  - First shows the SplashView.
//  - After "Start Tracking", shows a tab bar with Track and Journey tabs.
//  - Presents universal top alert banners just below the safe area on ANY iPhone.
//

import SwiftUI

struct ContentView: View {

    /// Whether we've moved past the splash screen.
    @State private var showMainApp = false

    /// Which tab is selected (0 = Track, 1 = Journey).
    @State private var selectedTab = 0

    /// The shared bus simulator that drives the whole demo.
    @State private var simulator = BusSimulator()

    /// Notification manager for local notification banners.
    @State private var notificationManager = NotificationManager()

    var body: some View {
        ZStack(alignment: .top) {
            // Main content (Splash or TabView)
            if showMainApp {
                TabView(selection: $selectedTab) {
                    Tab("Track", systemImage: "location.fill", value: 0) {
                        TrackView()
                    }

                    Tab("Journey", systemImage: "clock.fill", value: 1) {
                        JourneyView()
                    }
                }
                .tint(.blue)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else {
                SplashView {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showMainApp = true
                    }
                    simulator.play()
                }
                .transition(.opacity.combined(with: .move(edge: .leading)))
            }

            // Universal Top Alert Banner — slides down just below the top safe area
            if let alert = simulator.currentBannerAlert {
                TopAlertBannerView(alert: alert) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        simulator.currentBannerAlert = nil
                    }
                }
                .padding(.top, 8)
                .padding(.horizontal, 16)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(100)
            }
        }
        .animation(.spring(response: 0.42, dampingFraction: 0.78), value: simulator.currentBannerAlert != nil)
        .environment(simulator)
        .environment(notificationManager)
        .onAppear {
            simulator.notificationManager = notificationManager
            notificationManager.requestPermission()
        }
    }
}

#Preview {
    ContentView()
}
