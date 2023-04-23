// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "ParselyAnalytics",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "ParselyAnalytics",
            targets: ["ParselyAnalytics"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", .upToNextMajor(from: "12.0.0"))
    ],
    targets: [
        .target(
            name: "ParselyAnalytics",
            dependencies: [],
            path: "Sources",
            exclude: ["Info.plist"],
            resources: []
        ),
        .testTarget(
            name: "ParselyTrackerTests",
            dependencies: ["ParselyAnalytics", "Nimble"],
            path: "Tests",
            exclude: ["Info.plist", "UnitTests.xctestplan"]
        )
    ]
)
