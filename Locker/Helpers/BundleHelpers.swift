//
//  BundleHelpers.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation

class BundleHelpers {

    // MARK: - Public properties

    public static var bundleResource: Bundle? {
        guard let resourceBundleURL = Bundle(for: Self.self).url(forResource: "Locker", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL) else { return nil }
        return resourceBundle
    }

    public static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }
}

// MARK: - Public extension -

extension BundleHelpers {

    public static func write(_ data: Data, to url: URL) {
        // we'll have periodic updates to the library so we don't want to throw errors
        guard let decodedResponse = try? BundleHelpers.decoder.decode(DeviceResponse.self, from: data),
              let encodedData = try? JSONEncoder().encode(decodedResponse)
        else { return }
        try? encodedData.write(to: url)
    }

    static func readFromJSON(_ name: String) -> Data? {
        guard let path = BundleHelpers.bundleResource?.path(forResource: name, ofType: "json"),
        let data = try? String(contentsOfFile: path).data(using: .utf8)
        else { return nil }
        return data
    }

    public static func getFileURL(for name: String, with nameExtension: String) -> URL? {
        return BundleHelpers.bundleResource?.url(forResource: name, withExtension: nameExtension)
    }
}
