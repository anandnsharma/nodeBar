// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "nodeBar",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "nodeBar",
            path: "Sources"
        ),
        // Tests require full Xcode (XCTest SDK). Uncomment when Xcode is installed:
        // .testTarget(
        //     name: "nodeBarTests",
        //     dependencies: ["nodeBar"],
        //     path: "Tests"
        // )
    ]
)
