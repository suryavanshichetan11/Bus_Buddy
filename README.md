# Bus Buddy

Bus Buddy is a SwiftUI iOS prototype for live school-bus tracking. It gives
parents a real-time view of the bus, an ETA for their child's stop, a journey
timeline, simulated face-verified boarding, and instant safety alerts — so they
do not have to call the driver.

> This is a demo/prototype. Bus movement, face verification, and driver alerts
> are driven by an in-app simulator, not by live GPS or a backend.

## Features

- **Live tracking map** with an animated route, a pulsing bus marker, and a
  draggable glass bottom sheet.
- **ETA ring** that fills as the bus approaches the child's stop.
- **Journey timeline** with the day's checkpoints and boarding status.
- **Simulated face scan** for boarding verification.
- **Safety alerts** for tyre puncture, road block, and SOS, including local
  notification banners.
- **Demo controls** to play/pause, change simulation speed, jump to the
  afternoon route, and reset the demo.

## Tech stack

- SwiftUI
- MapKit
- CoreLocation
- UserNotifications
- iOS 17+ (uses `Tab`, `@Observable` environment objects, and modern SwiftUI
  APIs)

## Project layout

| File | Purpose |
| --- | --- |
| `Bus_BuddyApp.swift` | App entry point |
| `ContentView.swift` | Splash screen, tab container, and global alert banner |
| `SplashView.swift` | Animated launch screen |
| `TrackView.swift` | Live map, route, bus marker, and ETA sheet |
| `JourneyView.swift` | Journey timeline, alert controls, and alert cards |
| `DemoControlsView.swift` | Presenter/demo controls |
| `Models.swift` | Stops, journey steps, alerts, and child status |
| `BusSimulator.swift` | Observable simulator that drives the demo |
| `NotificationManager.swift` | Local notification permission and delivery |
| `Theme.swift` | Shared colors and styling |
| `Assets.xcassets` | App icon and accent color placeholders |

## Running the app

The repository contains the SwiftUI source and asset catalog. To run it in
Xcode:

1. Create a new **iOS App** project named **Bus Buddy** (SwiftUI, iOS 17+).
2. Replace the generated `Bus_BuddyApp.swift` and `ContentView.swift` with the
   files from this repository.
3. Add the remaining `.swift` files and `Assets.xcassets` to the app target.
4. Build and run on an iPhone simulator or device.

## Notes

- Map locations use the Ahmedabad area as sample data.
- Notifications are local notifications; no push server is required.
- The face scan is an animation-based mock-up, not biometric authentication.
