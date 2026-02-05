//
//  BundleHelpers.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation

final class BundleHelpers: Sendable {

    // MARK: - Private properties

    /// Lock for thread-safe file operations
    private static let fileLock = NSLock()

    // MARK: - Public properties

    static var bundleResource: Bundle? {
        guard let resourceBundleURL = Bundle(for: Self.self).url(forResource: "Locker_Locker", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL)
        else { return nil }
        return resourceBundle
    }

    static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// MARK: - Internal extension -

extension BundleHelpers {

    static func write(_ data: Data, to url: URL) {
        // we'll have periodic updates to the library so we don't want to throw errors
        guard let decodedResponse = try? BundleHelpers.decoder.decode(DeviceResponse.self, from: data),
              let encodedData = try? JSONEncoder().encode(decodedResponse)
        else { return }
        fileLock.lock()
        defer { fileLock.unlock() }
        try? encodedData.write(to: url)
    }

    static func readFromJSON(_ name: String) -> Data? {
        fileLock.lock()
        defer { fileLock.unlock() }
        guard let path = BundleHelpers.bundleResource?.path(forResource: name, ofType: "json"),
              let data = try? String(contentsOfFile: path).data(using: .utf8)
        else { return nil }
        return data
    }

    static func getFileURL(for name: String, with nameExtension: String) -> URL? {
        return BundleHelpers.bundleResource?.url(forResource: name, withExtension: nameExtension)
    }
}
