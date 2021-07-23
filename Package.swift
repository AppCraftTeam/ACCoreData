// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ACCoreData",
    platforms: [
        .iOS(.v11),
    ],
    products: [
        .library(
            name: "ACCoreData",
            targets: ["ACCoreData"]),
    ],
    dependencies: [
        .package(
            name: "ACExtensions",
            url: "https://github.com/AppCraftTeam/ACExtensions.git",
            .upToNextMajor(from: "1.0.0")
        )
    ],
    targets: [
        .target(
            name: "ACCoreData",
            dependencies: ["ACExtensions"]),
        .testTarget(
            name: "ACCoreDataTests",
            dependencies: ["ACCoreData"]),
    ]
)
