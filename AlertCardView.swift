//
//  AlertCardView.swift
//  Bus Buddy
//
//  A card that slides in when a driver alert fires (tyre puncture, road blocked, SOS).
//  Uses red colour and an SF Symbol icon.
//

import SwiftUI

struct AlertCardView: View {
    let alert: AlertItem

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle.
            ZStack {
                Circle()
                    .fill(alert.themeColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: alert.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(alert.themeColor)
            }

            // Text.
            VStack(alignment: .leading, spacing: 3) {
                Text(alert.title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(alert.themeColor)

                Text(alert.message)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(BusTheme.cardBackground)
                .shadow(color: alert.themeColor.opacity(0.1), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(alert.themeColor.opacity(0.25), lineWidth: 1)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}
