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
public class Locker {

    // MARK: - Public properties

    public static var userDefaults: UserDefaults {
        get {
            return currentUserDefaults ?? .standard
        }
        set {
            currentUserDefaults = newValue
        }
    }

    public static var biometricsSettingsDidChange: Bool {
        LockerHelpers.biometricsSettingsChanged
    }

    public static var isRunningFromTheSimulator: Bool {
#if targetEnvironment(simulator)
        return true
#else
        return false
#endif
    }

    public static var deviceSupportsAuthenticationWithBiometrics: BiometricsType {
        LockerHelpers.deviceSupportsAuthenticationWithBiometrics
    }

    public static var configuredBiometricsAuthentication: BiometricsType {
        LockerHelpers.configuredBiometricsAuthentication
    }

    // MARK: - Private properties

    private static var currentUserDefaults: UserDefaults?

    // MARK: - Handle secrets (store, delete, fetch)

    public static func setSecret(_ secret: String, forUniqueIdentifier: String) {
    #if targetEnvironment(simulator)
        Locker.userDefaults.set(secret, forKey: forUniqueIdentifier)
    #else
        let query: [CFString : Any] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount : LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)
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


            guard let sacObject = sacObject, errorRef == nil, secretData = secret.data(using: .utf8) else {
                print("can't create sacObject: ", errorRef?.pointee.debugDescription ?? "")
                return
            }
            let attributes: [CFString : Any] = [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : LockerHelpers.keyKeychainServiceName,
                kSecAttrAccount : LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier),
                kSecValueData : secretData,
                kSecUseAuthenticationUI: false,
                kSecAttrAccessControl : sacObject
            ]

            DispatchQueue.global(qos: .default).async {
                SecItemAdd(attributes as CFDictionary, nil)

                // Store current LA policy domain state
                LockerHelpers.storeCurrentLAPolicyDomainState()
            }
        }
    #endif

    }

    public static func retrieveCurrentSecretForUniqueIdentifier(_ uniqueIdentifier: String, operationPrompt: String, success: ((String) -> Void)?, failure: ((OSStatus) -> Void)?) {

    #if targetEnvironment(simulator)
        let simulatorSecret = Locker.userDefaults.string(forKey: uniqueIdentifier)
        guard let simulatorSecret = simulatorSecret else {
            failure?(errSecItemNotFound)
            return
        }
        success?(simulatorSecret)
    #else
        let query: [CFString : Any] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount : LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier),
            kSecMatchLimit : kSecMatchLimitOne,
            kSecReturnData : true,
            kSecUseOperationPrompt : operationPrompt
        ]

        DispatchQueue.global(qos: .default).async {
            var dataTypeRef: CFTypeRef? = nil

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

    public static func deleteSecretForUniqueIdentifier(_ uniqueIdentifier: String) {

    #if targetEnvironment(simulator)
        Locker.userDefaults.removeObject(forKey: uniqueIdentifier)
    #else
        let query: [CFString : Any] = [
            kSecClass : kSecClassGenericPassword,
            kSecAttrService : LockerHelpers.keyKeychainServiceName,
            kSecAttrAccount : LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uniqueIdentifier)
        ]

        DispatchQueue.global(qos: .default).async {
            SecItemDelete(query as CFDictionary)
        }
    #endif
    }
}

// MARK: - Additional helpers

public extension Locker {

    static func shouldUseAuthenticationWithBiometricsForUniqueIdentifier(_ uniqueIdentifier: String) -> Bool {
        return Locker.userDefaults.bool(forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier))
    }

    static func setShouldUseAuthenticationWithBiometrics(_ shouldUse: Bool, forUniqueIdentifier uniqueIdentifier: String) {
        if !shouldUse && Locker.shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier( uniqueIdentifier) {
            Locker.setShouldAddSecretToKeychainOnNextLogin(false, forUniqueIdentifier: uniqueIdentifier)
        }
        Locker.userDefaults.set(shouldUse, forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier))
    }

    static func didAskToUseAuthenticationWithBiometricsForUniqueIdentifier(_ uniqueIdentifier: String) -> Bool {
        Locker.userDefaults.bool(forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier))
    }

    static func setDidAskToUseAuthenticationWithBiometrics(_ useAuthenticationBiometrics: Bool, forUniqueIdentifier uniqueIdentifier: String) {
        Locker.userDefaults.set(useAuthenticationBiometrics, forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier))
    }

    static func shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(_ uniqueIdentifier: String) -> Bool {
        Locker.userDefaults.bool(forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier))
    }

    static func setShouldAddSecretToKeychainOnNextLogin(_ shouldAdd: Bool, forUniqueIdentifier uniqueIdentifier: String) {
        Locker.userDefaults.set(shouldAdd, forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier))
    }
}

// MARK: - Data reset

public extension Locker {

    static func resetForUniqueIdentifier(_ uniqueIdentifier: String) {
        Locker.userDefaults.removeObject(forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier))
        Locker.userDefaults.removeObject(forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier))
        Locker.userDefaults.removeObject(forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier))
        Locker.deleteSecretForUniqueIdentifier(uniqueIdentifier)
    }
}
