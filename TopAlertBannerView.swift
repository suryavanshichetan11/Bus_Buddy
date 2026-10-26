//
//  TopAlertBannerView.swift
//  Bus Buddy
//
//  A universal top alert banner that slides down just below the top safe area.
//  Works on ANY iPhone (Dynamic Island, Notch, or plain status bar).
//  - Road blocked uses amber, SOS uses red
//  - Slides down, expands with spring animation to show alert title & message
//  - SOS triggers a short horizontal shake and strong haptic feedback
//  - Auto-dismisses after ~4 seconds or can be swiped up to dismiss
//

import SwiftUI

struct TopAlertBannerView: View {
    let alert: AlertItem
    var onDismiss: () -> Void

    @State private var shakeOffset: CGFloat = 0.0
    @State private var isExpanded: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Alert Icon Circle
            ZStack {
                Circle()
                    .fill(alert.themeColor.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: alert.icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(alert.themeColor)
            }

            // Alert Title & Message
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title.uppercased())
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundStyle(alert.themeColor)
                        .tracking(0.6)

                    Spacer()

                    // Quick dismiss button
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }

                Text(alert.message)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(isExpanded ? 4 : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(alert.themeColor.opacity(0.4), lineWidth: 1.5)
                )
                .shadow(color: alert.themeColor.opacity(0.2), radius: 18, y: 6)
        )
        .offset(x: shakeOffset)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height < -10 {
                        onDismiss()
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isExpanded = true
            }

            // If SOS alert: strong haptic and short shake
            if alert.type == .sos {
                triggerSOSFeedback()
            } else {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)
            }
        }
    }

    // MARK: - SOS Shake & Strong Haptics

    private func triggerSOSFeedback() {
        let notifGen = UINotificationFeedbackGenerator()
        notifGen.notificationOccurred(.error)
        let impactGen = UIImpactFeedbackGenerator(style: .heavy)
        impactGen.impactOccurred()

        // Short horizontal shake animation sequence
        withAnimation(.linear(duration: 0.05)) { shakeOffset = -9 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.linear(duration: 0.05)) { shakeOffset = 9 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.linear(duration: 0.05)) { shakeOffset = -6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.linear(duration: 0.05)) { shakeOffset = 6 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
            withAnimation(.linear(duration: 0.05)) { shakeOffset = -3 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.linear(duration: 0.05)) { shakeOffset = 0 }
        }
    }
}
