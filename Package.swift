// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "sidle",
    platforms: [.macOS(.v12)],
    dependencies: [
         .package(url: "https://github.com/jdhealy/PrettyColors", from: "5.0.2"),
    ],
    targets: [
        .executableTarget(
            name: "sidle",
            dependencies: ["PrettyColors"]),
        .testTarget(
            name: "sidleTests",
            dependencies: ["sidle"]),
    ]
)
