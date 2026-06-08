// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceInk",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "VoiceInk",
            dependencies: [
                "WhisperKit",
            ],
            path: "VoiceInk",
            resources: [
                .copy("Resources/AppLogo.png")
            ]
        ),
    ]
)
