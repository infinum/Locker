//
//  LockerError.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//

import Foundation

@objc
public enum LockerError: Int, Error {
    /// Access control couldn't be initialized while trying to save the secret
    case accessControl = -99
    /// Conversion from secret to data failed
    case invalidData = -72

    /// NSError representation used in Obj-C methods
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
