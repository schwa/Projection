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
    dependencies: [
        .package(url: "https://github.com/schwa/SwiftGraphics", branch: "jwight/develop"),
    ],
    targets: [
        .target(
            name: "Projection",
            dependencies: [.product(name: "SIMDSupport", package: "SwiftGraphics")]
            ),
        .testTarget(
            name: "ProjectionTests",
            dependencies: ["Projection"]),
    ]
)
