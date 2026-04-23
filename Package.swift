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
        .executable(name: "SoundRemover", targets: ["SoundRemover"])
    ],
    targets: [
        .target(
            name: "SoundRemoverCore",
            dependencies: []
        ),
        .executableTarget(
            name: "SoundRemover",
            dependencies: ["SoundRemoverCore"],
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
        .testTarget(
            name: "SoundRemoverCoreTests",
            dependencies: ["SoundRemoverCore"]
        ),
        .testTarget(
            name: "SoundRemoverTests",
            dependencies: ["SoundRemover"]
        )
    ]
)
