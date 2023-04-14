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
    dependencies: [],
    targets: [
        .target(
            name: "ParselyAnalytics",
            dependencies: [],
            path: "ParselyTracker",
            resources: []
        ),
        .testTarget(
            name: "ParselyTrackerTests",
            dependencies: ["ParselyAnalytics"],
            path: "ParselyTrackerTests"
        )
    ]
)
