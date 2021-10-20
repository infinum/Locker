//
//  LockerError.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//

import Foundation

public enum LockerError: Error {
    case accessControl(String), invalidData(String)
}
