//
//  DemoControlsView.swift
//  Bus Buddy
//
//  A sheet with demo presenter controls.
//  Lets you Play/Pause, change speed, simulate face scan,
//  jump to afternoon, and reset the demo.
//
//  In the real product, GPS and scanners do all this automatically.
//

import SwiftUI

struct DemoControlsView: View {

    @Environment(BusSimulator.self) private var simulator
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                // Header explanation.
                HStack(spacing: 10) {
                    Image(systemName: "theatermask.and.paintbrush.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Demo Controls")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("In the real product, GPS and scanners do this automatically.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(BusTheme.lightYellowTint.opacity(0.7))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(BusTheme.cardBorder, lineWidth: 1)
                        )
                )

                // Play / Pause.
                HStack(spacing: 16) {
                    controlButton(
                        title: simulator.isPlaying ? "Pause" : "Play",
                        icon: simulator.isPlaying ? "pause.fill" : "play.fill",
                        color: .blue
                    ) {
                        if simulator.isPlaying {
                            simulator.pause()
                        } else {
                            simulator.play()
                        }
                    }
                }

                // Speed selector.
                VStack(alignment: .leading, spacing: 10) {
                    Text("Speed")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))

                    HStack(spacing: 12) {
                        ForEach([1.0, 2.0, 4.0], id: \.self) { speed in
                            Button {
                                simulator.setSpeed(speed)
                            } label: {
                                Text("\(Int(speed))x")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundStyle(simulator.speed == speed ? .white : .blue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(simulator.speed == speed ? Color.blue : BusTheme.lightYellowTint.opacity(0.6))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(BusTheme.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(BusTheme.cardBorder, lineWidth: 1)
                        )
                        .shadow(color: BusTheme.cardShadow, radius: 8, y: 2)
                )

                // Action buttons.
                VStack(spacing: 12) {
                    controlButton(
                        title: "Simulate Face Scan",
                        icon: "faceid",
                        color: .blue
                    ) {
                        simulator.simulateFaceScan()
                        dismiss()
                    }

                    controlButton(
                        title: "Jump to Afternoon",
                        icon: "sun.haze.fill",
                        color: .blue
                    ) {
                        simulator.jumpToAfternoon()
                        dismiss()
                    }

                    controlButton(
                        title: "Reset Demo",
                        icon: "arrow.counterclockwise",
                        color: .red
                    ) {
                        simulator.reset()
                    }
                }

                Spacer()
            }
            .padding(20)
            .background(BusTheme.pageBackground.ignoresSafeArea())
            .navigationTitle("Demo Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                }
            }
        }
    }

    // MARK: - Control Button

    @ViewBuilder
    private func controlButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(BusTheme.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(BusTheme.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: BusTheme.cardShadow, radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
