// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TubeGrab",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TubeGrab",
            path: "Sources/TubeGrab"
        )
    ]
)
