// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "StarryLyrics",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "StarryLyricsUI", targets: ["LyricsUI", "LyricsCore"]),
    ],
    targets: [
        .target(
            name: "LyricsCore",
            resources: [
                .copy("Resources/JapaneseReadings"),
            ]
        ),
        .target(name: "LyricsUI", dependencies: ["LyricsCore"]),
    ]
)
