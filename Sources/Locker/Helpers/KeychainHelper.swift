//
//  KeychainHelper.swift
//  Locker
//
//  Internal async helpers for Keychain operations.
//  All Security framework calls run off the main executor via Task.detached,
//  providing a single structured-concurrency implementation path.
//

import Foundation
import Security

/// Internal helper that centralizes all Keychain read/write/delete operations
/// behind async functions. Legacy completion-based APIs in `Locker` call these
/// via `Task.detached` and deliver results back on `DispatchQueue.main`.
enum KeychainHelper: Sendable {

    /// Result of a keychain retrieval: either the secret string or an OSStatus error code.
    enum RetrievalResult: Sendable {
        case success(String)
        case failure(OSStatus)
    }

    // MARK: - Store

    /// Stores a secret in the Keychain with biometric protection.
    /// Runs the Security framework calls on a detached task to avoid blocking the caller.
    ///
    /// - Returns: `nil` on success, or a `LockerError` on failure.
    static func storeSecret(
        _ secret: String,
        for uniqueIdentifier: String
    ) async -> LockerError? {
        let serviceName = LockerHelpers.keyKeychainServiceName
        let accountName = LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)

        return await withCheckedContinuation { continuation in
            // Run Security framework calls off the cooperative pool on a background queue,
            // since SecItemAdd/Delete can block waiting for hardware.
            DispatchQueue.global(qos: .default).async {
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: accountName
                ]
                // Delete any existing item first
                SecItemDelete(deleteQuery as CFDictionary)

                // Create access control
                let errorRef: UnsafeMutablePointer<Unmanaged<CFError>?>? = nil
                let flags: SecAccessControlCreateFlags = .biometryCurrentSet

                let sac = SecAccessControlCreateWithFlags(
                    kCFAllocatorDefault,
                    kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                    flags,
                    errorRef
                )

                guard let sacObject = sac, errorRef == nil,
                      let secretData = secret.data(using: .utf8) else {
                    if errorRef != nil {
                        continuation.resume(returning: .accessControl)
                    } else {
                        continuation.resume(returning: .invalidData)
                    }
                    return
                }

                // Add the item
                let attributes: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: accountName,
                    kSecValueData as String: secretData,
                    kSecUseAuthenticationUI as String: false,
                    kSecAttrAccessControl as String: sacObject
                ]
                SecItemAdd(attributes as CFDictionary, nil)

                // Store current LA policy domain state
                LockerHelpers.storeCurrentLAPolicyDomainState()

                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Retrieve

    /// Retrieves a secret from the Keychain using biometric authentication.
    /// Runs the Security framework call on a background queue since `SecItemCopyMatching`
    /// may block while the biometric prompt is displayed.
    static func retrieveSecret(
        for uniqueIdentifier: String,
        operationPrompt: String
    ) async -> RetrievalResult {
        let serviceName = LockerHelpers.keyKeychainServiceName
        let accountName = LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .default).async {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: accountName,
                    kSecMatchLimit as String: kSecMatchLimitOne,
                    kSecReturnData as String: true,
                    kSecUseOperationPrompt as String: operationPrompt
                ]

                var dataTypeRef: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

                if status == errSecSuccess {
                    guard let resultData = dataTypeRef as? Data,
                          let result = String(data: resultData, encoding: .utf8) else {
                        continuation.resume(returning: .failure(errSecItemNotFound))
                        return
                    }
                    continuation.resume(returning: .success(result))
                } else {
                    continuation.resume(returning: .failure(status))
                }
            }
        }
    }

    // MARK: - Delete

    /// Deletes a secret from the Keychain.
    static func deleteSecret(for uniqueIdentifier: String) async {
        let serviceName = LockerHelpers.keyKeychainServiceName
        let accountName = LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .default).async {
                let query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: serviceName,
                    kSecAttrAccount as String: accountName
                ]
                SecItemDelete(query as CFDictionary)
                continuation.resume()
            }
        }
    }
}
