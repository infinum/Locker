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

    @IBOutlet private weak var storeResultLabel: UILabel!
    @IBOutlet private weak var readResultLabel: UILabel!

    private let identifier = "TouchIDSampleApp"

    public override func viewDidLoad() {
        super.viewDidLoad()
//        Locker.setKeychainService("someCustomService")
//        shouldUseAuthWithBiometrics = true
    }


    @IBAction private func storeSecretAction() {
        storeSecret()
    }

    @IBAction private func readSecretAction() {
        readSecret { [weak self] secret in
            self?.readResultLabel.text = "Read: \(secret)"
        } failure: { [weak self] status in
            self?.readResultLabel.text = "Failed to read w status: \(status)"
        }
    }

    @IBAction private func resetEverythingAction(_ sender: Any) {
        resetUserDefaults()
        resetEverything()
        readResultLabel.text = "--"
        storeResultLabel.text = "--"
    }
}

// MARK: - Locker usage -

// MARK: Read Write Delete

extension ViewController {

    func storeSecret() {
        Locker.setSecret(topSecret, for: identifier, completed: { [weak self] error in
            guard let self else { return }

            guard let error
            else {
                self.storeResultLabel.text = "Stored: \(self.topSecret)"
                return
            }
            
            self.storeResultLabel.text = "Failed to store: \(error)"
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
