//
//  Locker.swift
//  
//
//  Created by Zvonimir Medak on 01.10.2021..
//

import Foundation
#if !os(macOS)
import UIKit
#endif

@available(macOS 10.13.4, *)
public class Locker: Lockable {

    // MARK: - Private properties
    private static var currentUserDefaults: UserDefaults?

    // MARK: - Public properties

    public static var userDefaults: UserDefaults? {
        get {
            if currentUserDefaults == nil {
                return UserDefaults.standard
            }
            return currentUserDefaults
        }
        set(newUserDefaults) {
            if currentUserDefaults == nil {
                currentUserDefaults = UserDefaults.standard
            } else {
                currentUserDefaults = newUserDefaults
            }
        }
    }

    public static var biometricsSettingsDidChange: Bool {
        LockerHelpers.biometricsSettingsChanged
    }

    public static var isRunningFromTheSimulator: Bool {
        TARGET_OS_SIMULATOR != 0 ? true : false
    }

    public static func deviceSupportsAuthenticationWithBiometrics(_ completion: @escaping ((BiometricsType) -> Void)) {
        LockerHelpers.deviceSupportsAuthenticationWithBiometrics { biometryType in
            completion(biometryType)
        }
    }

    public static var configuredBiometricsAuthentication: BiometricsType {
        LockerHelpers.configureBiometricsAuthentication
    }

    // MARK: - Handle secrets (store, delete, fetch)

    public static func setSecret(_ secret: String, for uniqueIdentifier: String) {
        if TARGET_OS_SIMULATOR != 0 {
            Locker.userDefaults?.set(secret, forKey: uniqueIdentifier)
        } else {
            let query: [CFString : Any] = [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : LockerHelpers.keyKeychainServiceName,
                kSecAttrAccount : LockerHelpers.keyKeychainAccountName(for: uniqueIdentifier)
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
                    kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                    flags,
                    errorRef
                )


                guard let sacObject = sacObject, errorRef == nil else {
                    print("can't create sacObject: ", errorRef?.pointee.debugDescription ?? "")
                    return
                }
                let attributes: [CFString : Any] = [
                    kSecClass : kSecClassGenericPassword,
                    kSecAttrService : LockerHelpers.keyKeychainServiceName,
                    kSecAttrAccount : LockerHelpers.keyKeychainAccountName(for: uniqueIdentifier),
                    kSecValueData : secret.data(using: .utf8) ?? Data(),
                    kSecUseAuthenticationUI: false,
                    kSecAttrAccessControl : sacObject
                ]

                DispatchQueue.global(qos: .default).async {
                    SecItemAdd(attributes as CFDictionary, nil)

                    // Store current LA policy domain state
                    LockerHelpers.storeCurrentLAPolicyDomainState()
                }
            }
        }
    }

    public static func retrieveCurrentSecret(for uniqueIdentifier: String, operationPrompt: String, success: ((String?) -> Void)?, failure: ((OSStatus) -> Void)?) {
        if TARGET_OS_SIMULATOR != 0 {
            let simulatorSecret = Locker.userDefaults?.string(forKey: uniqueIdentifier)
            if simulatorSecret == nil {
                failure?(errSecItemNotFound)
                return
            }
            success?(simulatorSecret)
        } else {
            let query: [CFString : Any] = [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : LockerHelpers.keyKeychainServiceName,
                kSecAttrAccount : LockerHelpers.keyKeychainAccountName(for: uniqueIdentifier),
                kSecMatchLimit : kSecMatchLimitOne,
                kSecReturnData : true,
                kSecUseOperationPrompt : operationPrompt
            ]

            DispatchQueue.global(qos: .default).async {
                var dataTypeRef: CFTypeRef? = nil

                let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
                if status == errSecSuccess {
                    if let success = success {
                        guard let resultData = dataTypeRef as? Data else {
                            failure?(errSecItemNotFound)
                            return
                        }
                        let result = String(data: resultData, encoding: .utf8)
                        DispatchQueue.main.async {
                            success(result)
                        }
                    }
                } else {
                    if let failure = failure {
                        DispatchQueue.main.async {
                            failure(status)
                        }
                    }
                }
            }
        }
    }

    public static func deleteSecret(for uniqueIdentifier: String) {
        if TARGET_OS_SIMULATOR != 0 {
            Locker.userDefaults?.removeObject(forKey: uniqueIdentifier)
        } else {
            let query: [CFString : Any] = [
                kSecClass : kSecClassGenericPassword,
                kSecAttrService : LockerHelpers.keyKeychainServiceName,
                kSecAttrAccount : LockerHelpers.keyKeychainAccountName(for: uniqueIdentifier)
            ]

            DispatchQueue.global(qos: .default).async {
                SecItemDelete(query as CFDictionary)
            }
        }
    }

    // MARK: - Additional helpers

    public static func shouldUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool {
        return Locker.userDefaults?.bool(forKey: LockerHelpers.keyBiometricsIDActivated(for: uniqueIdentifier)) ?? false
    }

    public static func setShouldUseAuthenticationWithBiometrics(_ shouldUse: Bool, for uniqueIdentifier: String) {
        if shouldUse == false && Locker.shouldAddSecretToKeychainOnNextLogin(for: uniqueIdentifier) {
            Locker.setShouldAddSecretToKeychainOnNextLogin(false, for: uniqueIdentifier)
        }
        Locker.userDefaults?.set(shouldUse, forKey: LockerHelpers.keyBiometricsIDActivated(for: uniqueIdentifier))
    }

    public static func didAskToUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool {
        Locker.userDefaults?.bool(forKey: LockerHelpers.keyDidAskToUserBiometricsID(for: uniqueIdentifier)) ?? false
    }

    public static func setDidAskToUseAuthenticationWithBiometrics(_ useAuthenticationBiometrics: Bool, for uniqueIdentifier: String) {
        Locker.userDefaults?.set(useAuthenticationBiometrics, forKey: LockerHelpers.keyDidAskToUserBiometricsID(for: uniqueIdentifier))
    }

    public static func shouldAddSecretToKeychainOnNextLogin(for uniqueIdentifier: String) -> Bool {
        Locker.userDefaults?.bool(forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLogin(for: uniqueIdentifier)) ?? false
    }

    public static func setShouldAddSecretToKeychainOnNextLogin(_ shouldAdd: Bool, for uniqueIdentifier: String) {
        Locker.userDefaults?.set(shouldAdd, forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLogin(for: uniqueIdentifier))
    }

    // MARK: - Data reset

    public static func reset(for uniqueIdentifier: String) {
        Locker.userDefaults?.removeObject(forKey: LockerHelpers.keyDidAskToUserBiometricsID(for: uniqueIdentifier))
        Locker.userDefaults?.removeObject(forKey: LockerHelpers.keyShouldAddSecretToKeychainOnNextLogin(for: uniqueIdentifier))
        Locker.userDefaults?.removeObject(forKey: LockerHelpers.keyBiometricsIDActivated(for: uniqueIdentifier))
        Locker.deleteSecret(for: uniqueIdentifier)
    }


}
