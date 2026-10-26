//
//  FaceScanView.swift
//  Bus Buddy
//
//  A face-scan overlay animation.
//  Shows a scanner frame, "Scanning face..." text, and then a green check.
//

import SwiftUI

struct FaceScanView: View {

    /// Whether the scan is complete (shows green check instead of scanning).
    var isComplete: Bool
    /// The result text (e.g. "Scanning face..." or "Face verified").
    var resultText: String

    // Animated scanner line position.
    @State private var scanLineOffset: CGFloat = -60

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                // Scanner frame (rounded rectangle outline).
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isComplete ? Color.green : Color.blue, lineWidth: 3)
                    .frame(width: 160, height: 160)

                if isComplete {
                    // Green checkmark.
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // Face icon.
                    Image(systemName: "faceid")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue.opacity(0.5))

                    // Moving scan line.
                    RoundedRectangle(cornerRadius: 2)
                        .fill(.blue.opacity(0.5))
                        .frame(width: 120, height: 3)
                        .offset(y: scanLineOffset)
                }

                // Corner brackets for scanner look.
                ScannerCorners(color: isComplete ? .green : .blue)
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isComplete)

            // Status text.
            Text(resultText)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(isComplete ? .green : .blue)
                .contentTransition(.numericText())
                .animation(.easeInOut, value: resultText)
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 20)
        )
        .onAppear {
            // Animate the scan line up and down.
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scanLineOffset = 60
            }
        }
    }
}

// MARK: - Scanner Corner Brackets

/// Draws small bracket corners to give a scanner look.
struct ScannerCorners: View {
    var color: Color

    var body: some View {
        ZStack {
            // Top-left corner.
            CornerBracket(color: color)
                .position(x: 12, y: 12)
            // Top-right corner.
            CornerBracket(color: color)
                .rotationEffect(.degrees(90))
                .position(x: 148, y: 12)
            // Bottom-left corner.
            CornerBracket(color: color)
                .rotationEffect(.degrees(-90))
                .position(x: 12, y: 148)
            // Bottom-right corner.
            CornerBracket(color: color)
                .rotationEffect(.degrees(180))
                .position(x: 148, y: 148)
        }
        .frame(width: 160, height: 160)
    }
}

struct CornerBracket: View {
    var color: Color

    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 20))
            path.addLine(to: CGPoint(x: 0, y: 4))
            path.addQuadCurve(to: CGPoint(x: 4, y: 0),
                              control: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        .stroke(color, lineWidth: 3)
        .frame(width: 20, height: 20)
    }
}
