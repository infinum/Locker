//
//  Locker.swift
//  Locker
//
//  Created by Zvonimir Medak on 19.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

@preconcurrency import Foundation
import UIKit

@objcMembers
public class Locker: NSObject {

    // MARK: - Public properties

    /// Lock for thread-safe access to mutable state
    private static let lock = NSLock()

    /**
     User defaults used for storing shouldUseAuthenticationWithBiometrics, askToUseAuthenticationWithBiometrics and shouldAddPasscodeToKeychainOnNextLogin values

     Should be set once before using any other Locker methods.
     If not set, standard user defaults will be used.
     */
    public static var userDefaults: UserDefaults? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _currentUserDefaults == nil ? UserDefaults.standard : _currentUserDefaults
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _currentUserDefaults = newValue ?? .standard
        }
    }

    /**
     Boolean value that indicates if biometric settings have changed
     */
    public static var biometricsSettingsDidChange: Bool {
        LockerHelpers.biometricsSettingsChanged
    }

    /**
     Boolean value that indicates if Locker is running from the simulator

     As Simulator does not support Keychain storage, Locker run from the simulator
     will use UserDefaults storage instead.
     */
    public static var isRunningFromTheSimulator: Bool {
    #if targetEnvironment(simulator)
        return true
    #else
        return false
    #endif
    }

    /**
     The biometrics type that the device supports (None, TouchID, FaceID).
     */
    public static var supportedBiometricsAuthentication: BiometricsType {
        LockerHelpers.supportedBiometricAuthentication
    }

    /**
     The biometrics type that the device supports which is enabled and configured in the device settings.
     */
    public static var configuredBiometricsAuthentication: BiometricsType {
        LockerHelpers.configuredBiometricsAuthentication
    }

    /**
     Boolean value that indicates if Locker should sync its local JSON device list with the API

     If the sync is enabled, Locker will check if the device is already contained in the list. If the
     device is not found in the local list, Locker will updated the local JSON device list.

     If you're using a simulator Locker will not sync the list.
     */
    public static var enableDeviceListSync: Bool {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _enableDeviceListSync
        }
        set {
            lock.lock()
            let shouldFetch = newValue && !_enableDeviceListSync
            _enableDeviceListSync = newValue
            lock.unlock()
            if shouldFetch {
                LockerHelpers.fetchNewDeviceList()
            }
        }
    }

    // MARK: - Private properties

    /// Backing storage for enableDeviceListSync - access only through the lock-protected computed property
    nonisolated(unsafe) private static var _enableDeviceListSync: Bool = false
    /// Backing storage for currentUserDefaults - access only through the lock-protected computed property
    nonisolated(unsafe) private static var _currentUserDefaults: UserDefaults?

    // MARK: - Handle secrets (store, delete, fetch)

    /**
     Used for storing value to Keychain with unique identifier.

     If Locker is run on the Simulator, the secret will not be stored securely in the keychain.
     Instead, the UserDefaults storage will be used.

     - Parameters:
        - secret: value to store to Keychain
        - uniqueIdentifier: unique key used for storing secret
        - completed: completion block returning an error if something went wrong
     */
    public static func setSecret(
        _ secret: String,
        for uniqueIdentifier: String,
        completed: (@Sendable (LockerError?) -> Void)? = nil
    ) {
    #if targetEnvironment(simulator)
        Locker.userDefaults?.set(secret, forKey: uniqueIdentifier)
    #else
        setSecretForDevice(secret, for: uniqueIdentifier, completion: { error in
            DispatchQueue.main.async {
                completed?(error)
            }
        })
    #endif
    }

    /**
     Used for retrieving secret from Keychain with unique identifier.
     If operation is successfull, secret is returned. Otherwise, failure status is returned.

     - Parameters:
        - uniqueIdentifier: unique key used for fetching secret
        - operationPrompt: message showed to the user on TouchID dialog
        - success: completion block returning secret
        - failure: failure block returning failure status
     */
    @objc(retreiveCurrentSecretForUniqueIdentifier:operationPrompt:success:failure:)
    public static func retrieveCurrentSecret(
        for uniqueIdentifier: String,
        operationPrompt: String,
        success: (@Sendable (String) -> Void)?,
        failure: (@Sendable (OSStatus) -> Void)?
    ) {

    #if targetEnvironment(simulator)
        let simulatorSecret = Locker.userDefaults?.string(forKey: uniqueIdentifier)
        guard let simulatorSecret = simulatorSecret else {
            DispatchQueue.main.async {
                failure?(errSecItemNotFound)
            }
            return
        }
        DispatchQueue.main.async {
            success?(simulatorSecret)
        }
    #else
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount as String: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier),
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true,
            kSecUseOperationPrompt as String: operationPrompt
        ]

        DispatchQueue.global(qos: .default).async {
            var dataTypeRef: CFTypeRef?

            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            if status == errSecSuccess {
                guard let resultData = dataTypeRef as? Data,
                      let result = String(data: resultData, encoding: .utf8) else {
                          DispatchQueue.main.async {
                              failure?(errSecItemNotFound)
                          }
                          return
                      }

                DispatchQueue.main.async {
                    success?(result)
                }
            } else {
                DispatchQueue.main.async {
                    failure?(status)
                }
            }
        }
    #endif
    }

    /**
     Used for deleting secret from Keychain with unique identifier.

     - Parameter uniqueIdentifier: unique key used for deleting secret
     */
    @objc(deleteSecretForUniqueIdentifier:)
    public static func deleteSecret(for uniqueIdentifier: String) {

    #if targetEnvironment(simulator)
        Locker.userDefaults?.removeObject(forKey: uniqueIdentifier)
    #else
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount as String: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)
        ]

        DispatchQueue.global(qos: .default).async {
            SecItemDelete(query as CFDictionary)
        }
    #endif
    }
}

// MARK: - Additional helpers

public extension Locker {
    
    /**
     Used for setting a custom keychain service key. 
     
     If this is not set, Locker will use a combination of the bundle identifier and a string constant to set the keychain service.

     - Parameter service: the custom keychain service key you want to use to interact with the Keychain
     */
    @objc(setKeychainService:)
    static func setKeychainService(_ service: String) {
        Locker.userDefaults?.set(service, forKey: LockerHelpers.keyCustomKeychainService)
    }

    /**
     Used for fetching whether user enabled authentication with biometrics.

     - Parameter uniqueIdentifier: used for fetching shouldUseAuthenticationWithBiometrics value

     - Returns: used to determine whether user enabled authentication with biometrics
     */
    @objc(shouldUseAuthenticationWithBiometricsForUniqueIdentifier:)
    static func shouldUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool {
        return Locker.userDefaults?.bool(
            forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier)
        ) ?? false
    }

    /**
     Used for saving whether user enabled authentication with biometrics.

     - Parameters:
        - shouldUse: used to determine whether user enabled authentication with biometrics
        - uniqueIdentifier: used for saving shouldUseAuthenticationWithBiometrics value
     */
    @objc(setShouldUseAuthenticationWithBiometrics:forUniqueIdentifier:)
    static func setShouldUseAuthenticationWithBiometrics(_ shouldUse: Bool, for uniqueIdentifier: String) {
        if !shouldUse && Locker.shouldAddSecretToKeychainOnNextLogin(for: uniqueIdentifier) {
            Locker.setShouldAddSecretToKeychainOnNextLogin(false, for: uniqueIdentifier)
        }
        Locker.userDefaults?.set(
            shouldUse,
            forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier)
        )
    }

    /**
     Used for fetching whether user was asked to use authentication with biometrics.

     - Parameter uniqueIdentifier: used for fetching askToUseAuthenticationWithBiometrics value

     - Returns: used to determine whether user was asked to use authentication with biometrics
     */
    @objc(didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:)
    static func didAskToUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool {
        Locker.userDefaults?.bool(
            forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier)
        ) ?? false
    }

    /**
     Used for saving whether user was asked to use authentication with
     - Parameters:
        - useAuthenticationBiometrics: used to determine whether user was asked to use authentication with biometrics
        - uniqueIdentifier: used for saving askToUseAuthenticationWithBiometrics value
     */
    @objc(setDidAskToUseAuthenticationWithBiometrics:forUniqueIdentifier:)
    static func setDidAskToUseAuthenticationWithBiometrics(
        _ useAuthenticationBiometrics: Bool,
        for uniqueIdentifier: String
    ) {
        Locker.userDefaults?.set(
            useAuthenticationBiometrics,
            forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier)
        )
    }

    /**
     Used for fetching whether secret should be stored to Keychain on next login.

     - Parameter uniqueIdentifier: used for fetching shouldAddSecretToKeychainOnNextLogin value

     - Returns: used to determine whether secret should be stored to Keychain on next login
     */
    @objc(shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:)
    static func shouldAddSecretToKeychainOnNextLogin(for uniqueIdentifier: String) -> Bool {
        Locker.userDefaults?.bool(
            forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier)
        ) ?? false
    }

    /**
     Used for saving whether secret should be stored to Keychain on next login.

     - Parameters:
        - shouldAdd: used to determine whether secret should be stored to Keychain on next login
        - uniqueIdentifier: used for saving shouldAddSecretToKeychainOnNextLogin value
     */
    @objc(setShouldAddSecretToKeychainOnNextLogin:forUniqueIdentifier:)
    static func setShouldAddSecretToKeychainOnNextLogin(_ shouldAdd: Bool, for uniqueIdentifier: String) {
        Locker.userDefaults?.set(
            shouldAdd,
            forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier)
        )
    }
}

// MARK: - Data reset

public extension Locker {

    /**
     Used for deleting all stored data for unique identifier.

     - Parameter uniqueIdentifier: unique key used for deleting all stored data
    */
    @objc(resetForUniqueIdentifier:)
    static func reset(for uniqueIdentifier: String) {
        Locker.userDefaults?.removeObject(
            forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier)
        )
        Locker.userDefaults?.removeObject(
            forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier)
        )
        Locker.userDefaults?.removeObject(
            forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier)
        )
        Locker.deleteSecret(for: uniqueIdentifier)
    }
}

// MARK: - Async/Await API (Swift 6)

@available(iOS 13.0, *)
public extension Locker {

    /// Error thrown when retrieving a secret fails
    enum RetrievalError: Error, Sendable {
        /// The secret was not found in the keychain
        case notFound
        /// The keychain operation failed with the given status
        case keychainError(OSStatus)
        /// The retrieved data could not be decoded as a string
        case invalidData
    }

    /**
     Stores a secret in the Keychain with biometric protection.

     This is the async/await version of `setSecret(_:for:completed:)`.

     - Parameters:
        - secret: The secret string to store
        - uniqueIdentifier: A unique key to identify the secret

     - Throws: `LockerError` if the operation fails
     */
    static func setSecret(_ secret: String, for uniqueIdentifier: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            setSecret(secret, for: uniqueIdentifier) { error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /**
     Retrieves a secret from the Keychain using biometric authentication.

     This is the async/await version of `retrieveCurrentSecret(for:operationPrompt:success:failure:)`.

     - Parameters:
        - uniqueIdentifier: The unique key used when storing the secret
        - operationPrompt: The message shown to the user during biometric authentication

     - Returns: The stored secret string

     - Throws: `RetrievalError` if the secret cannot be retrieved
     */
    static func retrieveCurrentSecret(
        for uniqueIdentifier: String,
        operationPrompt: String
    ) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            retrieveCurrentSecret(
                for: uniqueIdentifier,
                operationPrompt: operationPrompt,
                success: { secret in
                    continuation.resume(returning: secret)
                },
                failure: { status in
                    if status == errSecItemNotFound {
                        continuation.resume(throwing: RetrievalError.notFound)
                    } else {
                        continuation.resume(throwing: RetrievalError.keychainError(status))
                    }
                }
            )
        }
    }

    /**
     Deletes a secret from the Keychain.

     This is the async version of `deleteSecret(for:)` that ensures the operation
     completes on a background thread.

     - Parameter uniqueIdentifier: The unique key of the secret to delete
     */
    static func deleteSecret(for uniqueIdentifier: String) async {
        await withCheckedContinuation { continuation in
            #if targetEnvironment(simulator)
            Locker.userDefaults?.removeObject(forKey: uniqueIdentifier)
            continuation.resume()
            #else
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: LockerHelpers.keyKeychainServiceName,
                kSecAttrAccount as String: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)
            ]

            DispatchQueue.global(qos: .default).async {
                SecItemDelete(query as CFDictionary)
                continuation.resume()
            }
            #endif
        }
    }

    /**
     Resets all stored data for a unique identifier.

     This is the async version of `reset(for:)`.

     - Parameter uniqueIdentifier: The unique key for which to delete all stored data
     */
    static func reset(for uniqueIdentifier: String) async {
        Locker.userDefaults?.removeObject(
            forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier)
        )
        Locker.userDefaults?.removeObject(
            forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier)
        )
        Locker.userDefaults?.removeObject(
            forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier)
        )
        await deleteSecret(for: uniqueIdentifier)
    }
}

// MARK: - MainActor isolated callbacks (Swift 6)

@available(iOS 13.0, *)
public extension Locker {

    /**
     Stores a secret in the Keychain with a MainActor-isolated completion handler.

     Use this when you need to update UI directly in the completion handler.

     - Parameters:
        - secret: The secret string to store
        - uniqueIdentifier: A unique key to identify the secret
        - completed: A MainActor-isolated completion handler called with any error
     */
    @MainActor
    static func setSecret(
        _ secret: String,
        for uniqueIdentifier: String,
        onMainActor completed: (@MainActor @Sendable (LockerError?) -> Void)?
    ) {
        setSecret(secret, for: uniqueIdentifier) { error in
            Task { @MainActor in
                completed?(error)
            }
        }
    }

    /**
     Retrieves a secret from the Keychain with MainActor-isolated callbacks.

     Use this when you need to update UI directly in the success/failure handlers.

     - Parameters:
        - uniqueIdentifier: The unique key used when storing the secret
        - operationPrompt: The message shown to the user during biometric authentication
        - success: A MainActor-isolated handler called with the retrieved secret
        - failure: A MainActor-isolated handler called with the error status
     */
    @MainActor
    static func retrieveCurrentSecret(
        for uniqueIdentifier: String,
        operationPrompt: String,
        onMainActorSuccess success: (@MainActor @Sendable (String) -> Void)?,
        onMainActorFailure failure: (@MainActor @Sendable (OSStatus) -> Void)?
    ) {
        retrieveCurrentSecret(
            for: uniqueIdentifier,
            operationPrompt: operationPrompt,
            success: { secret in
                Task { @MainActor in
                    success?(secret)
                }
            },
            failure: { status in
                Task { @MainActor in
                    failure?(status)
                }
            }
        )
    }
}

// MARK: - Internal extension

extension Locker {
    static func setSecretForDevice(
        _ secret: String,
        for uniqueIdentifier: String,
        completion: (@Sendable (LockerError?) -> Void)? = nil
    ) {
        let serviceName = LockerHelpers.keyKeychainServiceName
        let accountName = LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)

        DispatchQueue.global(qos: .default).async {
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: accountName
            ]
            // First delete the previous item if it exists
            SecItemDelete(query as CFDictionary)

            // Then store it
            let errorRef: UnsafeMutablePointer<Unmanaged<CFError>?>? = nil
            var flags: SecAccessControlCreateFlags
            if #available(iOS 11.3, *) {
                flags = .biometryCurrentSet
            } else {
                flags = .touchIDCurrentSet
            }
            let sac = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                flags,
                errorRef
            )

            guard let sacObject = sac, errorRef == nil, let secretData = secret.data(using: .utf8) else {
                if errorRef != nil {
                    DispatchQueue.main.async {
                        completion?(.accessControl)
                    }
                } else {
                    DispatchQueue.main.async {
                        completion?(.invalidData)
                    }
                }
                return
            }
            addSecItem(for: uniqueIdentifier, secretData, sacObject: sacObject, completion: completion)
        }
    }

    private static func addSecItem(
        for uniqueIdentifier: String,
        _ secretData: Data, sacObject: SecAccessControl,
        completion: (@Sendable (LockerError?) -> Void)? = nil
    ) {
        let serviceName = LockerHelpers.keyKeychainServiceName
        let accountName = LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)

        DispatchQueue.global(qos: .default).async {
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
            DispatchQueue.main.async {
                completion?(nil)
            }
        }
    }
}
