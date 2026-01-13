// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ARCIntelligenceShowcase",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "ARCIntelligenceShowcase",
            targets: ["ARCIntelligenceShowcase"]
        )
    ],
    dependencies: [
        // Reference the local ARCIntelligence package
        .package(name: "ARCIntelligence", path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "ARCIntelligenceShowcase",
            dependencies: [
                .product(name: "ARCIntelligence", package: "ARCIntelligence"),
                .product(name: "ARCIntelligenceMocks", package: "ARCIntelligence")
            ],
            path: "ARCIntelligenceShowcase",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
