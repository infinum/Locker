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

    // MARK: - Setup before & after each test
    
    override func setUp() {
        super.setUp()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LockerHelpers.keyCustomKeychainService)
        defaults.removeObject(forKey: LockerHelpers.keyLAPolicyDomainState)
    }
    
    override func tearDown() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: LockerHelpers.keyCustomKeychainService)
        defaults.removeObject(forKey: LockerHelpers.keyLAPolicyDomainState)
        super.tearDown()
    }
    
    // MARK: - Keychain
    
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
        UserDefaults.standard.set(override, forKey: LockerHelpers.keyCustomKeychainService)
        let got = LockerHelpers.keyKeychainServiceName
        XCTAssertEqual(got, override)
    }
    
    // MARK: - Device
    
    func testIsSimulator() {
        // Matches compilation environment
#if targetEnvironment(simulator)
        XCTAssertTrue(LockerHelpers.isSimulator)
#else
        XCTAssertFalse(LockerHelpers.isSimulator)
#endif
    }
    
    func testDeviceCodeIsNonEmpty() {
        // getDeviceIdentifierFromSystem() returns machine identifier (e.g., "arm64", "x86_64", "iPhone15,3", etc.)
        let code = LockerHelpers.deviceCode
        XCTAssertFalse(code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
    
    // MARK: - Fetch new device list (no-op on simulator)
    
    func testFetchNewDeviceList() {
        // On simulator the method body is compiled out; this just ensures calling it won't explode.
        LockerHelpers.fetchNewDeviceList()
        XCTAssertTrue(true)
    }

}
