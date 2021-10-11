//
//  File.swift
//  
//
//  Created by Zvonimir Medak on 08.10.2021..
//

import Foundation

class DeviceList {
    static let shared = DeviceList()

    private(set) var api: URL = Constants.Apiary.deviceList

    private init() {}
}
