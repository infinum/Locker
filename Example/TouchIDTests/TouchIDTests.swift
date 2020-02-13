//
//  TouchIDTests.swift
//  TouchIDTests
//
//  Created by Ivan Vecko on 02/03/2018.
//  Copyright © 2018 Infinum Ltd. All rights reserved.
//

import XCTest
@testable import TouchID

class TouchIDTests: XCTestCase {

    private var containerViewController: ViewController!

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        containerViewController = ViewController()
    }

    override func tearDown() {
        containerViewController.resetUserDefaults()
        super.tearDown()
    }

    // MARK: - Store Retrieve and Delete -
    func testStoreAndRetrieveSecret() {

        // Store
        containerViewController.storeSecret()

        // Retrieve
        let asyncExpectation = expectation(description: "Async block executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.containerViewController.readSecret(success: { (secret) in
                XCTAssertEqual(secret, self.containerViewController.topSecret)
                asyncExpectation.fulfill()
            }, failure: { _ in
                XCTFail("Error while retrieve the secret")
                asyncExpectation.fulfill()
            })
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testStoreAndRetrieveSecretWithCustomUserDefaults() {

        containerViewController.setCustomUserDefaults()

        // Store
        containerViewController.storeSecret()

        // Retrieve
        let asyncExpectation = expectation(description: "Async block executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.containerViewController.readSecret(success: { (secret) in
                XCTAssertEqual(secret, self.containerViewController.topSecret)
                asyncExpectation.fulfill()
            }, failure: { _ in
                XCTFail("Error while retrieve the secret")
                asyncExpectation.fulfill()
            })
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    func testDeleteSecret() {

        // Store
        containerViewController.storeSecret()

        // Delete
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.containerViewController.deleteSecret()
        }

        // Retrieve
        let asyncExpectation = expectation(description: "Async block executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.containerViewController.readSecret(success: { (secret) in
                XCTFail("Data should not be available")
                asyncExpectation.fulfill()
            }, failure: { _ in
                XCTAssertTrue(true, "Data succesfully deleted")
                asyncExpectation.fulfill()
            })
        }

        waitForExpectations(timeout: 3, handler: nil)
    }

    // MARK: - Device settings -

    func testSettingsChanged() {
        XCTAssertFalse(containerViewController.settingsChanged)
    }

    func testRunningFromTheSimulator() {
        XCTAssertTrue(containerViewController.runningFromTheSimulator)
    }

    func testDeviceSupportsAuthenticationWithBiometrics() {
        XCTAssertTrue(containerViewController.deviceSupportsAuthenticationWithBiometrics == .none)
    }

    func testConfiguredBiometricsAuthentication() {
        XCTAssertTrue(containerViewController.configuredBiometricsAuthentication == .none)
    }

    // MARK: - Helpers -
    
    func testShouldUseAuthFlag() {
        containerViewController.shouldUseAuthWithBiometrics = true
        XCTAssertTrue(containerViewController.shouldUseAuthWithBiometrics)
    }

    func testShouldUseAuthFlagWithCustomUserDefaults() {
        containerViewController.setCustomUserDefaults()
        containerViewController.shouldUseAuthWithBiometrics = true
        XCTAssertTrue(containerViewController.shouldUseAuthWithBiometrics)
    }

    func testDidAskToUseAuthWithBiometrics() {
        containerViewController.didAskToUseAuthWithBiometrics = true
        XCTAssertTrue(containerViewController.didAskToUseAuthWithBiometrics)
    }

    func testDidAskToUseAuthWithBiometricsWithCustomUserDefaults() {
        containerViewController.setCustomUserDefaults()
        containerViewController.didAskToUseAuthWithBiometrics = true
        XCTAssertTrue(containerViewController.didAskToUseAuthWithBiometrics)
    }

    func testShouldAddSecretToKeychainOnNextLogin() {
        containerViewController.shouldAddSecretToKeychainOnNextLogin = true
        XCTAssertTrue(containerViewController.shouldAddSecretToKeychainOnNextLogin)
    }

    func testShouldAddSecretToKeychainOnNextLoginWithCustomUserDefaults() {
        containerViewController.setCustomUserDefaults()
        containerViewController.shouldAddSecretToKeychainOnNextLogin = true
        XCTAssertTrue(containerViewController.shouldAddSecretToKeychainOnNextLogin)
    }

    // MARK: - Reseting -

    func testResetAll() {

        // Store some data
        containerViewController.shouldUseAuthWithBiometrics = true
        containerViewController.didAskToUseAuthWithBiometrics = true
        containerViewController.shouldAddSecretToKeychainOnNextLogin = true
        containerViewController.storeSecret()

        // Reset locker
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.containerViewController.resetEverything()
        }

        // Check if everything is reseted
        let asyncExpectation = expectation(description: "Async block executed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.containerViewController.readSecret(success: { (secret) in
                XCTFail("Data should not be available")
                asyncExpectation.fulfill()
            }, failure: { _ in

                let shouldUseAuth = self.containerViewController.shouldUseAuthWithBiometrics
                let didAskToUseAuth = self.containerViewController.didAskToUseAuthWithBiometrics
                let shouldAddSecretOnNextLogin = self.containerViewController.shouldAddSecretToKeychainOnNextLogin

                let allReseted = shouldUseAuth || didAskToUseAuth || shouldAddSecretOnNextLogin

                XCTAssertFalse(allReseted, "Locker succesfully reseted")

                asyncExpectation.fulfill()
            })
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
