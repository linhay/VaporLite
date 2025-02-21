// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VaporLite",
    platforms: [
        .macOS(.v13),
        .iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "VaporLite",
            targets: ["VaporLite"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.10.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.1"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.65.0"),
        .package(url: "https://github.com/vapor/queues.git", from: "1.16.1"),
        .package(url: "https://github.com/vapor/redis.git", from: "4.11.0"),
        .package(url: "https://github.com/vapor/fluent.git", from: "4.12.0"),
        .package(url: "https://github.com/linhay/STJSON", from: "1.2.0"),
        .package(url: "https://github.com/AxApp/OpenAICore", from: "1.5.2"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.3"),
        .package(url: "https://github.com/apple/swift-http-types.git", from: "1.3.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "VaporLite",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "NIOPosix", package: "swift-nio"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "Queues", package: "queues"),
                .product(name: "Redis", package: "redis"),
                .product(name: "Fluent", package: "fluent"),
                .product(name: "OpenAICore", package: "OpenAICore"),
                .product(name: "CryptoSwift", package: "CryptoSwift"),
                .product(name: "STJSON", package: "STJSON"),
                .product(name: "HTTPTypesFoundation", package: "swift-http-types"),
                .product(name: "HTTPTypes", package: "swift-http-types")
            ]),
        .testTarget(
            name: "VaporLiteTests",
            dependencies: ["VaporLite"]),
    ]
)
