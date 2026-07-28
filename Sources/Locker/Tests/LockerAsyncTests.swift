//
//  LockerAsyncTests.swift
//  Locker
//

import XCTest

@testable import Locker

@available(iOS 13.0, macOS 10.15, *)
final class LockerAsyncTests: XCTestCase {

    private let uniqueIdentifier = "LockerAsyncTestsIdentifier"
    private let secret = "Async secret"
    private let operationPrompt = "Unlock locker!"

    // MARK: - Setup before & after each test

    override func setUp() {
        super.setUp()
        Locker.deleteSecret(for: uniqueIdentifier)
    }

    override func tearDown() {
        Locker.deleteSecret(for: uniqueIdentifier)
        super.tearDown()
    }

    // MARK: - Tests

    func testStoreAndRetrieveSecret() async throws {
        // Off the simulator these calls reach the real keychain and require an
        // enrolled biometry prompt, so there is nothing deterministic to assert.
        try XCTSkipUnless(Locker.isRunningFromTheSimulator, "Async keychain tests run on the simulator only")

        try await Locker.setSecret(secret, for: uniqueIdentifier)

        let storedSecret = try await Locker.retrieveCurrentSecret(
            for: uniqueIdentifier,
            operationPrompt: operationPrompt
        )

        XCTAssertEqual(storedSecret, secret)
    }

    func testRetrieveMissingSecretThrows() async throws {
        try XCTSkipUnless(Locker.isRunningFromTheSimulator, "Async keychain tests run on the simulator only")

        do {
            _ = try await Locker.retrieveCurrentSecret(
                for: uniqueIdentifier,
                operationPrompt: operationPrompt
            )
            XCTFail("Retrieving a secret that was never stored should throw")
        } catch let error as KeychainError {
            XCTAssertEqual(error.status, errSecItemNotFound)
        }
    }

    func testRetrieveDeletedSecretThrows() async throws {
        try XCTSkipUnless(Locker.isRunningFromTheSimulator, "Async keychain tests run on the simulator only")

        try await Locker.setSecret(secret, for: uniqueIdentifier)

        Locker.deleteSecret(for: uniqueIdentifier)

        do {
            _ = try await Locker.retrieveCurrentSecret(
                for: uniqueIdentifier,
                operationPrompt: operationPrompt
            )
            XCTFail("Retrieving a deleted secret should throw")
        } catch let error as KeychainError {
            XCTAssertEqual(error.status, errSecItemNotFound)
        }
    }
}
