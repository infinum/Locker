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

class LockerHelpers {

    // MARK: - Public properties

    static var biometricsSettingsChanged: Bool {
        var biometricsSettingsChangedStatus = false

        let oldDomainState = LockerHelpers.savedLAPolicyDomainState
        let newDomainState = LockerHelpers.currentLAPolicyDomainState

        // Check for domain state changes
        // For deactivated biometrics, LAContext in validation will return nil
        // storing that nil and comparing it to nil will result as `isEqual` NO
        // even data is not actually changed.
        let biometricsDeactivated: Bool   = (oldDomainState == nil)  || (newDomainState == nil)
        let biometricSettingsDidChange = oldDomainState?.elementsEqual(newDomainState!) ?? false
        if (biometricsDeactivated && biometricSettingsDidChange) {
            biometricsSettingsChangedStatus = true

            LockerHelpers.setLAPolicyDomainState(with: newDomainState)
        }

        return biometricsSettingsChangedStatus
    }

    static var deviceSupportsAuthenticationWithBiometrics: BiometricsType {

        if LockerHelpers.deviceSupportsAuthenticationWithFaceID {
            return .biometricsTypeFaceID
        }

        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // When user removes all fingers for TouchID, error code will be `notEnrolled`.
            // In that case, we want to return that device supports TouchID.
            // In case lib is used on simulator, error code will always be `notEnrolled` and only then
            // we want to return that biometrics is not supported as we don't know what simulator is used.
            if let error = error, error.code == kLAErrorBiometryNotAvailable || (error.code == kLAErrorBiometryNotEnrolled && isSimulator) {
                return .biometricsTypeNone
            }
        }

        return .biometricsTypeTouchID
    }

    static var configuredBiometricsAuthentication: BiometricsType {
        let canUse = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        if canUse && LockerHelpers.canUseAuthenticationWithFaceID {
            return .biometricsTypeFaceID
        } else if canUse {
            return .biometricsTypeTouchID
        } else {
            return .biometricsTypeNone
        }
    }

    static var keyLAPolicyDomainState: String {
        String(format: "%@_UserDefaultsLAPolicyDomainState", locale: nil, LockerHelpers.kBundleIdentifier)
    }

    static var canUseAuthenticationWithFaceID: Bool {
        get {
            let context = LAContext()
            var error: NSError? = nil

            if #available(iOS 11.0, *) {
                if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
                    && context.responds(to: #selector(getter: context.biometryType)) {
                    if context.biometryType == .faceID {
                        return true
                    }
                }
            }
            return false;
        }
    }

    static var deviceCode: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }

    static var deviceSupportsAuthenticationWithFaceID: Bool {
        if LockerHelpers.canUseAuthenticationWithFaceID {
            return true
        }

        let faceIDDevices = [
            "iPhone10,3", // iPhone X Global
            "iPhone10,6", // iPhone X GSM
            "iPhone11,2", // iPhone XS
            "iPhone11,4", // iPhone XS Max
            "iPhone11,6", // iPhone XS Max Global
            "iPhone11,8", // iPhone XR
            "iPhone12,1", // iPhone 11
            "iPhone12,3", // iPhone 11 Pro
            "iPhone12,5", // iPhone 11 Pro Max
            "iPhone13,1", // iPhone 12 Mini
            "iPhone13,2", // iPhone 12
            "iPhone13,3", // iPhone 12 Pro
            "iPhone13,4", // iPhone 12 Pro Max
            "iPhone14,2", // iPhone 13 Mini
            "iPhone14,3", // iPhone 13
            "iPhone14,4", // iPhone 13 Pro
            "iPhone14,5", // iPhone 13 Pro Max
            "iPad8,1", //  iPad Pro 11 inch 3rd Gen (WiFi)
            "iPad8,2", //  iPad Pro 11 inch 3rd Gen (1TB, WiFi)
            "iPad8,3", //  iPad Pro 11 inch 3rd Gen (WiFi+Cellular)
            "iPad8,4", //  iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,5", //  iPad Pro 12.9 inch 3rd Gen (WiFi)
            "iPad8,6", //  iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)
            "iPad8,7", //  iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)
            "iPad8,8", //  iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)
            "iPad8,9", //  iPad Pro 11 inch 4th Gen (WiFi)
            "iPad8,10", // iPad Pro 11 inch 4th Gen (WiFi+Cellular)
            "iPad8,11", // iPad Pro 12.9 inch 4th Gen (WiFi)
            "iPad8,12" //  iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)
        ]

        return faceIDDevices.contains(LockerHelpers.deviceCode)
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

    private static let kBundleIdentifier = Bundle.main.bundleIdentifier ?? ""

    // MARK: - Biometric helpers

    static func storeCurrentLAPolicyDomainState() {
        let newDomainState = LockerHelpers.currentLAPolicyDomainState
        LockerHelpers.setLAPolicyDomainState(with: newDomainState)
    }

    static var keyKeychainServiceName: String {
        String(format: "%@_KeychainService", LockerHelpers.kBundleIdentifier)
    }

    // MARK: - User defaults keys help methods

    static func keyKeychainAccountNameForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let kKeychainAccountName = String(format: "%@_KeychainAccount", locale: nil, kBundleIdentifier)
        return String(format: "%@_%@", kKeychainAccountName, uniqueIdentifier)
    }

    static func keyDidAskToUseBiometricsIDForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let kUserDefaultsDidAskToUseBiometricsID = String(format: "%@_UserDefaultsDidAskToUseTouchID", locale: nil, kBundleIdentifier)
        return String(format: "%@_%@", kUserDefaultsDidAskToUseBiometricsID, uniqueIdentifier)
    }

    static func keyBiometricsIDActivatedForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let kUserDefaultsKeyBiometricsIDActivated = String(format: "%@_UserDefaultsKeyTouchIDActivated", kBundleIdentifier)
        return String(format: "%@_%@", kUserDefaultsKeyBiometricsIDActivated, uniqueIdentifier)
    }

    static func keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(_ uniqueIdentifier: String) -> String {
        let kUserDefaultsShouldAddSecretToKeychainOnNextLogin = String(format: "%@_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin", kBundleIdentifier)
        return String(format: "%@_%@", kUserDefaultsShouldAddSecretToKeychainOnNextLogin, uniqueIdentifier)
    }


    // MARK: - Private methods

    private static func setLAPolicyDomainState(with domainState: Data?) {
        UserDefaults.standard.set(domainState, forKey: LockerHelpers.keyLAPolicyDomainState)
    }
}
