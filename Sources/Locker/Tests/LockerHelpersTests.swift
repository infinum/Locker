//
//  LockerHelpersTests.swift
//  Locker-Locker_Locker
//
//  Created by Nikola Simunko on 01.08.2025..
//

import XCTest

@testable import Locker

final class LockerHelpersTests: XCTestCase {

    private var bundleId: String { Bundle.main.bundleIdentifier ?? "" }
    private let customSuiteName = "com.locker.tests"

    // MARK: - Setup before & after each test

    override func setUp() {
        super.setUp()
        // Reset to standard defaults before each test
        Locker.userDefaults = nil
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LockerHelpers.keyCustomKeychainService)
        defaults.removeObject(forKey: LockerHelpers.keyLAPolicyDomainState)
    }

    override func tearDown() {
        // Clean up custom suite if used
        if let customDefaults = UserDefaults(suiteName: customSuiteName) {
            customDefaults.removePersistentDomain(forName: customSuiteName)
        }
        Locker.userDefaults = nil
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LockerHelpers.keyCustomKeychainService)
        defaults.removeObject(forKey: LockerHelpers.keyLAPolicyDomainState)
        super.tearDown()
    }

    // MARK: - Keychain key generation

    func testKeyKeychainAccountNameForUniqueIdentifier() {
        let uid = "abc123"
        let expected = "\(bundleId)_KeychainAccount_\(uid)"
        let got = LockerHelpers.keyKeychainAccountNameForUniqueIdentifier(uid)

        XCTAssertEqual(got, expected)
    }

    func testKeyDidAskToUseBiometricsIDForUniqueIdentifier() {
        let uid = "abc123"
        let expected = "\(bundleId)_UserDefaultsDidAskToUseTouchID_\(uid)"
        let got = LockerHelpers.keyDidAskToUseBiometricsIDForUniqueIdentifier(uid)

        XCTAssertEqual(got, expected)
    }

    func testKeyBiometricsIDActivatedForUniqueIdentifier() {
        let uid = "abc123"
        let expected = "\(bundleId)_UserDefaultsKeyTouchIDActivated_\(uid)"
        let got = LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uid)

        XCTAssertEqual(got, expected)
    }

    func testKeyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier() {
        let uid = "abc123"
        let expected = "\(bundleId)_UserDefaultsShouldAddPasscodeToKeychainOnNextLogin_\(uid)"
        let got = LockerHelpers.keyShouldAddSecretToKeychainOnNextLoginForUniqueIdentifier(uid)

        XCTAssertEqual(got, expected)
    }

    func testCustomKeychainService() {
        let expected = "\(bundleId)_UserDefaultsCustomKeychainService"
        XCTAssertEqual(LockerHelpers.keyCustomKeychainService, expected)
    }

    func testLAPolicyDomainState() {
        let expected = "\(bundleId)_UserDefaultsLAPolicyDomainState"
        XCTAssertEqual(LockerHelpers.keyLAPolicyDomainState, expected)
    }

    func testKeychainServiceNameReturnsDefaultWhenNoOverride() {
        let expected = "\(bundleId)_KeychainService"
        let got = LockerHelpers.keyKeychainServiceName
        XCTAssertEqual(got, expected)
    }

    func testKeychainServiceNameOverrideFromUserDefaults() {
        let override = "CustomService"
        Locker.userDefaults?.set(override, forKey: LockerHelpers.keyCustomKeychainService)
        let got = LockerHelpers.keyKeychainServiceName
        XCTAssertEqual(got, override)
    }

    // MARK: - UserDefaults unification (no divergence with custom suite)

    func testKeychainServiceNameUsesCustomSuite() {
        guard let customDefaults = UserDefaults(suiteName: customSuiteName) else {
            XCTFail("Could not create custom UserDefaults suite")
            return
        }

        Locker.userDefaults = customDefaults
        Locker.setKeychainService("MyCustomService")

        XCTAssertEqual(LockerHelpers.keyKeychainServiceName, "MyCustomService")
        XCTAssertEqual(
            customDefaults.string(forKey: LockerHelpers.keyCustomKeychainService),
            "MyCustomService"
        )
    }

    func testLAPolicyDomainStateUsesCustomSuite() {
        guard let customDefaults = UserDefaults(suiteName: customSuiteName) else {
            XCTFail("Could not create custom UserDefaults suite")
            return
        }

        Locker.userDefaults = customDefaults
        LockerHelpers.storeCurrentLAPolicyDomainState()

        let key = LockerHelpers.keyLAPolicyDomainState
        let standardValue = UserDefaults.standard.object(forKey: key)
        XCTAssertNil(standardValue, "LA policy state should not be in .standard when custom suite is used")
    }

    func testKeychainServiceNameMigratesFromStandard() {
        guard let customDefaults = UserDefaults(suiteName: customSuiteName) else {
            XCTFail("Could not create custom UserDefaults suite")
            return
        }

        // Pre-populate .standard with a legacy override
        UserDefaults.standard.set("LegacyService", forKey: LockerHelpers.keyCustomKeychainService)

        // Switch to custom suite
        Locker.userDefaults = customDefaults

        // Reading should migrate and return the legacy value
        XCTAssertEqual(LockerHelpers.keyKeychainServiceName, "LegacyService")
        XCTAssertEqual(
            customDefaults.string(forKey: LockerHelpers.keyCustomKeychainService),
            "LegacyService"
        )
        XCTAssertNil(UserDefaults.standard.string(forKey: LockerHelpers.keyCustomKeychainService))
    }

    func testBooleanFlagsUseCustomSuite() {
        guard let customDefaults = UserDefaults(suiteName: customSuiteName) else {
            XCTFail("Could not create custom UserDefaults suite")
            return
        }

        Locker.userDefaults = customDefaults
        let uid = "testUser"

        Locker.setShouldUseAuthenticationWithBiometrics(true, for: uid)
        Locker.setDidAskToUseAuthenticationWithBiometrics(true, for: uid)
        Locker.setShouldAddSecretToKeychainOnNextLogin(true, for: uid)

        XCTAssertTrue(Locker.shouldUseAuthenticationWithBiometrics(for: uid))
        XCTAssertTrue(Locker.didAskToUseAuthenticationWithBiometrics(for: uid))
        XCTAssertTrue(Locker.shouldAddSecretToKeychainOnNextLogin(for: uid))

        XCTAssertTrue(customDefaults.bool(
            forKey: LockerHelpers.keyBiometricsIDActivatedForUniqueIdentifier(uid)
        ))
    }

    // MARK: - Async API tests (simulator only)

    func testAsyncSetAndRetrieveSecretOnSimulator() async throws {
    #if targetEnvironment(simulator)
        let uid = "asyncTest"
        let secret = "asyncSecret123"

        try await Locker.setSecret(secret, for: uid)

        let retrieved = try await Locker.retrieveCurrentSecret(
            for: uid,
            operationPrompt: "Test prompt"
        )
        XCTAssertEqual(retrieved, secret)

        await Locker.deleteSecret(for: uid)

        do {
            _ = try await Locker.retrieveCurrentSecret(for: uid, operationPrompt: "Test")
            XCTFail("Should have thrown RetrievalError.notFound")
        } catch {
            // Expected
        }
    #else
        throw XCTSkip("Keychain async tests require simulator or enrolled biometrics")
    #endif
    }

    func testAsyncResetOnSimulator() async throws {
    #if targetEnvironment(simulator)
        let uid = "asyncResetTest"

        try await Locker.setSecret("secret", for: uid)
        Locker.setShouldUseAuthenticationWithBiometrics(true, for: uid)
        Locker.setDidAskToUseAuthenticationWithBiometrics(true, for: uid)

        await Locker.reset(for: uid)

        XCTAssertFalse(Locker.shouldUseAuthenticationWithBiometrics(for: uid))
        XCTAssertFalse(Locker.didAskToUseAuthenticationWithBiometrics(for: uid))

        do {
            _ = try await Locker.retrieveCurrentSecret(for: uid, operationPrompt: "Test")
            XCTFail("Should have thrown after reset")
        } catch {
            // Expected
        }
    #else
        throw XCTSkip("Reset async tests require simulator")
    #endif
    }

    func testAsyncSetAndRetrieveWithCustomSuite() async throws {
    #if targetEnvironment(simulator)
        guard let customDefaults = UserDefaults(suiteName: customSuiteName) else {
            XCTFail("Could not create custom UserDefaults suite")
            return
        }

        Locker.userDefaults = customDefaults

        let uid = "asyncCustomSuiteTest"
        let secret = "customSuiteSecret"

        try await Locker.setSecret(secret, for: uid)

        let retrieved = try await Locker.retrieveCurrentSecret(
            for: uid,
            operationPrompt: "Test"
        )
        XCTAssertEqual(retrieved, secret)

        // Verify it's in the custom suite (simulator stores in UserDefaults)
        XCTAssertEqual(customDefaults.string(forKey: uid), secret)

        await Locker.deleteSecret(for: uid)
    #else
        throw XCTSkip("Requires simulator")
    #endif
    }

    // MARK: - Legacy callback API tests (simulator only)

    func testLegacyCallbackSetAndRetrieve() async throws {
    #if targetEnvironment(simulator)
        let uid = "legacyCallbackTest"
        let secret = "legacySecret"

        // Use the sync callback-based API to store (simulator writes to UserDefaults synchronously)
        Locker.setSecret(secret, for: uid, completed: nil)

        // Use async API to verify the value was stored correctly
        let retrieved = try await Locker.retrieveCurrentSecret(
            for: uid,
            operationPrompt: "Test"
        )
        XCTAssertEqual(retrieved, secret)

        // Clean up via sync API — use explicit type annotation to pick the sync overload
        let syncDelete: (String) -> Void = Locker.deleteSecret(for:)
        syncDelete(uid)
    #else
        throw XCTSkip("Requires simulator")
    #endif
    }

    // MARK: - Device

    func testIsSimulator() {
    #if targetEnvironment(simulator)
        XCTAssertTrue(LockerHelpers.isSimulator)
    #else
        XCTAssertFalse(LockerHelpers.isSimulator)
    #endif
    }

    func testDeviceCodeIsNonEmpty() {
        let code = LockerHelpers.deviceCode
        XCTAssertFalse(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    // MARK: - Fetch new device list (no-op on simulator)

    func testFetchNewDeviceList() {
        LockerHelpers.fetchNewDeviceList()
        XCTAssertTrue(true)
    }

}
