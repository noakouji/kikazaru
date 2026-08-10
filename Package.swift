// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Kikazaru",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(name: "Kikazaru", path: "Sources/Kikazaru")
    ]
)
