//
//  Lockable.swift
//  
//
//  Created by Zvonimir Medak on 01.10.2021..
//

import Foundation

protocol Lockable {

    // MARK: - Properties

    /**
     User defaults used for storing shouldUseAuthenticationWithBiometrics, askToUseAuthenticationWithBiometrics and shouldAddPasscodeToKeychainOnNextLogin values

     Should be set once before using any other Locker methods.
     If not set, standard user defaults will be used.
     */
    static var userDefaults: UserDefaults? { get set }

    /**
     Boolean value that indicates if biometric settings have changed
     */
    static var biometricsSettingsDidChange: Bool { get }

    /**
     Boolean value that indicates if Locker is running from the simulator

     As Simulator does not support Keychain storage, Locker run from the simulator
     will use UserDefaults storage instead.
     */
    static var isRunningFromTheSimulator: Bool { get }

    /**
     The biometrics type that the device supports (None, TouchID, FaceID).
     */
    static var deviceSupportsAuthenticationWithBiometrics: BiometricsType { get }

    /**
     The biometrics type that the device supports which is enabled and configured in the device settings.
     */
    static var configuredBiometricsAuthentication: BiometricsType { get }


    // MARK: - Handle secrets (store, delete, fetch)

    /**
     Used for storing value to Keychain with unique identifier.

     If Locker is run on the Simulator, the secret will not be stored securely in the keychain.
     Instead, the UserDefaults storage will be used.

     @param secret value to store to Keychain
     @param uniqueIdentifier unique key used for storing secret
     */
    static func setSecret(_ secret: String, for uniqueIdentifier: String)

    /**
     Used for retrieving secret from Keychain with unique identifier.
     If operation is successfull, secret is returned. Otherwise, failure status is returned.

     @param uniqueIdentifier unique key used for fetching secret
     @param operationPrompt message showed to the user on TouchID dialog
     @param success completion block returning secret
     @param failure failure block returning failure status
     */
    static func retrieveCurrentSecret(for uniqueIdentifier: String, operationPrompt: String, success: ((String?) -> Void)?, failure: ((OSStatus) -> Void)?)

    /**
     Used for deleting secret from Keychain with unique identifier.

     @param uniqueIdentifier unique key used for deleting secret
     */
    static func deleteSecret(for uniqueIdentifier: String)


    // MARK: - Additional helpers

    /**
     Used for fetching whether user enabled authentication with biometrics.

     @param uniqueIdentifier used for fetching shouldUseAuthenticationWithBiometrics value
     @return used to determine whether user enabled authentication with biometrics
     */
    static func shouldUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool

    /**
     Used for saving whether user enabled authentication with biometrics.

     @param shouldUseAuthenticationWithBiometrics used to determine whether user enabled authentication with biometrics
     @param uniqueIdentifier used for saving shouldUseAuthenticationWithBiometrics value
     */
    static func setShouldUseAuthenticationWithBiometrics(_ shouldUse: Bool, for uniqueIdentifier: String)

    /**
     Used for fetching whether user was asked to use authentication with biometrics.

     @param uniqueIdentifier used for fetching askToUseAuthenticationWithBiometrics value
     @return used to determine whether user was asked to use authentication with biometrics
     */
    static func didAskToUseAuthenticationWithBiometrics(for uniqueIdentifier: String) -> Bool

    /**
     Used for saving whether user was asked to use authentication with biometrics.

     @param askToUseAuthenticationWithBiometrics used to determine whether user was asked to use authentication with biometrics
     @param uniqueIdentifier used for saving askToUseAuthenticationWithBiometrics value
     */
    static func setDidAskToUseAuthenticationWithBiometrics(_ useAuthenticationBiometrics: Bool, for uniqueIdentifier: String)

    /**
     Used for fetching whether secret should be stored to Keychain on next login.

     @param uniqueIdentifier used for fetching shouldAddPasscodeToKeychainOnNextLogin value
     @return used to determine whether secret should be stored to Keychain on next login
     */
    static func shouldAddSecretToKeychainOnNextLogin(for uniqueIdentifier: String) -> Bool

    /**
     Used for saving whether secret should be stored to Keychain on next login.

     @param shouldAddSecretToKeychainOnNextLogin used to determine whether secret should be stored to Keychain on next login
     @param uniqueIdentifier used for saving shouldAddPasscodeToKeychainOnNextLogin value
     */
    static func setShouldAddSecretToKeychainOnNextLogin(_ shouldAdd: Bool, for uniqueIdentifier: String)


    // MARK: - Data reset

    /**
     Used for deleting all stored data for unique identifier.

     @param uniqueIdentifier unique key used for deleting all stored data
     */
    static func reset(for uniqueIdentifier: String)
}
