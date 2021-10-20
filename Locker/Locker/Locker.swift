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

    public static var userDefaults: UserDefaults? {
        get {
            return currentUserDefaults == nil ? UserDefaults.standard : currentUserDefaults
        }
        set {
            currentUserDefaults = currentUserDefaults == nil ? UserDefaults.standard : newValue
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

    @objc(setSecret:forUniqueIdentifier:error:)
    public static func setSecret(_ secret: String, for uniqueIdentifier: String) throws {
    #if targetEnvironment(simulator)
        Locker.userDefaults?.set(secret, forKey: uniqueIdentifier)
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
                if let errorRef = errorRef {
                    throw LockerError.accessControl("Unable to initialize access control: \(errorRef.pointee.description)")
                }
                throw LockerError.invalidData("Invalid storing data")
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

    @objc(retreiveCurrentSecretForUniqueIdentifier:operationPrompt:success:failure:)
    public static func retrieveCurrentSecret(for uniqueIdentifier: String, operationPrompt: String, success: ((String) -> Void)?, failure: ((OSStatus) -> Void)?) {

    #if targetEnvironment(simulator)
        let simulatorSecret = Locker.userDefaults?.string(forKey: uniqueIdentifier)
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

    @objc(deleteSecretForUniqueIdentifier:)
    public static func deleteSecret(for uniqueIdentifier: String) {

    #if targetEnvironment(simulator)
        Locker.userDefaults?.removeObject(forKey: uniqueIdentifier)
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

    @objc(shouldUseAuthenticationWithBiometricsForUniqueIdentifier:)
    static func shouldUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool {
        return Locker.userDefaults?.bool(forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier)) ?? false
    }

    @objc(setShouldUseAuthenticationWithBiometrics:forUniqueIdentifier:)
    static func setShouldUseAuthenticationWithBiometrics(_ shouldUse: Bool, for uniqueIdentifier: String) {
        if !shouldUse && Locker.shouldAddSecretToKeychainOnNextLogin(for: uniqueIdentifier) {
            Locker.setShouldAddSecretToKeychainOnNextLogin(false, for: uniqueIdentifier)
        }
        Locker.userDefaults?.set(shouldUse, forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier))
    }

    @objc(didAskToUseAuthenticationWithBiometricsForUniqueIdentifier:)
    static func didAskToUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool {
        Locker.userDefaults?.bool(forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier)) ?? false
    }

    @objc(setDidAskToUseAuthenticationWithBiometrics:forUniqueIdentifier:)
    static func setDidAskToUseAuthenticationWithBiometrics(_ useAuthenticationBiometrics: Bool, for uniqueIdentifier: String) {
        Locker.userDefaults?.set(useAuthenticationBiometrics, forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier))
    }

    @objc(shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier:)
    static func shouldAddSecretToKeychainOnNextLogin(for uniqueIdentifier: String) -> Bool {
        Locker.userDefaults?.bool(forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier)) ?? false
    }

    @objc(setShouldAddSecretToKeychainOnNextLogin:forUniqueIdentifier:)
    static func setShouldAddSecretToKeychainOnNextLogin(_ shouldAdd: Bool, for uniqueIdentifier: String) {
        Locker.userDefaults?.set(shouldAdd, forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier))
    }
}

// MARK: - Data reset

public extension Locker {

    @objc(resetForUniqueIdentifier:)
    static func reset(for uniqueIdentifier: String) {
        Locker.userDefaults?.removeObject(forKey: LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uniqueIdentifier))
        Locker.userDefaults?.removeObject(forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uniqueIdentifier))
        Locker.userDefaults?.removeObject(forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uniqueIdentifier))
        Locker.deleteSecret(for: uniqueIdentifier)
    }
}
