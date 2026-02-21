// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TinyKana",
    platforms: [.macOS(.v12)],
    targets: [
        .executableTarget(
            name: "TinyKana",
            path: "Sources"
        )
    ]
)
