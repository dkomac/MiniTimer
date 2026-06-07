// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MiniTimer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "MiniTimerCore", targets: ["MiniTimerCore"]),
        .executable(name: "MiniTimerApp", targets: ["MiniTimerApp"])
    ],
    targets: [
        .target(name: "MiniTimerCore"),
        .executableTarget(
            name: "MiniTimerApp",
            dependencies: ["MiniTimerCore"]
        ),
        .testTarget(
            name: "MiniTimerCoreTests",
            dependencies: ["MiniTimerCore"]
        )
    ]
)
