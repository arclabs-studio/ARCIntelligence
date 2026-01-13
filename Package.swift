// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ARCIntelligence",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ARCIntelligence",
            targets: ["ARCIntelligence"]
        ),
        .library(
            name: "ARCIntelligenceMocks",
            targets: ["ARCIntelligenceMocks"]
        )
    ],
    dependencies: [
        // No external dependencies initially
        // ARCLogger will be added later if needed
    ],
    targets: [
        .target(
            name: "ARCIntelligence",
            dependencies: [],
            path: "Sources/ARCIntelligence",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
        .target(
            name: "ARCIntelligenceMocks",
            dependencies: ["ARCIntelligence"],
            path: "Sources/ARCIntelligenceMocks"
        ),
        .testTarget(
            name: "ARCIntelligenceTests",
            dependencies: [
                "ARCIntelligence",
                "ARCIntelligenceMocks"
            ],
            path: "Tests/ARCIntelligenceTests"
        )
    ]
)
