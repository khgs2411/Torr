// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Torr",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Torr",
            path: "Sources/Torr",
            exclude: ["Resources/Info.plist"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "TorrTests",
            dependencies: ["Torr"],
            path: "Tests/TorrTests",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
