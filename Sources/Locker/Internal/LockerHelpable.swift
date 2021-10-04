//
//  LockerHelpable.swift
//  
//
//  Created by Zvonimir Medak on 04.10.2021..
//

import Foundation

@available(macOS 10.12.2, *)
protocol LockerHelpable {

    // Check device support

    static var biometricsSettingsChanged: Bool { get }
    static var deviceSupportsAuthenticationWithBiometrics: BiometricsType { get }
    static var configureBiometricsAuthentication: BiometricsType { get }
    static var keyLAPolicyDomainState: String { get }
    static var canUserAuthenticationWithFaceID: Bool { get }
    static var deviceCode: String { get }
    static var deviceSupportsAuthenticationWithFaceID: Bool { get }
    static var isSimulator: Bool { get }

    // LAPolicy helpers
    @available(macOS 10.12.2, *)
    static func storeCurrentLAPolicyDomainState()

    // UserDefaults helpers

    static var keyKeychainServiceName: String { get }
    static func keyKeychainAccountName(for uniqueIdentifier: String) -> String
    static func keyDidAskToUserBiometricsID(for uniqueIdentifier: String) -> String
    static func keyBiometricsIDActivated(for uniqueIdentifier: String) -> String
    static func keyShouldAddSecretToKeychainOnNextLogin(for uniqueIdentifier: String) -> String
}
