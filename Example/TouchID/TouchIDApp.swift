//
//  TouchIDApp.swift
//  TouchID
//
//  Copyright © 2026 Infinum Ltd. All rights reserved.
//

import SwiftUI
import Locker

@main
struct TouchIDApp: App {

    // MARK: - Lifecycle -

    init() {
        Locker.enableDeviceListSync = true
    }

    // MARK: - Body -

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
