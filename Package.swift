// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Minar",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Minar",
            swiftSettings: [
                .enableUpcomingFeature("ApproachableConcurrency"),
            ]
        ),
    ]
)
