//
//  JourneyView.swift
//  Bus Buddy
//
//  Screen 2: Journey & Alerts.
//  Top section: Today's Journey timeline with 5 checkpoints.
//  Middle section: Driver alert simulation buttons.
//  Bottom section: Active alert cards.
//

import SwiftUI

struct JourneyView: View {

    @Environment(BusSimulator.self) private var simulator

    /// Whether the demo controls sheet is showing.
    @State private var showDemoControls = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    // MARK: - Today's Journey Timeline
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundStyle(.blue)
                            Text("Today's Journey")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                        }

                        VStack(spacing: 0) {
                            ForEach(Array(simulator.journeySteps.enumerated()), id: \.element.id) { index, step in
                                TimelineRow(
                                    step: step,
                                    isLast: index == simulator.journeySteps.count - 1
                                )
                            }
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(BusTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(BusTheme.cardBorder, lineWidth: 1)
                            )
                            .shadow(color: BusTheme.cardShadow, radius: 12, y: 4)
                    )

                    // MARK: - Driver Alert Buttons
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(.red)
                            Text("Simulate Driver Alerts")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                        }

                        Text("In real life, these come from the driver or bus sensors.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)

                        // Three alert buttons.
                        HStack(spacing: 12) {
                            alertButton(
                                title: "Tyre\nPuncture",
                                icon: "exclamationmark.triangle.fill",
                                action: {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                    simulator.triggerTyrePuncture()
                                }
                            )

                            alertButton(
                                title: "Road\nBlocked",
                                icon: "road.lanes",
                                action: {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                    simulator.triggerRoadBlocked()
                                }
                            )

                            alertButton(
                                title: "SOS",
                                icon: "sos",
                                action: {
                                    let impact = UIImpactFeedbackGenerator(style: .heavy)
                                    impact.impactOccurred()
                                    simulator.triggerSOS()
                                }
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(BusTheme.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(BusTheme.cardBorder, lineWidth: 1)
                            )
                            .shadow(color: BusTheme.cardShadow, radius: 12, y: 4)
                    )

                    // MARK: - Active Alerts
                    if !simulator.activeAlerts.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Active Alerts")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                Spacer()
                                Button {
                                    simulator.clearAlerts()
                                } label: {
                                    Text("Clear alerts")
                                        .font(.system(size: 13, weight: .medium, design: .rounded))
                                        .foregroundStyle(.blue)
                                }
                            }

                            ForEach(simulator.activeAlerts) { alert in
                                AlertCardView(alert: alert)
                            }
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(BusTheme.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 22)
                                        .stroke(BusTheme.cardBorder, lineWidth: 1)
                                )
                                .shadow(color: BusTheme.cardShadow, radius: 12, y: 4)
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(BusTheme.pageBackground)
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showDemoControls = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showDemoControls) {
                DemoControlsView()
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: simulator.activeAlerts.count)
    }

    // MARK: - Alert Button

    @ViewBuilder
    private func alertButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(.red)

                Text(title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.red.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.red.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
