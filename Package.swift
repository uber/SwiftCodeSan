// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "SwiftCodeSan",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "SwiftCodeSan", targets: ["SwiftCodeSan"]),
        .library(name: "SwiftCodeSanKit", targets: ["SwiftCodeSanKit"]),
        ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.0.4")),
        .package(url: "https://github.com/apple/swift-tools-support-core.git", .branch("master")),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .exact("0.50200.0"))
    ],
    targets: [ 
        .target(
            name: "SwiftCodeSan",
            dependencies: [
                "SwiftCodeSanKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                ]),
        .target(
            name: "SwiftCodeSanKit",
            dependencies: [
                .product(name: "SwiftSyntax", package: "SwiftSyntax"),
            ]
        ),
        .testTarget(
            name: "SwiftCodeSanTests",
            dependencies: [
                "SwiftCodeSanKit",
            ],
            path: "Tests"
        )
    ]
)

