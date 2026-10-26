//
//  BusSimulator.swift
//  Bus Buddy
//
//  The brain of the demo. This class:
//    - Holds a list of bus stops with real coordinates in Ahmedabad, India.
//    - Moves the bus along the route on a 60 FPS smooth timer.
//    - Calculates ETA and distance to the child's home stop via O(1) precomputed metrics.
//    - Manages the full-day story (morning trip, face scans, afternoon trip).
//    - Handles driver alerts (tyre puncture, road blocked, SOS).
//
//  All GPS data is simulated — no real location services needed.
//

import Foundation
import CoreLocation
import SwiftUI

@Observable
final class BusSimulator {

    // MARK: - Route Data
    // A realistic route in Ahmedabad, Gujarat, India.
    // 8 stops: Depot, 5 pickups, Home (Aarav's stop), School.

    let stops: [BusStop] = [
        BusStop(name: "Bus Depot",
                coordinate: CLLocationCoordinate2D(latitude: 23.0225, longitude: 72.5714),
                type: .depot),
        BusStop(name: "Vastrapur Lake",
                coordinate: CLLocationCoordinate2D(latitude: 23.0301, longitude: 72.5290),
                type: .pickup),
        BusStop(name: "Prahladnagar",
                coordinate: CLLocationCoordinate2D(latitude: 23.0130, longitude: 72.5120),
                type: .pickup),
        BusStop(name: "Satellite",
                coordinate: CLLocationCoordinate2D(latitude: 23.0180, longitude: 72.5050),
                type: .pickup),
        BusStop(name: "Jodhpur Cross Rd",
                coordinate: CLLocationCoordinate2D(latitude: 23.0280, longitude: 72.5100),
                type: .pickup),
        BusStop(name: "Ambawadi",
                coordinate: CLLocationCoordinate2D(latitude: 23.0350, longitude: 72.5500),
                type: .pickup),
        BusStop(name: "Aarav's Home",
                coordinate: CLLocationCoordinate2D(latitude: 23.0400, longitude: 72.5600),
                type: .home),
        BusStop(name: "DPS School",
                coordinate: CLLocationCoordinate2D(latitude: 23.0500, longitude: 72.5800),
                type: .school),
    ]

    /// The index of the home stop in the stops array.
    var homeStopIndex: Int { 6 }

    /// The index of the school stop.
    var schoolStopIndex: Int { 7 }

    // MARK: - Simulation State

    /// All the small GPS points along the route (interpolated between stops).
    var routePoints: [CLLocationCoordinate2D] = []

    /// Density for smooth, visible movement.
    let pointsPerSegment = 80

    /// Precomputed cumulative distance along the route for instant O(1) ETA calculation.
    var cumulativeDistances: [Double] = []

    /// Travelled coordinates sliced smoothly for the blue polyline.
    var travelledRouteCoordinates: [CLLocationCoordinate2D] = []

    /// The current index into routePoints (where the bus is now).
    var currentPointIndex: Int = 0

    /// The bus's current position on the map.
    var busPosition: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 23.0225, longitude: 72.5714)

    /// How far the bus has come as a fraction (0.0 to 1.0).
    var progress: Double = 0

    /// Is the simulation currently playing?
    var isPlaying: Bool = false

    /// Speed multiplier: 1x, 2x, or 4x.
    var speed: Double = 1.0

    /// Timer interval (0.05s = 20 updates per second) for liquid-smooth motion.
    let baseInterval: Double = 0.05

    /// Tick counter to throttle non-visual calculations.
    private var tickCount: Int = 0

    /// Current demo phase.
    var phase: DemoPhase = .morningToHome

    /// Child's current status (shown on Track screen).
    var childStatus: ChildStatus = .waitingToBoard

    /// ETA to the home stop in minutes.
    var etaMinutes: Int = 12

    /// Distance remaining to home stop in km.
    var distanceToHomeKm: Double = 4.0

    /// Progress from 0.0 to 1.0 towards the destination stop (used for the circular ETA progress ring).
    var progressToStop: Double {
        let homePointIndex = Double(homeStopIndex * pointsPerSegment)
        guard homePointIndex > 0 else { return 0.0 }

        switch phase {
        case .morningToHome:
            return min(1.0, max(0.0, Double(currentPointIndex) / homePointIndex))
        case .faceScanMorning, .morningToSchool, .atSchool:
            return 1.0
        case .afternoonStart, .faceScanAfternoon, .afternoonToHome:
            let totalAfternoon = Double(routePoints.count - 1) - homePointIndex
            guard totalAfternoon > 0 else { return 1.0 }
            let completed = Double(routePoints.count - 1) - Double(currentPointIndex)
            return min(1.0, max(0.0, completed / totalAfternoon))
        case .droppedHome:
            return 1.0
        }
    }

    /// Whether the bus has arrived at home (morning).
    var arrivedAtHome: Bool = false

    /// Whether the bus has arrived at school.
    var arrivedAtSchool: Bool = false

    /// Is a face scan animation currently showing?
    var showFaceScan: Bool = false

    /// Face scan result text.
    var faceScanResult: String = ""

    /// Is the face scan complete?
    var faceScanComplete: Bool = false

    // MARK: - Journey Timeline

    var journeySteps: [JourneyStep] = [
        JourneyStep(title: "Bus started from depot",
                    scheduledTime: "7:05 AM",
                    subtitle: "",
                    icon: "bus.fill"),
        JourneyStep(title: "Boarded at home",
                    scheduledTime: "7:42 AM",
                    subtitle: "Face verified",
                    icon: "faceid"),
        JourneyStep(title: "Reached school",
                    scheduledTime: "8:15 AM",
                    subtitle: "Entered campus safely",
                    icon: "building.columns.fill"),
        JourneyStep(title: "Boarded from school",
                    scheduledTime: "3:30 PM",
                    subtitle: "Face verified",
                    icon: "faceid"),
        JourneyStep(title: "Dropped at home",
                    scheduledTime: "4:05 PM",
                    subtitle: "Parent notified",
                    icon: "house.fill"),
    ]

    // MARK: - Alerts

    /// Active alert cards.
    var activeAlerts: [AlertItem] = []

    /// Whether road-blocked delay is active (adds 20 min to ETA).
    var roadBlockedActive: Bool = false

    /// Extra delay minutes from road blocked.
    var delayMinutes: Int = 0

    /// Whether a tyre puncture pause is active.
    var tyrePunctureActive: Bool = false

    // MARK: - Timer
    private var timer: Timer?

    // MARK: - Notification Manager (injected)
    var notificationManager: NotificationManager?

    // MARK: - Initialise

    init() {
        buildRoutePoints()
        busPosition = routePoints.first ?? stops[0].coordinate
    }

    // MARK: - Build Interpolated Route Points
    /// Creates smooth GPS points between each pair of stops and precomputes distances.
    func buildRoutePoints() {
        routePoints = []
        for i in 0 ..< stops.count - 1 {
            let from = stops[i].coordinate
            let to = stops[i + 1].coordinate
            for j in 0 ..< pointsPerSegment {
                let fraction = Double(j) / Double(pointsPerSegment)
                let lat = from.latitude + (to.latitude - from.latitude) * fraction
                let lon = from.longitude + (to.longitude - from.longitude) * fraction
                routePoints.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
            }
        }
        // Add the very last point (the school).
        if let last = stops.last {
            routePoints.append(last.coordinate)
        }

        // Precompute cumulative distances once for O(1) instant lookup.
        cumulativeDistances = [0.0]
        var totalDist: Double = 0
        if routePoints.count > 1 {
            for i in 0 ..< routePoints.count - 1 {
                let from = CLLocation(latitude: routePoints[i].latitude, longitude: routePoints[i].longitude)
                let to = CLLocation(latitude: routePoints[i + 1].latitude, longitude: routePoints[i + 1].longitude)
                totalDist += from.distance(from: to)
                cumulativeDistances.append(totalDist)
            }
        }

        travelledRouteCoordinates = routePoints.first != nil ? [routePoints[0]] : []
    }

    // MARK: - Play / Pause

    func play() {
        guard !isPlaying else { return }
        isPlaying = true

        // Mark the first journey step as completed when we start.
        if phase == .morningToHome && !journeySteps[0].isCompleted {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                journeySteps[0].isCompleted = true
            }
        }

        startTimer()
    }

    func pause() {
        isPlaying = false
        timer?.invalidate()
        timer = nil
    }

    private func startTimer() {
        timer?.invalidate()
        let interval = baseInterval / speed
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    // MARK: - Speed Control

    func setSpeed(_ newSpeed: Double) {
        speed = newSpeed
        if isPlaying {
            startTimer()
        }
    }

    // MARK: - Tick (one simulation step)

    private func tick() {
        // Don't move during tyre puncture pause.
        if tyrePunctureActive { return }

        // Don't move during face scan.
        if showFaceScan { return }

        tickCount += 1

        switch phase {
        case .morningToHome:
            moveBusForward()
            if tickCount % 6 == 0 {
                updateETAAndDistance()
            }

            // Check if bus reached home stop.
            let homePointIndex = homeStopIndex * pointsPerSegment
            if currentPointIndex >= homePointIndex {
                phase = .faceScanMorning
                triggerFaceScan(morning: true)
            }

        case .faceScanMorning:
            break

        case .morningToSchool:
            moveBusForward()
            let schoolPointIndex = schoolStopIndex * pointsPerSegment
            if currentPointIndex >= schoolPointIndex {
                currentPointIndex = routePoints.count - 1
                busPosition = routePoints[currentPointIndex]
                phase = .atSchool
                arrivedAtSchool = true
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    childStatus = .reachedSchool(time: "8:15 AM")
                    journeySteps[2].isCompleted = true
                }
                notificationManager?.send(
                    title: "BusBuddy",
                    body: "Aarav reached school at 8:15 AM. Entered campus safely."
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0 / speed) { [weak self] in
                    self?.startAfternoon()
                }
            }

        case .atSchool:
            break

        case .afternoonStart:
            phase = .faceScanAfternoon
            triggerFaceScan(morning: false)

        case .faceScanAfternoon:
            break

        case .afternoonToHome:
            moveBusBackward()
            if tickCount % 6 == 0 {
                updateETAAndDistance()
            }

            let homePointIndex = homeStopIndex * pointsPerSegment
            if currentPointIndex <= homePointIndex {
                currentPointIndex = homePointIndex
                busPosition = routePoints[currentPointIndex]
                phase = .droppedHome
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    childStatus = .droppedHome(time: "4:05 PM")
                    journeySteps[4].isCompleted = true
                }
                notificationManager?.send(
                    title: "BusBuddy",
                    body: "Aarav was dropped at home safely at 4:05 PM."
                )
                pause()
            }

        case .droppedHome:
            pause()
        }

        // Update progress smoothly.
        if !routePoints.isEmpty {
            progress = Double(currentPointIndex) / Double(routePoints.count - 1)
        }
    }

    // MARK: - Move Bus (Glides smoothly without animation hitching)

    private func moveBusForward() {
        if currentPointIndex < routePoints.count - 1 {
            currentPointIndex += 1
            busPosition = routePoints[currentPointIndex]

            // Throttle travelled polyline array slicing to prevent MapKit Metal stalls.
            if currentPointIndex % 6 == 0 || currentPointIndex == routePoints.count - 1 {
                travelledRouteCoordinates = Array(routePoints[0...currentPointIndex])
            }
        }
    }

    private func moveBusBackward() {
        if currentPointIndex > 0 {
            currentPointIndex -= 1
            busPosition = routePoints[currentPointIndex]

            if currentPointIndex % 6 == 0 || currentPointIndex == 0 {
                travelledRouteCoordinates = Array(routePoints[0...currentPointIndex])
            }
        }
    }

    // MARK: - ETA & Distance Calculation (O(1) Instant Lookup)

    func updateETAAndDistance() {
        let homePointIndex = min(homeStopIndex * pointsPerSegment, cumulativeDistances.count - 1)
        guard homePointIndex < cumulativeDistances.count, currentPointIndex < cumulativeDistances.count else { return }

        let remainingMeters: Double
        if phase == .afternoonToHome || phase == .afternoonStart {
            remainingMeters = max(0, cumulativeDistances[currentPointIndex] - cumulativeDistances[homePointIndex])
        } else {
            remainingMeters = max(0, cumulativeDistances[homePointIndex] - cumulativeDistances[currentPointIndex])
        }

        let km = remainingMeters / 1000.0
        distanceToHomeKm = (km * 10).rounded() / 10

        let averageSpeedKmPerMin = 25.0 / 60.0
        var minutes = km / averageSpeedKmPerMin

        if roadBlockedActive {
            minutes += Double(delayMinutes)
        }

        if remainingMeters > 30 {
            etaMinutes = max(1, Int(minutes.rounded()))
        } else {
            etaMinutes = 0
        }
    }

    // MARK: - Face Scan Animation

    func triggerFaceScan(morning: Bool) {
        showFaceScan = true
        faceScanComplete = false
        faceScanResult = "Scanning face..."

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 / speed) { [weak self] in
            guard let self else { return }
            self.faceScanComplete = true
            self.faceScanResult = "Face verified"

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 / self.speed) { [weak self] in
                guard let self else { return }
                self.showFaceScan = false

                if morning {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.childStatus = .boardedMorning(time: "7:42 AM")
                        self.journeySteps[1].isCompleted = true
                        self.arrivedAtHome = true
                    }
                    self.notificationManager?.send(
                        title: "BusBuddy",
                        body: "Aarav boarded the bus at 7:42 AM. Face verified."
                    )
                    self.phase = .morningToSchool
                    self.etaMinutes = 0
                    self.distanceToHomeKm = 0
                } else {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        self.childStatus = .boardedAfternoon(time: "3:30 PM")
                        self.journeySteps[3].isCompleted = true
                    }
                    self.notificationManager?.send(
                        title: "BusBuddy",
                        body: "Aarav boarded from school at 3:30 PM. Face verified."
                    )
                    self.phase = .afternoonToHome
                }
            }
        }
    }

    /// Manually trigger a face scan from demo controls.
    func simulateFaceScan() {
        if phase == .morningToHome {
            let homePointIndex = homeStopIndex * pointsPerSegment
            currentPointIndex = homePointIndex
            busPosition = routePoints[homePointIndex]
            phase = .faceScanMorning
            triggerFaceScan(morning: true)
        } else if phase == .afternoonStart || phase == .afternoonToHome {
            phase = .faceScanAfternoon
            triggerFaceScan(morning: false)
        }
    }

    // MARK: - Afternoon

    func startAfternoon() {
        phase = .afternoonStart
        currentPointIndex = routePoints.count - 1
        busPosition = routePoints[currentPointIndex]
    }

    /// Jump to afternoon from demo controls.
    func jumpToAfternoon() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            journeySteps[0].isCompleted = true
            journeySteps[1].isCompleted = true
            journeySteps[2].isCompleted = true
            childStatus = .reachedSchool(time: "8:15 AM")
        }
        arrivedAtHome = true
        arrivedAtSchool = true
        showFaceScan = false
        startAfternoon()
        if !isPlaying { play() }
    }

    // MARK: - Driver Alerts

    /// Current banner sliding down from below the top safe area.
    var currentBannerAlert: AlertItem? = nil

    private var bannerDismissTask: Task<Void, Never>? = nil

    /// Display the banner just below the safe area, auto-dismissing after ~4 seconds.
    func showTopBanner(alert: AlertItem) {
        bannerDismissTask?.cancel()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
            currentBannerAlert = alert
        }

        bannerDismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if self.currentBannerAlert?.id == alert.id {
                    self.currentBannerAlert = nil
                }
            }
        }
    }

    func triggerTyrePuncture() {
        let alert = AlertItem(
            type: .tyrePuncture,
            title: "Tyre Puncture",
            message: "Bus stopped safely. Replacement bus is on the way.",
            icon: "exclamationmark.triangle.fill",
            color: "amber"
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            activeAlerts.append(alert)
        }
        showTopBanner(alert: alert)
        notificationManager?.send(title: "BusBuddy Alert", body: alert.message)

        tyrePunctureActive = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0 / speed) { [weak self] in
            self?.tyrePunctureActive = false
        }
    }

    func triggerRoadBlocked() {
        let alert = AlertItem(
            type: .roadBlocked,
            title: "Road Blocked",
            message: "Road blocked. Bus will be 20 minutes late.",
            icon: "road.lanes",
            color: "amber"
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            activeAlerts.append(alert)
            roadBlockedActive = true
            delayMinutes = 20
        }
        showTopBanner(alert: alert)
        notificationManager?.send(title: "BusBuddy Alert", body: alert.message)
    }

    func triggerSOS() {
        let alert = AlertItem(
            type: .sos,
            title: "SOS Alert",
            message: "Safety alert. Driver pressed SOS. School has been notified immediately.",
            icon: "sos",
            color: "red"
        )
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            activeAlerts.append(alert)
        }
        showTopBanner(alert: alert)
        notificationManager?.send(title: "BusBuddy SOS", body: alert.message)
    }

    func clearAlerts() {
        withAnimation {
            activeAlerts.removeAll()
            roadBlockedActive = false
            delayMinutes = 0
            currentBannerAlert = nil
            bannerDismissTask?.cancel()
        }
    }

    // MARK: - Reset Demo

    func reset() {
        pause()
        currentPointIndex = 0
        busPosition = routePoints.first ?? stops[0].coordinate
        travelledRouteCoordinates = routePoints.first != nil ? [routePoints[0]] : []
        progress = 0
        phase = .morningToHome
        childStatus = .waitingToBoard
        etaMinutes = 12
        distanceToHomeKm = 4.0
        arrivedAtHome = false
        arrivedAtSchool = false
        showFaceScan = false
        faceScanComplete = false
        faceScanResult = ""
        activeAlerts.removeAll()
        currentBannerAlert = nil
        bannerDismissTask?.cancel()
        roadBlockedActive = false
        delayMinutes = 0
        tyrePunctureActive = false
        speed = 1.0

        for i in journeySteps.indices {
            journeySteps[i].isCompleted = false
        }
    }
}
