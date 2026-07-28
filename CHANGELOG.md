# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2026-07-28

### Added

- `async`/`await` variants of `Locker.setSecret(_:for:)` and
  `Locker.retrieveCurrentSecret(for:operationPrompt:)`. Swift concurrency back
  deploys to iOS 13, so these are annotated `@available(iOS 13.0, macOS 10.15, *)`
  and the library's iOS 12.0 minimum is unchanged. The async read throws the new
  public `KeychainError`, which carries the failing `OSStatus`; the async write
  throws the existing `LockerError`. The completion handler APIs are unchanged.

### Fixed

- `Locker.setSecret(_:for:completed:)` now invokes its completion block when
  running on the simulator. Previously the simulator code path stored the secret
  and returned without calling back, so callers waiting on the completion were
  never notified.

### Changed

- Converted the `Example/` app (`TouchID`) to SwiftUI: the `UIViewController` +
  `Main.storyboard` UI is replaced by the SwiftUI `App` lifecycle
  (`@main struct TouchIDApp: App`), an `@Observable` view model, and `async`/`await`
  call sites, and its unit tests are migrated to Swift Testing. The example app's
  deployment target is now iOS 17.0 — this is a demo app only requirement and does
  **not** change the library's supported minimum, which remains iOS 12.0.
- Bumped minimum iOS deployment target from iOS 10.0 to iOS 12.0.
  All public API interfaces remain unchanged — this is a toolchain/platform
  requirement for Swift 6 readiness. Consumers targeting iOS 10 or iOS 11
  must remain on Locker 3.0.x.
- Bumped SwiftPM `swift-tools-version` to 6.0 (requires a Swift 6 toolchain;
  Xcode 26 is the minimum version supported by this library going forward).
  Removed the temporary `swiftLanguageModes: [.v5]` override and enabled
  strict concurrency checking via `.enableUpcomingFeature("StrictConcurrency")`.
- Podspec `s.swift_version` set to `"5.0"` — this is a Swift language mode
  setting (CocoaPods maps it to the `SWIFT_VERSION` build setting). The Xcode 26
  minimum requirement is documented in the README.
- Removed unused `import UIKit` from `Locker.swift`.
- Replaced iOS-only `#available` guards with dual-platform variants for macOS
  compatibility:
  - `#available(iOS 11.3, macOS 10.13.4, *)` — keychain `SecAccessControl` guard
  - `#available(iOS 11.0, macOS 10.13, *)` — `LABiometryType` availability guard
  - `#available(iOS 11.0, macOS 10.15, *)` — `.faceID` / `.biometryType` guard

## [3.0.6] - 2024-03-01

- Minor fixes.

## [3.0.5] - 2024-02-01

- Minor fixes.
