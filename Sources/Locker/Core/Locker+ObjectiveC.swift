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
    Sets a `secret` for a specified unique identifier

    - Parameters:
     - secret: the value you want to store to UserDefaults
     - uniqueIdentifier: the identifier you want to use when retrieving the value
     - completed: closure that is called upon finished secret storage. If the error occurs upon storing,
        info will be passed through the completion block
     */
    @available(swift, obsoleted: 1.0)
    @objc(setSecret:forUniqueIdentifier:completion:)
    static func setSecret(
        _ secret: String,
        for uniqueIdentifier: String,
        completed: ((NSError?) -> Void)? = nil
    ) {
    #if targetEnvironment(simulator)
        Locker.userDefaults?.set(secret, forKey: uniqueIdentifier)
    #else
        setSecretForDevice(secret, for: uniqueIdentifier, completion: { error in
            completed?(error?.asNSError)
        })
    #endif
    }

}
