// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VaporLite",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VaporLite",
            targets: ["VaporLite"]),
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/redis.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.0.0"),
        .package(url: "https://github.com/linhay/STJSON", from: "1.0.5"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.7.0")),
        .package(url: "https://github.com/apple/swift-http-types.git", .upToNextMajor(from: "1.0.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VaporLite",
            dependencies: [
                .product(name: "Redis", package: "redis"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "STJSON", package: "STJSON"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
                .product(name: "HTTPTypes", package: "swift-http-types")
            ]),
        .testTarget(
            name: "VaporLiteTests",
            dependencies: ["VaporLite"]),
    ]
)
