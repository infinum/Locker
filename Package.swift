// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Locker",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "Locker",
            targets: ["Locker"]
        )
    ],
    targets: [
        .target(
            name: "Locker",
            path: "Sources/Locker",
            exclude: ["Tests"], // exclude test sources so Locker module doesn't depend on XCTest
            resources: [
                .process("Helpers/BiometryAvailabilityDeviceList.json"),
                .copy("SupportingFiles/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "LockerTests",
            dependencies: ["Locker"],
            path: "Sources/Locker/Tests" // use the existing test folder inside Locker
        )
    ]
)
