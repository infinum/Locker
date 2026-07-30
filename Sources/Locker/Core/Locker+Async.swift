//
//  Locker+Async.swift
//  Locker
//

import Foundation

// Swift concurrency back deploys to iOS 13 / macOS 10.15, so the async API is
// gated rather than raising the package's iOS 12.0 minimum.
@available(iOS 13.0, macOS 10.15, *)
public extension Locker {

    /**
     Used for storing value to Keychain with unique identifier.

     If Locker is run on the Simulator, the secret will not be stored securely in the keychain.
     Instead, the UserDefaults storage will be used.

     - Parameters:
        - secret: value to store to Keychain
        - uniqueIdentifier: unique key used for storing secret
     - Throws: `LockerError` if the secret could not be stored
     */
    static func setSecret(_ secret: String, for uniqueIdentifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Locker.setSecret(secret, for: uniqueIdentifier) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /**
     Used for retrieving secret from Keychain with unique identifier.

     - Parameters:
        - uniqueIdentifier: unique key used for fetching secret
        - operationPrompt: message shown to the user on TouchID dialog
     - Returns: the stored secret
     - Throws: `KeychainError` carrying the failure `OSStatus`
     */
    static func retrieveCurrentSecret(
        for uniqueIdentifier: String,
        operationPrompt: String
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            Locker.retrieveCurrentSecret(
                for: uniqueIdentifier,
                operationPrompt: operationPrompt,
                success: { continuation.resume(returning: $0) },
                failure: { continuation.resume(throwing: KeychainError(status: $0)) }
            )
        }
    }
}
