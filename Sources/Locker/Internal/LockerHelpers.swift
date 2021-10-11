//
//  LockerHelpers.swift
//  
//
//  Created by Zvonimir Medak on 04.10.2021..
//

import Foundation
import LocalAuthentication
import System
import Alamofire

@available(macOS 10.13.2, *)
class LockerHelpers: LockerHelpable {

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

    static var configureBiometricsAuthentication: BiometricsType {
        let canUse = LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)

        if canUse && LockerHelpers.canUseAuthenticationWithFaceID {
            return .faceID
        } else if canUse {
            return .touchID
        } else {
            return .none
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

    static func deviceSupportsAuthenticationWithFaceID(_ completion: @escaping ((Bool) -> Void)) {
        if LockerHelpers.canUseAuthenticationWithFaceID {
            completion(true)
        } else {
            URLSession.shared.dataTask(with: deviceList.api) { data, _, error in
                guard let data = data, error == nil else {
                    completion(false)
                    return
                }
                do {
                    let deviceList = try JSONDecoder().decode(DeviceResponse.self, from: data).devices
                    completion(deviceList.contains(LockerHelpers.deviceCode))
                } catch {
                    completion(false)
                }
            }.resume()
        }
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

    static func keyKeychainAccountName(for uniqueIdentifier: String) -> String {
        let kKeychainAccountName = String(format: "%@_KeychainAccount", locale: nil, kBundleIdentifier)
        return String(format: "%@_%@", kKeychainAccountName, uniqueIdentifier)
    }

    static func keyDidAskToUserBiometricsID(for uniqueIdentifier: String) -> String {
        let kUserDefaultsDidAskToUseBiometricsID = String(format: "%@_UserDefaultsDidAskToUseTouchID", locale: nil, kBundleIdentifier)
        return String(format: "%@_%@", kUserDefaultsDidAskToUseBiometricsID, uniqueIdentifier)
    }

    static func keyBiometricsIDActivated(for uniqueIdentifier: String) -> String {
        let kUserDefaultsKeyBiometricsIDActivated = String(format: "%@_UserDefaultsKeyTouchIDActivated", kBundleIdentifier)
        return String(format: "%@_%@", kUserDefaultsKeyBiometricsIDActivated, uniqueIdentifier)
    }

    static func keyShouldAddSecretToKeychainOnNextLogin(for uniqueIdentifier: String) -> String {
        let kUserDefaultsShouldAddSecretToKeychainOnNextLogin = String(format: "%@_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin", kBundleIdentifier)
        return String(format: "%@_%@", kUserDefaultsShouldAddSecretToKeychainOnNextLogin, uniqueIdentifier)
    }


    // MARK: - Private methods

    private static func setLAPolicyDomainState(with domainState: Data?) {
        UserDefaults.standard.set(domainState, forKey: LockerHelpers.keyLAPolicyDomainState)
    }

    // MARK: - Apiary

    static func deviceSupportsAuthenticationWithBiometrics(_ completion: @escaping ((BiometricsType) -> Void)) {
        LockerHelpers.deviceSupportsAuthenticationWithFaceID({ isSupported in
            if isSupported {
                completion(.faceID)
            } else {
                let context = LAContext()
                var error: NSError? = nil

                if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                    // When user removes all fingers for TouchID, error code will be `notEnrolled`.
                    // In that case, we want to return that device supports TouchID.
                    // In case lib is used on simulator, error code will always be `notEnrolled` and only then
                    // we want to return that biometrics is not supported as we don't know what simulator is used.
                    if let error = error, error.code == kLAErrorBiometryNotAvailable || error.code == kLAErrorBiometryNotEnrolled && isSimulator {
                        completion(.none)
                    }
                } else {
                    completion(.touchID)
                }
            }
        })
    }

    internal static var deviceList: DeviceList = .shared
}
