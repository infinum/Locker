//
//  LockerHelpers.swift
//  Locker
//
//  Created by Zvonimir Medak on 19.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation
import LocalAuthentication
import System

// swiftlint:disable identifier_name
class LockerHelpers {

    // MARK: - Public properties

    static var biometricsSettingsChanged: Bool {
        return checkIfBiometricsSettingsChanged()
    }

    static var deviceSupportsAuthenticationWithBiometrics: BiometricsType {
        if LockerHelpers.deviceSupportsAuthenticationWithFaceID {
            return .faceID
        }

        return checkIfCanAuthenticateWithBiometrics() ? .touchID : .none
    }

    static var configuredBiometricsAuthentication: BiometricsType {
        return getConfiguredBiometricsAuthenticationType()
    }

    static var keyLAPolicyDomainState: String {
        return "\(LockerHelpers.bundleIdentifier)_UserDefaultsLAPolicyDomainState"
    }

    static var canUseAuthenticationWithFaceID: Bool {
        return isFaceIDEnabled()
    }

    static var deviceCode: String {
        return getDeviceIdentifierFromSystem()
    }

    static var deviceSupportsAuthenticationWithFaceID: Bool {
        if LockerHelpers.canUseAuthenticationWithFaceID {
            return true
        }

        return checkIfDeviceSupportsAuthenticationWithFaceID()
    }

    static var isSimulator: Bool {
        LockerHelpers.deviceCode == "x86_64"
    }

    // MARK: - Private properties

    static private var currentLAPolicyDomainState: Data? {
        let context = LAContext()
        context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.evaluatedPolicyDomainState
    }

    static private var savedLAPolicyDomainState: Data? {
        UserDefaults.standard.object(forKey: LockerHelpers.keyLAPolicyDomainState) as? Data
    }

    private static let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
    private static let devices = Devices.shared
}

// MARK: - Public extension

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
        let userDefaultsShouldAddSecretToKeychainOnNextLogin =
        "\(LockerHelpers.bundleIdentifier)_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin"
        return "\(userDefaultsShouldAddSecretToKeychainOnNextLogin)_\(uniqueIdentifier)"
    }

    // MARK: - Biometric helpers

    static func storeCurrentLAPolicyDomainState() {
        let newDomainState = LockerHelpers.currentLAPolicyDomainState
        LockerHelpers.setLAPolicyDomainState(with: newDomainState)
    }

    static var keyKeychainServiceName: String {
        return "\(LockerHelpers.bundleIdentifier)_KeychainService"
    }

    // MARK: - Device list

    static func fetchNewDeviceList() {
    #if !targetEnvironment(simulator)
        devices.fetchDevices()
    #endif
    }
}

// MARK: - Private extension

private extension LockerHelpers {

    static func checkIfBiometricsSettingsChanged() -> Bool {
        let oldDomainState = LockerHelpers.savedLAPolicyDomainState
        let newDomainState = LockerHelpers.currentLAPolicyDomainState

        // Check for domain state changes
        // For deactivated biometrics, LAContext in validation will return nil
        // storing that nil and comparing it to nil will result as `isEqual` NO
        // even data is not actually changed.
        let biometricsDeactivated = oldDomainState == nil || newDomainState == nil
        let biometricSettingsDidChange = oldDomainState?.elementsEqual(newDomainState!) ?? false
        if biometricsDeactivated && biometricSettingsDidChange {
            LockerHelpers.setLAPolicyDomainState(with: newDomainState)
            return true
        }

        return false
    }

    static func checkIfCanAuthenticateWithBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?

        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // When user removes all fingers for TouchID, error code will be `notEnrolled`.
            // In that case, we want to return that device supports TouchID.
            // In case lib is used on simulator, error code will always be `notEnrolled` and only then
            // we want to return that biometrics is not supported as we don't know what simulator is used.
            if let error = error, error.code == kLAErrorBiometryNotAvailable
                || (error.code == kLAErrorBiometryNotEnrolled && isSimulator) {
                return false
            }
        }

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

    static func isFaceIDEnabled() -> Bool {
        let context = LAContext()
        var error: NSError?

        if #available(iOS 11.0, *) {
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
                && context.responds(to: #selector(getter: context.biometryType)) {
                if context.biometryType == .faceID {
                    return true
                }
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

    static func checkIfDeviceSupportsAuthenticationWithFaceID() -> Bool {
        return devices.isDeviceInFaceIDList(device: LockerHelpers.deviceCode)
    }

    static func setLAPolicyDomainState(with domainState: Data?) {
        UserDefaults.standard.set(domainState, forKey: LockerHelpers.keyLAPolicyDomainState)
    }
}
