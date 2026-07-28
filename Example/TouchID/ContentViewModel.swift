//
//  ContentViewModel.swift
//  TouchID
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import Foundation
import Security
import Locker

@MainActor
@Observable
final class ContentViewModel {

    // MARK: - Internal properties -

    static let clearMessage = "Keychain clear"
    static let noSecretsMessage = "No secrets to read"

    /// Shown as the alert's text field placeholder, and stored when the field is left empty.
    static let customSecretPlaceholder = "Custom secret"

    let topSecret = "My Secret!"

    /// Result of the last store or read, shared by all actions.
    var result = ContentViewModel.clearMessage

    var customSecret = ""
    var isCustomSecretAlertPresented = false

    // MARK: - Private properties -

    private let identifier = "TouchIDSampleApp"
    private let operationPrompt = "Unlock locker!"
}

// MARK: - View actions -

extension ContentViewModel {

    func storeTapped() async {
        await store(topSecret)
    }

    func storeCustomTapped() {
        isCustomSecretAlertPresented = true
    }

    func confirmCustomSecretTapped() async {
        // An empty field stores the placeholder, so the alert always has something to store.
        let secret = customSecret.isEmpty ? ContentViewModel.customSecretPlaceholder : customSecret
        customSecret = ""

        await store(secret)
    }

    func cancelCustomSecretTapped() {
        customSecret = ""
    }

    func readTapped() async {
        do {
            result = "Read: \(try await readSecret())"
        } catch let error as KeychainError where error.status == errSecItemNotFound {
            // Nothing stored yet is an expected state, not a failure worth an OSStatus.
            result = ContentViewModel.noSecretsMessage
        } catch {
            result = "Failed to read: \(error.localizedDescription)"
        }
    }

    func resetTapped() {
        resetUserDefaults()
        resetEverything()
        result = ContentViewModel.clearMessage
    }
}

// MARK: Storing

private extension ContentViewModel {

    func store(_ secret: String) async {
        do {
            try await storeSecret(secret)
            result = "Stored: \(secret)"
        } catch {
            result = "Failed to store: \(error.localizedDescription)"
        }
    }
}

// MARK: - Locker usage -

// MARK: Read Write Delete

extension ContentViewModel {

    func storeSecret(_ secret: String) async throws {
        try await Locker.setSecret(secret, for: identifier)
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
