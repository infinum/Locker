//
//  ViewController.swift
//  TouchID
//
//  Created by Ivan Vecko on 02/03/2018.
//  Copyright © 2018 Infinum Ltd. All rights reserved.
//

import UIKit
import Locker

class ViewController: UIViewController {

    // MARK: - Private properties -

    private let identifier = "TouchIDSampleApp"

    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        checkApplicationSettings()
        storeReadDeleteSecret()
        runAdditionalHelpers()
        resetEverything()
    }
}

// MARK: - Locker usage -

private extension ViewController {

    // MARK: Device settings

    func checkApplicationSettings() {

        let settingsIsChanged = Locker.biometricsSettingsAreChanged
        print("Settings is changed: \(settingsIsChanged)")

        switch Locker.deviceSupportsAuthenticationWithBiometrics {
        case .none:
            print("Device doesnt support Biometrics")
        case .touchID:
            print("Device supports TouchID")
        case .faceID:
            print("Device supports FaceID")
        }

        switch Locker.canUseAuthenticationWithBiometrics {
        case .none:
            print("Device can not use Biometrics")
        case .touchID:
            print("Device can use TouchID")
        case .faceID:
            print("Device can use FaceID")
        }
    }

    // MARK: Read Write Delete

    func storeReadDeleteSecret() {
        Locker.setSecret("1234", for: identifier)
        Locker.retrieveCurrentSecret(
            for: identifier,
            operationPrompt: "Unlock locker!",
            success: { (secret) in
                print(secret ?? "Missing data!")
        }, failure: {failureReason in
            print("Failed because: \(failureReason)")
        }
        )
        Locker.deleteSecret(for: identifier)
    }

    // MARK: Helpers

    func runAdditionalHelpers() {
        Locker.setShouldUseAuthenticationWithBiometrics(true, forUniqueIdentifier: identifier)
        let shouldUseAuthenticationWithBiometrics = Locker.shouldUseAuthenticationWithBiometrics(for: identifier)
        print("Should Use Authentication With Biometrics: \(shouldUseAuthenticationWithBiometrics)")

        Locker.setDidAskToUseAuthenticationWithBiometrics(true, forUniqueIdentifier: identifier)
        let setDidAskToUseAuthenticationWithBiometrics = Locker.didAskToUseAuthenticationWithBiometrics(for: identifier)
        print("Should Use Authentication With Biometrics: \(setDidAskToUseAuthenticationWithBiometrics)")

        Locker.setShouldAddSecretToKeychainOnNextLogin(true, forUniqueIdentifier: identifier)
        let shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier = Locker.shouldAddSecretToKeychainOnNextLogin(for: identifier)
        print("Should Use Authentication With Biometrics: \(shouldAddSecretToKeychainOnNextLoginForUniqueIdentifier)")
    }

    // MARK: Reseting

    func resetEverything() {
        Locker.reset(for: identifier)
    }
}
