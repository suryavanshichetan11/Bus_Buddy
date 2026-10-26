//
//  TimelineRow.swift
//  Bus Buddy
//
//  A single row in the journey timeline.
//  Shows a circle (green check or grey), connecting line, title, time, and subtitle.
//

import SwiftUI

struct TimelineRow: View {
    let step: JourneyStep
    let isLast: Bool   // True if this is the last row (no line below).

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left side: circle and connecting line.
            VStack(spacing: 0) {
                // Status circle.
                ZStack {
                    Circle()
                        .fill(step.isCompleted ? Color.green : BusTheme.lightYellowTint.opacity(0.75))
                        .overlay(
                            Circle()
                                .stroke(step.isCompleted ? Color.clear : BusTheme.cardBorder, lineWidth: 1)
                        )
                        .frame(width: 32, height: 32)

                    if step.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Image(systemName: step.icon)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: step.isCompleted)

                // Connecting line to next step.
                if !isLast {
                    Rectangle()
                        .fill(step.isCompleted ? Color.green.opacity(0.45) : BusTheme.warmLine)
                        .frame(width: 2)
                        .frame(height: 48)
                }
            }

            // Right side: step details.
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(step.isCompleted ? .primary : .secondary)

                HStack(spacing: 6) {
                    if step.isCompleted {
                        Text(step.scheduledTime)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.green)
                    } else {
                        Text("Pending")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.gray)
                    }

                    if step.isCompleted && !step.subtitle.isEmpty {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(step.subtitle)
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.top, 4)

            Spacer()
        }
    }
}
