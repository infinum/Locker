//
//  Locker.swift
//  Locker
//
//  Created by Zvonimir Medak on 19.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation
import UIKit

@objcMembers
public class Locker: NSObject {

    // MARK: - Public properties

    /// Shared state container (thread-safe, Sendable).
    private static let state = LockerState.shared

    /**
     User defaults used for storing shouldUseAuthenticationWithBiometrics, askToUseAuthenticationWithBiometrics and shouldAddPasscodeToKeychainOnNextLogin values

     Should be set once before using any other Locker methods.
     If not set, standard user defaults will be used.

     All Locker internal storage (keychain service override, LA policy domain state,
     boolean flags) uses this same UserDefaults instance, ensuring no divergence
     when a custom suite is configured.
     */
    public static var userDefaults: UserDefaults? {
        get {
            state.userDefaults
        }
        set {
            if let newValue = newValue {
                state.userDefaults = newValue
            } else {
                state.resetUserDefaults()
            }
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
            state.enableDeviceListSync
        }
        set {
            let (shouldFetch, _) = state.setEnableDeviceListSync(newValue)
            if shouldFetch {
                LockerHelpers.fetchNewDeviceList()
            }
        }
    }

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
        Task.detached {
            let error = await KeychainHelper.storeSecret(secret, for: uniqueIdentifier)
            DispatchQueue.main.async {
                completed?(error)
            }
        }
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
        Task.detached {
            let result = await KeychainHelper.retrieveSecret(
                for: uniqueIdentifier,
                operationPrompt: operationPrompt
            )
            DispatchQueue.main.async {
                switch result {
                case .success(let secret):
                    success?(secret)
                case .failure(let status):
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
        Task.detached {
            await KeychainHelper.deleteSecret(for: uniqueIdentifier)
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
    #if targetEnvironment(simulator)
        Locker.userDefaults?.set(secret, forKey: uniqueIdentifier)
    #else
        let error = await KeychainHelper.storeSecret(secret, for: uniqueIdentifier)
        if let error = error {
            throw error
        }
    #endif
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
    #if targetEnvironment(simulator)
        guard let secret = Locker.userDefaults?.string(forKey: uniqueIdentifier) else {
            throw RetrievalError.notFound
        }
        return secret
    #else
        let result = await KeychainHelper.retrieveSecret(
            for: uniqueIdentifier,
            operationPrompt: operationPrompt
        )
        switch result {
        case .success(let secret):
            return secret
        case .failure(let status):
            if status == errSecItemNotFound {
                throw RetrievalError.notFound
            } else {
                throw RetrievalError.keychainError(status)
            }
        }
    #endif
    }

    /**
     Deletes a secret from the Keychain.

     This is the async version of `deleteSecret(for:)` that ensures the operation
     completes on a background thread.

     - Parameter uniqueIdentifier: The unique key of the secret to delete
     */
    static func deleteSecret(for uniqueIdentifier: String) async {
    #if targetEnvironment(simulator)
        Locker.userDefaults?.removeObject(forKey: uniqueIdentifier)
    #else
        await KeychainHelper.deleteSecret(for: uniqueIdentifier)
    #endif
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
