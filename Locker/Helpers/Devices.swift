//
//  Devices.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//

import Foundation

class Devices {
    static let shared = Devices()

    private(set) var devicesURL: URL? = Constants.devicesURL

    private init() {}

    func fetchDevices() {
        guard let devicesURL = devicesURL else {
            return
        }
        URLSession.shared.dataTask(with: devicesURL) { data, _, error in
            guard let data = data, error == nil,
                  let urlPath = BundleHelpers.bundleResource?
                    .url(forResource: "devices", withExtension: "json") else { return }
            BundleHelpers.write(data, to: urlPath)
        }.resume()
    }

    func isDeviceInFaceIDList(device: String) -> Bool {
        let deviceResponse = readDataFromDevices()
        return deviceResponse?.faceIdDevices.contains(device) ?? false
    }

    func isDeviceInTouchIDList(device: String) -> Bool {
        let deviceResponse = readDataFromDevices()
        return deviceResponse?.touchIdDevices.contains(device) ?? false
    }
}

private extension Devices {

    func readDataFromDevices() -> DeviceResponse? {
        guard let data = BundleHelpers.readFromJSON("devices") else {
            return nil
        }
        let deviceResponse: DeviceResponse? = BundleHelpers.parse(jsonData: data)
        return deviceResponse
    }
}
