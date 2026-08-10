// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SoundDuck",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "SoundDuck", path: "Sources/SoundDuck")
    ]
)
