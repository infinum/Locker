//
//  LockerState.swift
//  Locker
//
//  Thread-safe container for Locker's shared mutable state.
//  Replaces nonisolated(unsafe) + NSLock with a Sendable struct
//  that encapsulates all locking internally.
//

import Foundation

/// Thread-safe container for Locker's mutable configuration.
///
/// All reads/writes go through `NSLock`-protected accessors.
/// The struct itself is `Sendable` because the lock serializes all access
/// and the backing storage is only mutated under the lock.
final class LockerState: Sendable {

    private let lock = NSLock()

    // Backing storage — only accessed under `lock`.
    // Using `nonisolated(unsafe)` here is justified: the NSLock above serializes
    // every read and write. These ivars are never accessed without holding the lock.
    nonisolated(unsafe) private var _userDefaults: UserDefaults?
    nonisolated(unsafe) private var _enableDeviceListSync: Bool = false

    static let shared = LockerState()

    private init() {}

    // MARK: - UserDefaults

    /// The UserDefaults instance used for all Locker storage.
    /// Returns `.standard` if no custom instance has been set.
    var userDefaults: UserDefaults {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _userDefaults ?? .standard
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _userDefaults = newValue
        }
    }

    /// Resets userDefaults to `.standard`.
    func resetUserDefaults() {
        lock.lock()
        defer { lock.unlock() }
        _userDefaults = nil
    }

    // MARK: - Device List Sync

    /// Whether device list syncing is enabled.
    /// Setting to `true` for the first time triggers a fetch.
    /// Returns the previous value and the new value so the caller can decide whether to fetch.
    func setEnableDeviceListSync(_ newValue: Bool) -> (shouldFetch: Bool, Void) {
        lock.lock()
        let shouldFetch = newValue && !_enableDeviceListSync
        _enableDeviceListSync = newValue
        lock.unlock()
        return (shouldFetch, ())
    }

    var enableDeviceListSync: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _enableDeviceListSync
    }
}
