# 🚌 BusBuddy

**Every child. Every ride. Every moment.**

BusBuddy is an iOS app for parents that makes the school bus journey transparent and safe. It was built as a prototype for a workshop, using SwiftUI, Xcode and an AI coding agent (Google Antigravity).

## The problem

Every morning, parents:
- call the bus driver about 3 times to ask where the bus is,
- have no idea when the bus will reach their stop,
- don't know whether their child has boarded, reached school, or been dropped home.

## The solution

BusBuddy gives parents live information, so they never need to call the driver.

## Features

- **Live bus tracking:** the bus moves on an Apple Map along its route
- **ETA and distance:** live estimate to the child's stop, updated as the bus moves
- **Face-verified boarding status:** the parent sees when the child boards
- **Full-day journey timeline:**
  1. Bus started from depot
  2. Boarded at home
  3. Reached school
  4. Boarded from school
  5. Dropped at home
- **Instant alerts:** tyre puncture, road blocked (adds delay to the ETA) and SOS, shown in the app and as notification banners
- **Premium UI:** splash screen, glass bottom sheet, ETA ring, smooth spring animations and haptics

## Screens

| Splash | Live Tracking | Journey & Alerts |
|---|---|---|
| ![Splash](screenshots/splash.png) | ![Track](screenshots/track.png) | ![Journey](screenshots/journey.png) |

## Tech stack

- Swift and SwiftUI
- MapKit
- UserNotifications (local notifications)
- Xcode, iOS 17 or later

## Run it

1. Clone the repository.
2. Open `BusBuddy.xcodeproj` in Xcode.
3. Choose an iPhone simulator and press Run.
4. Allow notifications when asked.

No GPS, internet or setup is needed. The demo runs by itself and has demo controls (play, pause, speed, face scan, reset).

## What is simulated and what is real

| Simulated in this prototype | Planned for a real product |
|---|---|
| Bus GPS location and ETA | GPS tracker on the bus sending live data to a server |
| Face scanner | Camera at the bus door matching enrolled children |
| Driver alert buttons | A driver panel and bus sensors |
| Local notifications | Push notifications from a backend |

## Privacy note

A real deployment would handle children's face data only with parental consent, encrypted storage and compliance with India's DPDP Act. RFID cards could be offered as an alternative.

## Roadmap

- Real GPS hardware and a backend server
- Face recognition at the bus door
- Driver app and school admin dashboard
- Push notifications
- Lock screen Live Activity and widget

## Author

Built by **[Your Name]** at **[Workshop / College Name]**, 2026.
