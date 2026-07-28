//
//  ContentViewModel.swift
//  TouchID
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import Foundation
import Locker

@MainActor
@Observable
final class ContentViewModel {

    // MARK: - Internal properties -

    let topSecret = "My Secret!"

    var storeResult = "--"
    var readResult = "--"

    // MARK: - Private properties -

    private let identifier = "TouchIDSampleApp"
    private let operationPrompt = "Unlock locker!"
}

// MARK: - View actions -

extension ContentViewModel {

    func storeTapped() async {
        do {
            try await storeSecret()
            storeResult = "Stored: \(topSecret)"
        } catch {
            storeResult = "Failed to store: \(error.localizedDescription)"
        }
    }

    func readTapped() async {
        do {
            readResult = "Read: \(try await readSecret())"
        } catch {
            readResult = "Failed to read: \(error.localizedDescription)"
        }
    }

    func resetTapped() {
        resetUserDefaults()
        resetEverything()
        storeResult = "--"
        readResult = "--"
    }
}

// MARK: - Locker usage -

// MARK: Read Write Delete

extension ContentViewModel {

    func storeSecret() async throws {
        try await Locker.setSecret(topSecret, for: identifier)
    }

    func readSecret() async throws -> String {
        try await Locker.retrieveCurrentSecret(for: identifier, operationPrompt: operationPrompt)
    }

    func deleteSecret() {
        Locker.deleteSecret(for: identifier)
    }
}

// MARK: Device settings

extension ContentViewModel {

    var settingsChanged: Bool {
        Locker.biometricsSettingsDidChange
    }

    var runningFromTheSimulator: Bool {
        Locker.isRunningFromTheSimulator
    }

    var supportedBiometricAuthentication: BiometricsType {
        Locker.supportedBiometricsAuthentication
    }

    var configuredBiometricsAuthentication: BiometricsType {
        Locker.configuredBiometricsAuthentication
    }
}

// MARK: User defaults

extension ContentViewModel {

    func setCustomUserDefaults() {
        guard let userDefaults = UserDefaults(suiteName: "customDomain") else { return }

        Locker.userDefaults = userDefaults
    }

    func resetUserDefaults() {
        Locker.userDefaults = nil
    }
}

// MARK: Helpers

extension ContentViewModel {

    var shouldUseAuthWithBiometrics: Bool {
        get { Locker.shouldUseAuthenticationWithBiometrics(for: identifier) }
        set { Locker.setShouldUseAuthenticationWithBiometrics(newValue, for: identifier) }
    }

    var didAskToUseAuthWithBiometrics: Bool {
        get { Locker.didAskToUseAuthenticationWithBiometrics(for: identifier) }
        set { Locker.setDidAskToUseAuthenticationWithBiometrics(newValue, for: identifier) }
    }

    var shouldAddSecretToKeychainOnNextLogin: Bool {
        get { Locker.shouldAddSecretToKeychainOnNextLogin(for: identifier) }
        set { Locker.setShouldAddSecretToKeychainOnNextLogin(newValue, for: identifier) }
    }
}

// MARK: Reseting

extension ContentViewModel {

    func resetEverything() {
        Locker.reset(for: identifier)
    }
}
