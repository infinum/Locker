# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [3.1.0] - Unreleased (to be tagged in a dedicated release PR after all Swift 6 migration chunks are merged)

### Changed

- Bumped minimum iOS deployment target from iOS 10.0 to iOS 12.0.
  All public API interfaces remain unchanged — this is a toolchain/platform
  requirement for Swift 6 readiness. Consumers targeting iOS 10 or iOS 11
  must remain on Locker 3.0.x.
- Bumped SwiftPM tools version to 5.9.
- Bumped CocoaPods `swift_version` to 5.10 (requires Xcode 15.3+).
- Removed unused `import UIKit` from `Locker.swift`.
- Replaced iOS-only `#available(iOS 11.0, *)` guards with dual-platform
  guards (`#available(iOS 11.0, macOS 10.13, *)`) for macOS compatibility.

## [3.0.6] - 2024-03-01

- Minor fixes.

## [3.0.5] - 2024-02-01

- Minor fixes.
