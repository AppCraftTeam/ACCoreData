// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ACCoreData",
    platforms: [
        .iOS(.v11),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "ACCoreData",
            targets: ["ACCoreData"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ACCoreData",
            dependencies: []
        ),
        .testTarget(
            name: "ACCoreDataTests",
            dependencies: ["ACCoreData"]),
    ]
)
