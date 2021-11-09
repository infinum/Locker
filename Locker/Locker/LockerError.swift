//
//  LockerError.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//

import Foundation

@objc
public enum LockerError: Int, Error {
    case accessControl = -99
    case invalidData = -72

    var asNSError: NSError {
        convertToNSError()
    }
}

// MARK: - Public extension -

extension LockerError: LocalizedError {

    public var errorDescription: String? {
        switch self {
        case .accessControl:
            return "Unable to initialize access control"
        case .invalidData:
            return "Invalid storing data"
        }
    }
}

// MARK: - Private extension -

private extension LockerError {
    func convertToNSError() -> NSError {
        return NSError(
            domain: "com.infinum.locker",
            code: self.rawValue,
            userInfo: ["NSLocalizedDescriptionKey": self.errorDescription ?? "Something went wrong"]
        )

    }
}
