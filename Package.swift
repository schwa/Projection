// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Projection",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .macCatalyst(.v17),
        .tvOS(.v17),
        .visionOS(.v1),
    ],
    products: [
        .library(
            name: "Projection",
            targets: ["Projection"]),
    ],
    targets: [
        .target(
            name: "Projection"),
        .testTarget(
            name: "ProjectionTests",
            dependencies: ["Projection"]),
    ]
)
