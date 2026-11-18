// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "TTLChanger",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "TTLChanger",
            path: "Sources/TTLChanger"
        )
    ]
)
