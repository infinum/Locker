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

    /**
     User defaults used for storing shouldUseAuthenticationWithBiometrics, askToUseAuthenticationWithBiometrics and shouldAddPasscodeToKeychainOnNextLogin values

     Should be set once before using any other Locker methods.
     If not set, standard user defaults will be used.
     */
    public static var userDefaults: UserDefaults? {
        get {
            return currentUserDefaults == nil ? UserDefaults.standard : currentUserDefaults
        }
        set {
            currentUserDefaults = newValue ?? .standard
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
    public static var enableDeviceListSync: Bool = false {
        didSet {
            guard enableDeviceListSync else { return }
            LockerHelpers.fetchNewDeviceList()
        }
    }

    // MARK: - Private properties

    private static var currentUserDefaults: UserDefaults?

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
        completed: ((LockerError?) -> Void)? = nil
    ) {
    #if targetEnvironment(simulator)
        Locker.userDefaults?.set(secret, forKey: uniqueIdentifier)
    #else
        setSecretForDevice(secret, for: uniqueIdentifier, completion: { error in
            completed?(error)
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
        success: ((String) -> Void)?,
        failure: ((OSStatus) -> Void)?
    ) {

    #if targetEnvironment(simulator)
        let simulatorSecret = Locker.userDefaults?.string(forKey: uniqueIdentifier)
        guard let simulatorSecret = simulatorSecret else {
            failure?(errSecItemNotFound)
            return
        }
        success?(simulatorSecret)
    #else
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier),
            kSecMatchLimit: kSecMatchLimitOne,
            kSecReturnData: true,
            kSecUseOperationPrompt: operationPrompt
        ]

        DispatchQueue.global(qos: .default).async {
            var dataTypeRef: CFTypeRef?

            let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
            if status == errSecSuccess {
                guard let resultData = dataTypeRef as? Data,
                      let result = String(data: resultData, encoding: .utf8) else {
                          failure?(errSecItemNotFound)
                          return
                      }

                DispatchQueue.main.async {
                    success?(result)
                }
            } else {
                failure?(status)
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
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)
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

// MARK: - Internal extension

extension Locker {
    static func setSecretForDevice(
        _ secret: String,
        for uniqueIdentifier: String,
        completion: ((LockerError?) -> Void)? = nil
    ) {
        let query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)
        ]

        DispatchQueue.global(qos: .default).async {
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
            let sacObject = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                flags,
                errorRef
            )

            guard let sacObject = sacObject, errorRef == nil, let secretData = secret.data(using: .utf8) else {
                if errorRef != nil {
                    completion?(.accessControl)
                } else {
                    completion?(.invalidData)
                }
                return
            }
            addSecItem(for: uniqueIdentifier, secretData, sacObject: sacObject, completion: completion)
        }
    }

    private static func addSecItem(
        for uniqueIdentifier: String,
        _ secretData: Data, sacObject: SecAccessControl,
        completion: ((LockerError?) -> Void)? = nil
    ) {
        let attributes: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount: LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier),
            kSecValueData: secretData,
            kSecUseAuthenticationUI: false,
            kSecAttrAccessControl: sacObject
        ]

        DispatchQueue.global(qos: .default).async {
            SecItemAdd(attributes as CFDictionary, nil)

            // Store current LA policy domain state
            LockerHelpers.storeCurrentLAPolicyDomainState()
            completion?(nil)
        }
    }
}
