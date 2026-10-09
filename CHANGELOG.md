# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - 2026-10-09

### Added

- Support for new devices:
  - iPhone 18 Pro (`iPhone19,2`) — Face ID
  - iPhone 18 Pro Max (`iPhone19,3`, `iPhone19,7`) — Face ID
  - iPhone Duo (`iPhone19,4`) — Touch ID

### Fixed

- Biometry device list now loads when Locker is built with Swift Package Manager
  outside an app bundle (e.g. `swift test`). The resource bundle is resolved via
  `Bundle.module` under SPM; CocoaPods lookup is unchanged.

## [3.1.0] - 2026-06-26

### Changed

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
