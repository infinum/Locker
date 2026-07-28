//
//  ContentViewModelTests.swift
//  TouchIDTests
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import Testing
import Locker
@testable import TouchID

// `.serialized`: Locker keeps its configuration (`userDefaults`) and its stored
// secrets in process wide static state, and every test here uses the same unique
// identifier. Swift Testing runs tests in parallel by default, which XCTest did
// not, so the suite has to opt back out.
@Suite(.serialized)
@MainActor
struct ContentViewModelTests {

    // MARK: - Private properties -

    private let viewModel = ContentViewModel()

    // MARK: - Setup -

    init() {
        // A fresh instance is created per test, but the Locker state behind it is
        // shared, so start every test from a known clean slate.
        viewModel.resetUserDefaults()
        viewModel.resetEverything()
    }
}

// MARK: - Store Retrieve and Delete -

extension ContentViewModelTests {

    @Test("Stores and retrieves the secret")
    func storeAndRetrieveSecret() async throws {
        try await viewModel.storeSecret()

        let secret = try await viewModel.readSecret()

        #expect(secret == viewModel.topSecret)
    }

    @Test("Stores and retrieves the secret with custom user defaults")
    func storeAndRetrieveSecretWithCustomUserDefaults() async throws {
        viewModel.setCustomUserDefaults()

        try await viewModel.storeSecret()
        let secret = try await viewModel.readSecret()

        #expect(secret == viewModel.topSecret)
    }

    @Test("Deletes the secret")
    func deleteSecret() async throws {
        try await viewModel.storeSecret()

        viewModel.deleteSecret()

        await #expect(throws: KeychainError.self) {
            try await viewModel.readSecret()
        }
    }
}

// MARK: - View actions -

extension ContentViewModelTests {

    @Test("Store, read and reset update the displayed results")
    func viewActionsUpdateResults() async {
        await viewModel.storeTapped()
        #expect(viewModel.storeResult == "Stored: \(viewModel.topSecret)")

        await viewModel.readTapped()
        #expect(viewModel.readResult == "Read: \(viewModel.topSecret)")

        viewModel.resetTapped()
        #expect(viewModel.storeResult == "--")
        #expect(viewModel.readResult == "--")
    }

    @Test("Reading a secret that is not stored shows a failure")
    func readTappedWithoutStoredSecretShowsFailure() async {
        await viewModel.readTapped()

        #expect(viewModel.readResult.hasPrefix("Failed to read: "))
    }
}

// MARK: - Device settings -

extension ContentViewModelTests {

    @Test("Biometrics settings did not change")
    func settingsChanged() {
        #expect(!viewModel.settingsChanged)
    }

    // The whole suite assumes the simulator: Locker falls back to UserDefaults
    // there, so no biometric prompt is needed to read a secret back.
    @Test("Runs from the simulator")
    func runningFromTheSimulator() {
        #expect(viewModel.runningFromTheSimulator)
    }

    @Test("Device supports no biometric authentication")
    func supportedBiometricAuthentication() {
        #expect(viewModel.supportedBiometricAuthentication == .none)
    }

    @Test("No biometric authentication is configured")
    func configuredBiometricsAuthentication() {
        #expect(viewModel.configuredBiometricsAuthentication == .none)
    }
}

// MARK: - Helpers -

extension ContentViewModelTests {

    @Test("Stores the should use auth flag")
    func shouldUseAuthFlag() {
        viewModel.shouldUseAuthWithBiometrics = true

        #expect(viewModel.shouldUseAuthWithBiometrics)
    }

    @Test("Stores the should use auth flag in custom user defaults")
    func shouldUseAuthFlagWithCustomUserDefaults() {
        viewModel.setCustomUserDefaults()

        viewModel.shouldUseAuthWithBiometrics = true

        #expect(viewModel.shouldUseAuthWithBiometrics)
    }

    @Test("Stores the did ask to use auth flag")
    func didAskToUseAuthWithBiometrics() {
        viewModel.didAskToUseAuthWithBiometrics = true

        #expect(viewModel.didAskToUseAuthWithBiometrics)
    }

    @Test("Stores the did ask to use auth flag in custom user defaults")
    func didAskToUseAuthWithBiometricsWithCustomUserDefaults() {
        viewModel.setCustomUserDefaults()

        viewModel.didAskToUseAuthWithBiometrics = true

        #expect(viewModel.didAskToUseAuthWithBiometrics)
    }

    @Test("Stores the should add secret on next login flag")
    func shouldAddSecretToKeychainOnNextLogin() {
        viewModel.shouldAddSecretToKeychainOnNextLogin = true

        #expect(viewModel.shouldAddSecretToKeychainOnNextLogin)
    }

    @Test("Stores the should add secret on next login flag in custom user defaults")
    func shouldAddSecretToKeychainOnNextLoginWithCustomUserDefaults() {
        viewModel.setCustomUserDefaults()

        viewModel.shouldAddSecretToKeychainOnNextLogin = true

        #expect(viewModel.shouldAddSecretToKeychainOnNextLogin)
    }
}

// MARK: - Reseting -

extension ContentViewModelTests {

    @Test("Resets everything")
    func resetAll() async throws {
        viewModel.shouldUseAuthWithBiometrics = true
        viewModel.didAskToUseAuthWithBiometrics = true
        viewModel.shouldAddSecretToKeychainOnNextLogin = true
        try await viewModel.storeSecret()

        viewModel.resetEverything()

        await #expect(throws: KeychainError.self) {
            try await viewModel.readSecret()
        }
        #expect(!viewModel.shouldUseAuthWithBiometrics)
        #expect(!viewModel.didAskToUseAuthWithBiometrics)
        #expect(!viewModel.shouldAddSecretToKeychainOnNextLogin)
    }
}
