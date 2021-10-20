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
            guard let data = data, error == nil else {
                return
            }
            do {
                let deviceList = try JSONDecoder().decode(DeviceResponse.self, from: data).devices
                deviceList.contains(LockerHelpers.deviceCode)
            } catch {
            }
        }.resume()
    }
}
