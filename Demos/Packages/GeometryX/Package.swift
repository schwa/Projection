// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "GeometryX",
    platforms: [
        .macOS(.v14),
        .tvOS(.v17),
        .iOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "GeometryX", targets: ["GeometryX"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-algorithms", from: "1.2.0"),
        .package(url: "https://github.com/schwa/earcut-swift", branch: "main"),
        .package(url: "https://github.com/schwa/SwiftGraphics", branch: "jwight/develop"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "GeometryX",
            dependencies: [
                .product(name: "Algorithms", package: "swift-algorithms"),
                .product(name: "earcut", package: "earcut-swift"),
                .product(name: "CoreGraphicsSupport", package: "SwiftGraphics"),
                .product(name: "SIMDSupport", package: "SwiftGraphics"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .testTarget(
            name: "GeometryTests",
            dependencies: ["GeometryX"],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        ),
        .executableTarget(
            name: "TrivialMeshCLI",
            dependencies: [
                "GeometryX",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            swiftSettings: [.interoperabilityMode(.Cxx)]
        )
    ]
)
