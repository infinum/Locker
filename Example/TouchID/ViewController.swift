//
//  ViewController.swift
//  TouchID
//
//  Created by Ivan Vecko on 02/03/2018.
//  Copyright © 2018 Infinum Ltd. All rights reserved.
//

import UIKit
import Locker

public final class ViewController: UIViewController {

    // MARK: - Public properties -

    let topSecret = "My Secret!"

    // MARK: - Private properties -

    private let identifier = "TouchIDSampleApp"
}

// MARK: - Locker usage -

// MARK: Read Write Delete

extension ViewController {

    func storeSecret() {
        Locker.setSecret(topSecret, for: identifier, completion: { error in
            // handle error
            print(error)
        })
    }

    func readSecret(success: @escaping (String) -> Void, failure: @escaping (OSStatus) -> Void) {
        Locker.retrieveCurrentSecret(
            for: identifier,
            operationPrompt: "Unlock locker!",
            success: success, failure: failure
        )
    }

    func deleteSecret() {
        Locker.deleteSecret(for: identifier)
    }
}

// MARK: Device settings

extension ViewController {

    var settingsChanged: Bool {
        return Locker.biometricsSettingsDidChange
    }

    var runningFromTheSimulator: Bool {
        return Locker.isRunningFromTheSimulator
    }

    var supportedBiometricAuthentication: BiometricsType {
        return Locker.supportedBiometricsAuthentication
    }

    var configuredBiometricsAuthentication: BiometricsType {
        return Locker.configuredBiometricsAuthentication
    }
}

// MARK: User defaults

extension ViewController {

    func setCustomUserDefaults() {
        guard let userDefaults = UserDefaults(suiteName: "customDomain") else {
            return
        }
        Locker.userDefaults = userDefaults
    }

    func resetUserDefaults() {
        Locker.userDefaults = nil
    }
}

// MARK: Helpers

extension ViewController {

    var shouldUseAuthWithBiometrics: Bool {
        get { return Locker.shouldUseAuthenticationWithBiometrics(for: identifier) }
        set (newValue) { Locker.setShouldUseAuthenticationWithBiometrics(newValue, for: identifier) }
    }

    // swiftlint:disable unused_setter_value
    var didAskToUseAuthWithBiometrics: Bool {
        get { return Locker.didAskToUseAuthenticationWithBiometrics(for: identifier) }
        set { Locker.setDidAskToUseAuthenticationWithBiometrics(true, for: identifier) }
    }

    var shouldAddSecretToKeychainOnNextLogin: Bool {
        get { return Locker.shouldAddSecretToKeychainOnNextLogin(for: identifier) }
        set { Locker.setShouldAddSecretToKeychainOnNextLogin(true, for: identifier) }
    }
}

// MARK: Reseting

extension ViewController {
    func resetEverything() {
        Locker.reset(for: identifier)
    }
}
