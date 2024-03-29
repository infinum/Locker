//
//  DeviceManager.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//

import Foundation

class DeviceManager {

    // MARK: - Singleton creation -

    static let shared = DeviceManager()

    private init() {}
}

// MARK: - Internal extension -

extension DeviceManager {

    func fetchDevices() {
        guard let url = Constants.devicesURL else { return }
        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data,
                  error == nil,
                  let path = BundleHelpers.getFileURL(for: "BiometryAvailabilityDeviceList", with: "json")
            else { return }
            BundleHelpers.write(data, to: path)
        }.resume()
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
