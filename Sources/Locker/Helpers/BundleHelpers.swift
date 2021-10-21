//
//  BundleHelpers.swift
//  Locker
//
//  Created by Zvonimir Medak on 20.10.2021..
//  Copyright © 2021 Infinum. All rights reserved.
//

import Foundation

class BundleHelpers {

    public static var bundleResource: Bundle? {
        let myBundle = Bundle(for: Self.self)
        guard let resourceBundleURL = myBundle.url(forResource: "Locker", withExtension: "bundle"),
              let resourceBundle = Bundle(url: resourceBundleURL) else { return nil }
        return resourceBundle
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    public static func write(_ data: Data, to url: URL) {
        // we'll have periodic updates to the library so we don't want to throw errors
        do {
            let decodedResponse = try BundleHelpers.decoder.decode(DeviceResponse.self, from: data)
            let encodedData = try? JSONEncoder().encode(decodedResponse)
            try encodedData!.write(to: url)
        } catch {
        }
    }
}

extension BundleHelpers {

    static func readFromJSON(_ name: String) -> Data? {
        do {
            if let bundlePath = BundleHelpers.bundleResource?.path(forResource: name, ofType: "json"),
               let jsonData = try String(contentsOfFile: bundlePath).data(using: .utf8) {
                return jsonData
            }
        } catch {
            return nil
        }

        return nil
    }

    static func parse<T: Codable>(jsonData: Data) -> T? {
        do {
            return try BundleHelpers.decoder.decode(T.self, from: jsonData)
        } catch {
            return nil
        }
    }
}
