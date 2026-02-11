---
name: ios-developing
description: Guides iOS and iPadOS app development with Swift, SwiftUI, and UIKit. Use when building or modifying iOS apps, implementing SwiftUI views, handling UIKit lifecycle, or working in Xcode for iPhone/iPad targets.
---

# iOS Developing

## Swift Conventions

- Prefer value types (`struct`), `enum` with associated values, and protocols. Use `class` when reference semantics or inheritance are needed.
- Use `async/await` for async work; mark main-UI updates with `@MainActor` or `await MainActor.run { }`.
- Optionals: `if let`, `guard let`, `??`. Prefer `guard` for early exit. Use `Result` for fallible APIs when callers need the error.

## SwiftUI (iOS)

- Lifecycle: `@State` (owned), `@StateObject` for `ObservableObject`, `@ObservedObject` / `@EnvironmentObject` for injected. Use `@Binding` for two-way.
- Layout: `VStack`/`HStack`/`ZStack`, `Spacer`, `frame`, `padding`. Prefer `ScrollView` + `LazyVStack` for long lists.
- Lists: `List { }` or `ForEach` with identifiable data (`id: \.id` or `Identifiable`).
- Navigation: `NavigationStack` (iOS 16+) with `navigationDestination`; `NavigationLink` for pushes. Use `ToolbarItem` for bar buttons.
- Sheets: `.sheet(item:)` or `.sheet(isPresented:)`. Dismiss with `@Environment(\.dismiss)`.
- Safe area and keyboard: `safeAreaInset`; use `@FocusState` and optional keyboard avoidance (e.g. `ScrollView` + padding).

## UIKit (when needed)

- Use `UIViewController` lifecycle: `viewDidLoad`, `viewWillAppear`, etc. Prefer SwiftUI via `UIHostingController` for new UI when possible.
- Auto Layout: NSLayoutConstraint or SwiftUI. With UIKit, activate constraints and update in `updateViewConstraints` or layout callbacks.
- Table/collection: `UITableView`/`UICollectionView` with diffable data source (iOS 13+) when appropriate.

## Xcode & Project

- Targets: separate app target per platform (e.g. iOS vs macOS). Shared code in same module or SPM package.
- Info.plist / entitlements: Capabilities (e.g. Keychain, Push) and privacy usage strings (camera, mic, photo library).
- Minimum deployment: set in target; avoid APIs above that version without `@available` or `#if`.

## iOS-Specific

- **ScreenCaptureKit**: Available on macOS 12.3+; not available on iOS. For iOS screen capture use ReplayKit (`RPScreenRecorder` or `RPBroadcastSampleHandler`).
- **App lifecycle**: `@main` with `App` struct (SwiftUI) or `UIApplicationDelegate`. Handle background/foreground in `ScenePhase` or delegate.
- **Storage**: `UserDefaults`, `FileManager` (Documents, Caches), Keychain for secrets. Use security-scoped bookmarks on macOS for user-selected folders; iOS uses photo library / document picker as appropriate.

## Checklist for New Features

- [ ] Correct `@MainActor` / threading for UI updates
- [ ] Handle nil and errors; avoid force unwraps in production paths
- [ ] Respect safe area and size classes (compact/regular)
- [ ] Add privacy usage strings for camera, mic, photo library, etc., if used
