// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Locker",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Locker",
            targets: ["Locker"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Locker",
            path: "Sources/Locker",
            exclude: ["Tests"], // exclude test sources so Locker module doesn't depend on XCTest
            resources: [
                .process("Helpers/BiometryAvailabilityDeviceList.json"),
                .copy("SupportingFiles/PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "LockerTests",
            dependencies: ["Locker"],
            path: "Sources/Locker/Tests" // use the existing test folder inside Locker
        )
    ]
)
