//
//  Constants.swift
//  
//
//  Created by Zvonimir Medak on 08.10.2021..
//

import Foundation

enum Constants {
    enum Apiary {
        static let base = URL(string: "https://private-7d1e4-lockerdevices.apiary-mock.com")!
        static let deviceList = base.appendingPathComponent("/devices")
    }
}
