// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Throttling",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "Throttling", targets: ["Throttling"])
    ],
    targets: [
        .target(name: "Throttling"),
        .testTarget(name: "ThrottlingTests", dependencies: ["Throttling"])
    ]
)
