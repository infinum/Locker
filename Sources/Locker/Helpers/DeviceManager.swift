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

// MARK: - Public extension -

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
        let deviceResponse = readDataFromDeviceList()
        return deviceResponse?.faceIdDevices.contains(device) ?? false
    }

    func isDeviceInTouchIDList(device: String) -> Bool {
        let deviceResponse = readDataFromDeviceList()
        return deviceResponse?.touchIdDevices.contains(device) ?? false
    }
}

// MARK: - Private extension

private extension DeviceManager {

    func readDataFromDeviceList() -> DeviceResponse? {
        guard let data = BundleHelpers.readFromJSON("BiometryAvailabilityDeviceList") else {
            return nil
        }
        return try? BundleHelpers.decoder.decode(DeviceResponse.self, from: data)
    }
}
