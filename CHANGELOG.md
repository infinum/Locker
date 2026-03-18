# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [4.0.0] - Unreleased

### Breaking Changes

- **Minimum iOS deployment target raised from iOS 10.0 to iOS 12.0.**
  Consumers targeting iOS 10 or iOS 11 must remain on Locker 3.x.
  This change is required to support Swift 6 strict-concurrency toolchain
  requirements and to drop now-unsupported `#available` workarounds for
  APIs that became unconditional on iOS 12+.

### Changed

- Bumped SwiftPM tools version to 5.9.
- Bumped CocoaPods `swift_version` to 5.10 (requires Xcode 15.3+).
- Removed unused `import UIKit` from `Locker.swift`.
- Replaced iOS-only `#available(iOS 11.0, *)` guards with dual-platform
  guards (`#available(iOS 11.0, macOS 10.13, *)`) for macOS compatibility.
- Removed `UIKit` from `Locker.podspec` frameworks (it was never needed).

## [3.0.6] - 2024-03-01

- Minor fixes.

## [3.0.5] - 2024-02-01

- Minor fixes.
