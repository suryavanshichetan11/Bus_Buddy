//
//  TrackView.swift
//  Bus Buddy
//
//  Screen 1: Live Tracking (Upgraded Premium View).
//  - Full-screen Apple Map with an animated self-drawing route line
//  - Pulsing bus marker that rotates to face its direction of travel (heading)
//  - Multi-tier soft glowing trail behind the bus
//  - Bottom draggable glass sheet (.ultraThinMaterial) with small, medium, and large heights
//  - Circular ETA progress ring that fills as the bus nears the stop, with rolling numeric transitions
//  - Smooth spring animations and light haptic feedback
//

import SwiftUI
import MapKit

/// Three distinct snap heights for the draggable glass sheet.
enum SheetHeightState: CaseIterable {
    case small    // Compact, minimal map obstruction
    case medium   // Standard balanced dashboard
    case large    // Expanded with route milestones and vehicle metrics

    var height: CGFloat {
        switch self {
        case .small: return 125
        case .medium: return 295
        case .large: return 495
        }
    }
}

struct TrackView: View {

    @Environment(BusSimulator.self) private var simulator

    // Map camera position — updates to follow the moving bus.
    @State private var cameraPosition: MapCameraPosition = .automatic

    // Last time camera was smoothly animated.
    @State private var lastCameraUpdate: Date = .distantPast

    // Animated self-drawing route progression (0.0 to 1.0).
    @State private var animatedRouteProgress: Double = 0.0

    // Draggable sheet height state.
    @State private var sheetState: SheetHeightState = .medium

    // Active drag translation offset.
    @State private var dragOffset: CGFloat = 0.0

    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Full Map Canvas
            mapView
                .ignoresSafeArea(edges: .top)

            // MARK: - Draggable Glass Bottom Sheet
            draggableGlassSheet
                .frame(height: currentSheetHeight)
                .transition(.move(edge: .bottom))

            // MARK: - Face Scan Overlay
            if simulator.showFaceScan {
                Color.black.opacity(0.35)
                    .ignoresSafeArea()
                    .transition(.opacity)

                FaceScanView(
                    isComplete: simulator.faceScanComplete,
                    resultText: simulator.faceScanResult
                )
                .transition(.scale(scale: 0.85).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: simulator.showFaceScan)
        .onChange(of: simulator.busPosition.latitude) {
            throttleCameraUpdate()
        }
        .onAppear {
            centerCameraOnBus(animated: false)
            // Animate route drawing itself on first appear.
            withAnimation(.easeInOut(duration: 1.5)) {
                animatedRouteProgress = 1.0
            }
        }
    }

    // MARK: - Current Dynamic Sheet Height

    private var currentSheetHeight: CGFloat {
        let raw = sheetState.height - dragOffset
        return max(SheetHeightState.small.height - 15, min(SheetHeightState.large.height + 30, raw))
    }

    // MARK: - Animated Route Points

    /// The portion of the route coordinates currently drawn.
    private var animatedRouteCoordinates: [CLLocationCoordinate2D] {
        guard !simulator.routePoints.isEmpty else { return [] }
        let targetCount = max(2, Int(Double(simulator.routePoints.count) * animatedRouteProgress))
        return Array(simulator.routePoints.prefix(min(targetCount, simulator.routePoints.count)))
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // 1. Full remaining route — animates drawing itself when screen appears.
            if !animatedRouteCoordinates.isEmpty {
                MapPolyline(coordinates: animatedRouteCoordinates)
                    .stroke(Color.gray.opacity(0.35), lineWidth: 4)
            }

            // 2. Travelled portion of the route in solid blue.
            if !simulator.travelledRouteCoordinates.isEmpty {
                MapPolyline(coordinates: simulator.travelledRouteCoordinates)
                    .stroke(Color.blue, lineWidth: 4)
            }

            // 3. Route Stop Markers.
            ForEach(simulator.stops) { stop in
                switch stop.type {
                case .home:
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.green)
                                .frame(width: 32, height: 32)
                                .shadow(color: .green.opacity(0.35), radius: 5, y: 2)
                            Image(systemName: "house.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                case .school:
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue)
                                .frame(width: 32, height: 32)
                                .shadow(color: .blue.opacity(0.35), radius: 5, y: 2)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                case .depot:
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.65))
                                .frame(width: 26, height: 26)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.white)
                        }
                    }
                case .pickup:
                    Annotation(stop.name, coordinate: stop.coordinate) {
                        ZStack {
                            Circle()
                                .fill(.blue.opacity(0.18))
                                .frame(width: 22, height: 22)
                            Circle()
                                .fill(.blue)
                                .frame(width: 10, height: 10)
                        }
                    }
                }
            }

            // 4. Stable, smooth Pulsing Bus Marker.
            Annotation("Bus", coordinate: simulator.busPosition) {
                PulsingBusMarker()
            }
        }
        .mapStyle(.standard(elevation: .flat))
    }

    // MARK: - Draggable Glass Bottom Sheet

    private var draggableGlassSheet: some View {
        VStack(spacing: 0) {
            // Drag handle grabber pill.
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.secondary.opacity(0.35))
                    .frame(width: 38, height: 5)
                    .padding(.top, 10)
                    .padding(.bottom, 6)
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                cycleSheetState()
            }

            // Sheet body content based on available height.
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    // Road blocked delay banner.
                    if simulator.roadBlockedActive {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.white)
                            Text("Delayed 20 min - road blocked")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.red)
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Bus Header row (always visible).
                    busHeaderRow

                    // Content visible in Medium and Large heights.
                    if currentSheetHeight > 170 {
                        // Circular ETA progress ring & metrics row.
                        etaCircularMetricsRow

                        // Child status badge.
                        childStatusBadge
                    }

                    // Content visible in Large (expanded) height.
                    if currentSheetHeight > 340 {
                        expandedDetailsSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(.ultraThinMaterial)
                .overlay(
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                        .stroke(Color.white.opacity(0.65), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 22, y: -6)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let predicted = sheetState.height - value.predictedEndTranslation.height
                    let closest = SheetHeightState.allCases.min(by: {
                        abs($0.height - predicted) < abs($1.height - predicted)
                    }) ?? .medium

                    // Light haptic feedback.
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()

                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        sheetState = closest
                        dragOffset = 0
                    }
                }
        )
    }

    // MARK: - Bus Header Row

    private var busHeaderRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Bus 7")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("GJ 06 AB 1257")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                    Text("Rahul Kumar")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(.secondary)

                    // Call driver button.
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        if let url = URL(string: "tel://9876543210") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(6)
                            .background(Circle().fill(.green))
                    }
                }
            }

            Spacer()

            // Compact glanceable pill if in Small height mode.
            if currentSheetHeight <= 170 {
                HStack(spacing: 6) {
                    Text("\(simulator.etaMinutes) min")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(simulator.roadBlockedActive ? .red : .blue)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.1f km", simulator.distanceToHomeKm))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(Color.blue.opacity(0.08))
                )
            }

            // LIVE indicator badge.
            HStack(spacing: 5) {
                Circle()
                    .fill(.red)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(.red.opacity(0.1))
            )
        }
    }

    // MARK: - Circular ETA Progress Ring & Metrics

    private var etaCircularMetricsRow: some View {
        HStack(spacing: 18) {
            // Circular progress ring with rolling minutes counter.
            ZStack {
                // Background track ring
                Circle()
                    .stroke(
                        simulator.roadBlockedActive ? Color.red.opacity(0.15) : Color.blue.opacity(0.12),
                        lineWidth: 6
                    )

                // Filling progress ring
                Circle()
                    .trim(from: 0, to: simulator.progressToStop)
                    .stroke(
                        simulator.roadBlockedActive ? Color.red : Color.blue,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: simulator.progressToStop)

                // Rolling minutes transition
                VStack(spacing: -2) {
                    Text("\(simulator.etaMinutes)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(simulator.roadBlockedActive ? .red : .blue)
                        .contentTransition(.numericText(value: Double(simulator.etaMinutes)))
                        .animation(.spring(response: 0.4), value: simulator.etaMinutes)

                    Text("min")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(simulator.roadBlockedActive ? .red : .blue)
                }
            }
            .frame(width: 74, height: 74)

            // Destination context description
            VStack(alignment: .leading, spacing: 3) {
                Text("ESTIMATED ARRIVAL")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                Text("Aarav's Stop")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)

                Text("Ahmedabad route")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Distance remaining readout
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(String(format: "%.1f", simulator.distanceToHomeKm))
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(value: simulator.distanceToHomeKm))
                        .animation(.spring(response: 0.4), value: simulator.distanceToHomeKm)
                    Text("km")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text("remaining")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Child Status Badge

    private var childStatusBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: simulator.childStatus.icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(statusColor)

            Text(simulator.childStatus.displayText)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(statusColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(statusBadgeBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .stroke(Color.white.opacity(0.8), lineWidth: 0.8)
        )
        .animation(.spring(response: 0.4), value: simulator.childStatus)
    }

    // MARK: - Expanded Details (Large Height)

    private var expandedDetailsSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 2)

            // Route milestones bar.
            VStack(alignment: .leading, spacing: 8) {
                Text("TRIP PROGRESS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
                    .tracking(0.5)

                HStack(spacing: 8) {
                    milestonePill(title: "Depot", completed: simulator.journeySteps[0].isCompleted)
                    milestoneDivider(active: simulator.journeySteps[0].isCompleted)
                    milestonePill(title: "Home", completed: simulator.journeySteps[1].isCompleted)
                    milestoneDivider(active: simulator.journeySteps[1].isCompleted)
                    milestonePill(title: "DPS School", completed: simulator.journeySteps[2].isCompleted)
                }
            }

            // 2-column metrics cards.
            HStack(spacing: 12) {
                statCard(title: "AVG SPEED", value: "25 km/h", icon: "gauge.with.needle.fill")
                statCard(title: "STUDENT", value: "Aarav Sharma", icon: "person.crop.circle.fill")
            }

            // Center on bus button.
            Button {
                let impact = UIImpactFeedbackGenerator(style: .light)
                impact.impactOccurred()
                centerCameraOnBus(animated: true)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Re-center on Bus")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.blue.opacity(0.08))
                )
            }
            .buttonStyle(.plain)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Milestone Pill Helper

    private func milestonePill(title: String, completed: Bool) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(completed ? Color.green : Color.secondary.opacity(0.4))
                .frame(width: 7, height: 7)
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(completed ? .primary : .secondary)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(completed ? Color.green.opacity(0.12) : Color.black.opacity(0.04))
        )
    }

    private func milestoneDivider(active: Bool) -> some View {
        Rectangle()
            .fill(active ? Color.green : Color.secondary.opacity(0.2))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.7))
        )
    }

    // MARK: - State Cycle Helper

    private func cycleSheetState() {
        let next: SheetHeightState
        switch sheetState {
        case .small: next = .medium
        case .medium: next = .large
        case .large: next = .medium
        }
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
            sheetState = next
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch simulator.childStatus.iconColorName {
        case "green": return .green
        case "red": return .red
        default: return .blue
        }
    }

    private var statusBadgeBackground: Color {
        switch simulator.childStatus.iconColorName {
        case "green":
            return Color.green.opacity(0.12)
        case "red":
            return Color.red.opacity(0.12)
        default:
            return Color.blue.opacity(0.08)
        }
    }

    private func throttleCameraUpdate() {
        let now = Date()
        // Only re-aim the camera every 1.5 seconds so MapKit transitions smoothly without hitching
        guard now.timeIntervalSince(lastCameraUpdate) > 1.4 else { return }
        lastCameraUpdate = now

        centerCameraOnBus(animated: true)
    }

    private func centerCameraOnBus(animated: Bool) {
        let camera = MapCamera(
            centerCoordinate: simulator.busPosition,
            distance: 5500,
            heading: 0,
            pitch: 0
        )
        if animated {
            withAnimation(.easeInOut(duration: 1.2)) {
                cameraPosition = .camera(camera)
            }
        } else {
            cameraPosition = .camera(camera)
        }
    }
}
