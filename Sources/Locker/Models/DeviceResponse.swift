//
//  DeviceResponse.swift
//  Locker
//
//  Created by Zvonimir Medak on 21.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation

struct DeviceResponse: Codable {
    let faceIdDevices: [String]
    let touchIdDevices: [String]
}
