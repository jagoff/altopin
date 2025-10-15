// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "AlwaysOnTop",
    platforms: [
        .macOS(.v10_15)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AlwaysOnTop",
            dependencies: [],
            path: "AlwaysOnTop"
        )
    ]
)
