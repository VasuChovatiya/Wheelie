// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wheelie",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Wheelie", targets: ["Wheelie"]),
    ],
    targets: [
        .target(name: "Wheelie", path: "Sources/Wheelie"),
        .testTarget(
            name: "WheelieTests",
            dependencies: ["Wheelie"],
            path: "Tests/WheelieTests",
            // A symlink to spec/test-vectors.json, so both platforms test against one file.
            resources: [.copy("Resources/test-vectors.json")]
        ),
    ]
)
