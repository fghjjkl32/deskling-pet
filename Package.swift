// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Deskling",
    platforms: [.macOS(.v13)],
    targets: [
        .target(name: "DesklingCore"),
        .executableTarget(name: "Deskling", dependencies: ["DesklingCore"]),
        .testTarget(name: "DesklingCoreTests", dependencies: ["DesklingCore"]),
    ]
)
