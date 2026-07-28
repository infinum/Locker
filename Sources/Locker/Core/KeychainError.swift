//
//  KeychainError.swift
//  Locker
//

import Foundation

/// Wraps the `OSStatus` reported when a Keychain operation fails.
public struct KeychainError: Error, Equatable {

    /// The `OSStatus` returned by the underlying Security framework call.
    public let status: OSStatus

    public init(status: OSStatus) {
        self.status = status
    }
}

// MARK: - Public extension -

extension KeychainError: LocalizedError {

    public var errorDescription: String? {
        "Keychain operation failed with status: \(status)"
    }
}
