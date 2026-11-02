// swift-tools-version: 6.0
import PackageDescription
import AppleProductTypes

let package = Package(
    name: "WheelieDemo",
    platforms: [.iOS("17.0")],
    products: [
        .iOSApplication(
            name: "WheelieDemo",
            targets: ["App"],
            bundleIdentifier: "com.vasuchovatiya.WheelieDemo",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [.phone, .pad],
            supportedInterfaceOrientations: [.portrait]
        )
    ],
    dependencies: [
        // The library at the repo root.
        .package(path: "../../..")
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [.product(name: "Wheelie", package: "Wheelie")],
            path: "Sources"
        )
    ]
)
