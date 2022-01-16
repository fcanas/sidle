// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "sidle",
    platforms: [.macOS("10.15.4"), .iOS(.v9), .tvOS(.v9), .watchOS(.v2)],
    products: [
        .executable(name: "sidle", targets: ["sidle"]),
        .library(name: "SidleCore", targets: ["SidleCore"])
    ],
    dependencies: [
         .package(url: "https://github.com/jdhealy/PrettyColors", from: "5.0.2"),
    ],
    targets: [
        .target(
            name: "SidleCore",
            dependencies: ["PrettyColors"]
        ),
        .executableTarget(
            name: "sidle",
            dependencies: ["SidleCore", "PrettyColors"]
            ),
        .testTarget(
            name: "sidleTests",
            dependencies: ["sidle"]),
        .testTarget(
            name: "SidleCoreTests",
            dependencies: ["SidleCore"]),
    ]
)
