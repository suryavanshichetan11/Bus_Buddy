//
//  Models.swift
//  Bus Buddy
//
//  Data types used across the app.
//  This file defines our stops, journey steps, alerts, and child status.
//

import Foundation
import CoreLocation
import SwiftUI

// MARK: - Bus Stop
// Each stop on the bus route has a name, location (latitude & longitude),
// and a type so we know if it's the depot, a regular pickup, the child's home, or the school.

struct BusStop: Identifiable {
    let id = UUID()
    let name: String                    // e.g. "Vastrapur Lake"
    let coordinate: CLLocationCoordinate2D
    let type: StopType

    enum StopType {
        case depot      // Where the bus starts in the morning
        case pickup     // A regular pickup stop
        case home       // Aarav's home stop
        case school     // The school destination
    }
}

// MARK: - Journey Step
// Each checkpoint in the day's journey (shown on the Journey screen).

struct JourneyStep: Identifiable {
    let id = UUID()
    let title: String           // e.g. "Bus started from depot"
    let scheduledTime: String   // e.g. "7:05 AM"
    let subtitle: String        // e.g. "Face verified"
    let icon: String            // SF Symbol name
    var isCompleted: Bool = false
}

// MARK: - Alert Item
// An alert triggered by the driver (tyre puncture, road blocked, SOS).

struct AlertItem: Identifiable, Equatable {
    let id: UUID
    let type: AlertType
    let title: String
    let message: String
    let icon: String
    let color: String   // "red" or "amber"

    init(id: UUID = UUID(), type: AlertType, title: String, message: String, icon: String, color: String) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
    }

    /// Color according to specification: Road blocked uses amber, SOS uses red.
    var themeColor: Color {
        switch type {
        case .roadBlocked, .tyrePuncture:
            return Color(red: 1.0, green: 0.62, blue: 0.0) // Amber
        case .sos:
            return Color.red // Danger Red
        }
    }

    enum AlertType: String {
        case tyrePuncture = "tyre"
        case roadBlocked  = "road"
        case sos          = "sos"
    }
}

// MARK: - Child Status
// Describes what's happening with the child right now.

enum ChildStatus: Equatable {
    case waitingToBoard
    case boardedMorning(time: String)
    case reachedSchool(time: String)
    case boardedAfternoon(time: String)
    case droppedHome(time: String)

    /// A short text shown on the Track screen.
    var displayText: String {
        switch self {
        case .waitingToBoard:
            return "Aarav is waiting to board"
        case .boardedMorning(let time):
            return "Aarav boarded at \(time), face verified"
        case .reachedSchool(let time):
            return "Aarav reached school at \(time)"
        case .boardedAfternoon(let time):
            return "Aarav boarded from school at \(time)"
        case .droppedHome(let time):
            return "Aarav dropped at home at \(time)"
        }
    }

    /// The SF Symbol icon for this status.
    var icon: String {
        switch self {
        case .waitingToBoard:
            return "hourglass"
        case .boardedMorning:
            return "checkmark.circle.fill"
        case .reachedSchool:
            return "building.columns.fill"
        case .boardedAfternoon:
            return "bus.fill"
        case .droppedHome:
            return "house.fill"
        }
    }

    /// The colour for this status indicator.
    var iconColorName: String {
        switch self {
        case .waitingToBoard:
            return "blue"
        case .boardedMorning, .droppedHome:
            return "green"
        case .reachedSchool:
            return "blue"
        case .boardedAfternoon:
            return "blue"
        }
    }
}

// MARK: - Demo Phase
// The simulation runs through these phases in order.

enum DemoPhase: Int, Comparable {
    case morningToHome = 0       // Bus travelling from depot towards Aarav's home
    case faceScanMorning = 1     // Face scan at home stop
    case morningToSchool = 2     // Bus travelling from home to school
    case atSchool = 3            // Bus has reached school (morning done)
    case afternoonStart = 4      // Afternoon: bus leaving school
    case faceScanAfternoon = 5   // Face scan when boarding at school
    case afternoonToHome = 6     // Bus travelling from school back to home
    case droppedHome = 7         // Journey complete

    static func < (lhs: DemoPhase, rhs: DemoPhase) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
