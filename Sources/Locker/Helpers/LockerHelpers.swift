//
//  LockerHelpers.swift
//  Locker
//
//  Created by Zvonimir Medak on 19.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation
import LocalAuthentication

final class LockerHelpers: Sendable {

    // MARK: - Public properties

    static var biometricsSettingsChanged: Bool {
        return checkIfBiometricsSettingsChanged()
    }

    static var supportedBiometricAuthentication: BiometricsType {
        if LockerHelpers.deviceSupportsAuthenticationWithFaceID {
            return .faceID
        }

        return deviceSupportsAuthenticationWithTouchID ? .touchID : .none
    }

    static var configuredBiometricsAuthentication: BiometricsType {
        return getConfiguredBiometricsAuthenticationType()
    }

    static var keyLAPolicyDomainState: String {
        return "\(LockerHelpers.bundleIdentifier)_UserDefaultsLAPolicyDomainState"
    }

    static var canUseAuthenticationWithFaceID: Bool {
        return faceIDEnabled
    }

    static var canUseAuthenticationWithTouchID: Bool {
        return touchIDEnabled
    }

    static var deviceCode: String {
        return getDeviceIdentifierFromSystem()
    }

    static var deviceSupportsAuthenticationWithFaceID: Bool {
        if LockerHelpers.canUseAuthenticationWithFaceID {
            return true
        }

        return deviceManager.isDeviceInFaceIDList(device: LockerHelpers.deviceCode)
    }

    static var deviceSupportsAuthenticationWithTouchID: Bool {
        if LockerHelpers.canUseAuthenticationWithTouchID {
            return true
        }

        return deviceManager.isDeviceInTouchIDList(device: LockerHelpers.deviceCode)
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
            return true
        #else
            return false
        #endif
    }

    // MARK: - Private properties

    static private var currentLAPolicyDomainState: Data? {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.evaluatedPolicyDomainState
    }

    /// Reads LA policy domain state from the unified Locker.userDefaults.
    /// On first access, migrates any existing value from UserDefaults.standard
    /// if a custom suite is in use and the key doesn't exist there yet.
    static private var savedLAPolicyDomainState: Data? {
        let defaults = resolvedUserDefaults
        let key = LockerHelpers.keyLAPolicyDomainState

        // Migration: if using a custom suite and no value exists yet,
        // check UserDefaults.standard for a previously stored value.
        if defaults !== UserDefaults.standard {
            if defaults.object(forKey: key) == nil,
               let legacyValue = UserDefaults.standard.object(forKey: key) as? Data {
                defaults.set(legacyValue, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        return defaults.object(forKey: key) as? Data
    }

    private static var faceIDEnabled: Bool {
        return checkFaceIdState()
    }

    private static var touchIDEnabled: Bool {
        let context = LAContext()
        var error: NSError?

        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // When user removes all fingers for TouchID, error code will be `notEnrolled`.
            // In that case, we want to return that device supports TouchID.
            // In case lib is used on simulator, error code will always be `notEnrolled` and only then
            // we want to return that biometrics is not supported as we don't know what simulator is used.
            if let error = error,
               error.code == biometryNotAvailableCode || (error.code == biometryNotEnrolledCode && isSimulator) {
                return false
            }
        }

        return true
    }

    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""

    private static var biometryNotAvailableCode: Int {
        return LAError.biometryNotAvailable.rawValue
    }

    private static var biometryNotEnrolledCode: Int {
        return LAError.biometryNotEnrolled.rawValue
    }

    private static let deviceManager: DeviceManager = .shared

    /// Returns the current Locker.userDefaults instance.
    /// This ensures all UserDefaults access goes through the same instance,
    /// eliminating divergence when a custom suite is configured.
    private static var resolvedUserDefaults: UserDefaults {
        Locker.userDefaults ?? .standard
    }
}

// MARK: - Internal extension

extension LockerHelpers {

    // MARK: - User defaults keys help methods

    static func keyKeychainAccountNameForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let keychainAccountName = "\(LockerHelpers.bundleIdentifier)_KeychainAccount"
        return "\(keychainAccountName)_\(uniqueIdentifier)"
    }

    static func keyDidAskToUseBiometricsIDForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let userDefaultsDidAskToUseBiometricsID = "\(LockerHelpers.bundleIdentifier)_UserDefaultsDidAskToUseTouchID"
        return "\(userDefaultsDidAskToUseBiometricsID)_\(uniqueIdentifier)"
    }

    static func keyBiometricsIDActivatedForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let userDefaultsKeyBiometricsIDActivated = "\(LockerHelpers.bundleIdentifier)_UserDefaultsKeyTouchIDActivated"
        return "\(userDefaultsKeyBiometricsIDActivated)_\(uniqueIdentifier)"
    }

    static func keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        // swiftlint:disable:next line_length
        let shouldAddSecretToKeychainOnNextLogin = "\(LockerHelpers.bundleIdentifier)_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin"
        return "\(shouldAddSecretToKeychainOnNextLogin)_\(uniqueIdentifier)"
    }

    static var keyCustomKeychainService: String {
        return "\(LockerHelpers.bundleIdentifier)_UserDefaultsCustomKeychainService"
    }

    // MARK: - Biometric helpers

    static func storeCurrentLAPolicyDomainState() {
        let newDomainState = LockerHelpers.currentLAPolicyDomainState
        LockerHelpers.setLAPolicyDomainState(with: newDomainState)
    }

    /// Reads the keychain service name from the unified Locker.userDefaults.
    /// On first access with a custom suite, migrates the value from UserDefaults.standard.
    static var keyKeychainServiceName: String {
        let defaults = resolvedUserDefaults
        let key = keyCustomKeychainService

        // Migration: if using a custom suite and no override exists yet,
        // check UserDefaults.standard for a previously stored override.
        if defaults !== UserDefaults.standard {
            if defaults.object(forKey: key) == nil,
               let legacyService = UserDefaults.standard.object(forKey: key) as? String {
                defaults.set(legacyService, forKey: key)
                UserDefaults.standard.removeObject(forKey: key)
            }
        }

        guard let service = defaults.object(forKey: key) as? String else {
            return "\(LockerHelpers.bundleIdentifier)_KeychainService"
        }

        return service
    }

    // MARK: - Device list

    static func fetchNewDeviceList() {
    #if !targetEnvironment(simulator)
        if !deviceSupportsAuthenticationWithTouchID && !deviceSupportsAuthenticationWithFaceID {
            deviceManager.fetchDevices()
        }
    #endif
    }
}

// MARK: - Private extension

private extension LockerHelpers {

    static func checkIfBiometricsSettingsChanged() -> Bool {
        let oldDomainState = LockerHelpers.savedLAPolicyDomainState
        let newDomainState = LockerHelpers.currentLAPolicyDomainState

        guard oldDomainState != nil || newDomainState != nil,
              oldDomainState != newDomainState
        else { return false }

        LockerHelpers.setLAPolicyDomainState(with: LockerHelpers.currentLAPolicyDomainState)
        return true
    }

    static func getConfiguredBiometricsAuthenticationType() -> BiometricsType {
        let canUse = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        if canUse && LockerHelpers.canUseAuthenticationWithFaceID {
            return .faceID
        } else if canUse {
            return .touchID
        } else {
            return .none
        }
    }

    static func checkFaceIdState() -> Bool {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .faceID {
                return true
            }
        }
        return false
    }

    static func getDeviceIdentifierFromSystem() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    /// Writes LA policy domain state to the unified Locker.userDefaults.
    static func setLAPolicyDomainState(with domainState: Data?) {
        resolvedUserDefaults.set(domainState, forKey: LockerHelpers.keyLAPolicyDomainState)
    }
}
