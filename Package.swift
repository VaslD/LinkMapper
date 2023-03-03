// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "LinkMapper",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "link-mapper", targets: ["LinkMapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.2"),
    ],
    targets: [
        .executableTarget(name: "LinkMapper", dependencies: [
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
