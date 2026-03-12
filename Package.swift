// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(name: "ARCIntelligence",
                      platforms: [.iOS(.v17),
                                  .macOS(.v14),
                                  .visionOS(.v1)],
                      products: [.library(name: "ARCIntelligence",
                                          targets: ["ARCIntelligence"]),
                                 .library(name: "ARCIntelligenceMocks",
                                          targets: ["ARCIntelligenceMocks"])],
                      dependencies: [.package(url: "https://github.com/arclabs-studio/ARCLogger", from: "1.0.0"),
                                     .package(url: "https://github.com/arclabs-studio/ARCNetworking", from: "1.0.0")],
                      targets: [.target(name: "ARCIntelligence",
                                        dependencies: ["ARCLogger", "ARCNetworking"],
                                        path: "Sources/ARCIntelligence"),
                                .target(name: "ARCIntelligenceMocks",
                                        dependencies: ["ARCIntelligence"],
                                        path: "Sources/ARCIntelligenceMocks"),
                                .testTarget(name: "ARCIntelligenceTests",
                                            dependencies: ["ARCIntelligence",
                                                           "ARCIntelligenceMocks"],
                                            path: "Tests/ARCIntelligenceTests")],
                      swiftLanguageModes: [.v6])
