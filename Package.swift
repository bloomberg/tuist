// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "tuist",
    products: [
        .executable(name: "tuist", targets: ["tuist"]),
        .executable(name: "tuistenv", targets: ["tuistenv"]),
        .library(name: "ProjectDescription",
                 type: .dynamic,
                 targets: ["ProjectDescription"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tuist/xcodeproj.git", .upToNextMinor(from: "6.3.0")),
        .package(url: "https://github.com/apple/swift-package-manager", .revision("a107d28d1b40491cf505799a046fee53e7c422e1")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMinor(from: "1.0.1")),
    ],
    targets: [
        .target(
            name: "TuistGenerator",
            dependencies: ["xcodeproj", "Utility", "TuistCore", "Yams", "ProjectDescription"]
        ),
        .target(
            name: "TuistKit",
            dependencies: ["xcodeproj", "Utility", "TuistCore", "Yams", "TuistGenerator"]
        ),
        .testTarget(
            name: "TuistKitTests",
            dependencies: ["TuistKit", "TuistCoreTesting"]
        ),
        .target(
            name: "tuist",
            dependencies: ["TuistKit"]
        ),
        .target(
            name: "TuistEnvKit",
            dependencies: ["Utility", "TuistCore", "ProjectDescription"]
        ),
        .testTarget(
            name: "TuistEnvKitTests",
            dependencies: ["TuistEnvKit", "TuistCoreTesting"]
        ),
        .target(
            name: "tuistenv",
            dependencies: ["TuistEnvKit"]
        ),
        .target(
            name: "ProjectDescription",
            dependencies: []
        ),
        .testTarget(
            name: "ProjectDescriptionTests",
            dependencies: ["ProjectDescription"]
        ),
        .target(
            name: "TuistCore",
            dependencies: ["Utility"]
        ),
        .target(
            name: "TuistCoreTesting",
            dependencies: ["TuistCore"]
        ),
        .testTarget(
            name: "TuistCoreTests",
            dependencies: ["TuistCore", "TuistCoreTesting"]
        ),
        .testTarget(
            name: "TuistGeneratorTests",
            dependencies: ["TuistGenerator", "TuistCoreTesting"]
        ),
    ]
)
