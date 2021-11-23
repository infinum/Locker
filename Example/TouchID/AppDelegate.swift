//
//  AppDelegate.swift
//  TouchID
//
//  Created by Ivan Vecko on 02/03/2018.
//  Copyright © 2018 Infinum Ltd. All rights reserved.
//

import UIKit
import Locker

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.
        Locker.enableDeviceListSync = true
        return true
    }
}
