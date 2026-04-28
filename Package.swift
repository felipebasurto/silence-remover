// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "SoundRemover",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "SoundRemoverCore", targets: ["SoundRemoverCore"]),
        .library(name: "SoundRemoverUI", targets: ["SoundRemoverUI"]),
        .executable(name: "SoundRemover", targets: ["SoundRemover"])
    ],
    targets: [
        .target(
            name: "SoundRemoverCore",
            dependencies: []
        ),
        .target(
            name: "SoundRemoverUI",
            dependencies: ["SoundRemoverCore"],
            path: "Sources/SoundRemover",
            exclude: [
                "Resources/AppIcon.iconset",
                "Resources/AppIcon.png",
                "Resources/AppIcon.icns"
            ],
            resources: [
                .process("Resources/en.lproj"),
                .process("Resources/es.lproj"),
                .process("Resources/SkeuoPanel.png"),
                .copy("Resources/ffmpeg")
            ]
        ),
        .executableTarget(
            name: "SoundRemover",
            dependencies: ["SoundRemoverUI"],
            path: "Sources/SoundRemoverCLI"
        ),
        .testTarget(
            name: "SoundRemoverCoreTests",
            dependencies: ["SoundRemoverCore"]
        ),
        .testTarget(
            name: "SoundRemoverTests",
            dependencies: ["SoundRemoverUI"]
        )
    ]
)
