//
//  Locker+ObjectiveC.swift
//  Locker
//
//  Created by Zvonimir Medak on 09.11.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation

public extension Locker {

    /**
     Used for storing value to Keychain with unique identifier.

     - Parameters:
        - secret: value to store to Keychain
        - uniqueIdentifier: unique key used for storing secret
        - completed: completion block returning an error if something went wrong
     */
    @available(swift, obsoleted: 1.0)
    @objc(setSecret:forUniqueIdentifier:completion:)
    static func setSecret(
        _ secret: String,
        for uniqueIdentifier: String,
        completed: ((NSError?) -> Void)? = nil
    ) {
        setSecretForDevice(secret, for: uniqueIdentifier, completion: { error in
            DispatchQueue.main.async {
                completed?(error?.asNSError)
            }
        })
    }

}
