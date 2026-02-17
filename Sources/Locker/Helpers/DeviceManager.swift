//
//  DeviceManager.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//

import Foundation

final class DeviceManager: Sendable {

    // MARK: - Singleton creation -

    static let shared = DeviceManager()

    private init() {}
}

// MARK: - Internal extension -

extension DeviceManager {

    /// Fetches the device list from the remote API using async/await URLSession.
    /// File writes remain thread-safe via BundleHelpers.fileLock.
    func fetchDevices() {
        guard let url = Constants.devicesURL else { return }
        Task.detached {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let path = BundleHelpers.getFileURL(
                    for: "BiometryAvailabilityDeviceList",
                    with: "json"
                ) else { return }
                BundleHelpers.write(data, to: path)
            } catch {
                // Network errors are silently ignored, matching previous behavior.
                // The local device list remains valid as a fallback.
            }
        }
    }

    func isDeviceInFaceIDList(device: String) -> Bool {
        let deviceResponse = readDataFromDevices()
        return deviceResponse?.faceIdDevices.contains { $0.id == device } ?? false
    }

    func isDeviceInTouchIDList(device: String) -> Bool {
        let deviceResponse = readDataFromDevices()
        return deviceResponse?.touchIdDevices.contains { $0.id == device } ?? false
    }
}

// MARK: - Private extension

private extension DeviceManager {

    func readDataFromDevices() -> DeviceResponse? {
        guard let data = BundleHelpers.readFromJSON("BiometryAvailabilityDeviceList") else {
            return nil
        }
        return try? BundleHelpers.decoder.decode(DeviceResponse.self, from: data)
    }
}
