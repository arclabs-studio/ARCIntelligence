// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ARCIntelligence",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
        .tvOS(.v14),
        .watchOS(.v7)
    ],
    products: [
        .library(
            name: "ARCIntelligence",
            targets: ["ARCIntelligence"]
        ),
    ],
    targets: [
        .target(
            name: "ARCIntelligence",
            path: "Sources"
        ),
        .testTarget(
            name: "ARCIntelligenceTests",
            dependencies: ["ARCIntelligence"],
            path: "Tests"
        )
    ]
)
