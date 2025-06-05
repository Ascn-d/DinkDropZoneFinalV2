// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DinkDrop",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .iOSApplication(
            name: "DinkDrop",
            targets: ["App"],
            bundleIdentifier: "com.example.DinkDrop",
            teamIdentifier: nil,
            displayVersion: "0.1",
            bundleVersion: "1",
            accentColorName: "AccentColor",
            supportedDeviceFamilies: [
                .phone,
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown,
                .landscapeLeft,
                .landscapeRight
            ]
        )
    ],
    targets: [
        .target(
            name: "App",
            dependencies: ["Models", "Services", "ViewModels", "Views"],
            path: "Sources/App",
            resources: [
                .assetCatalog(name: "Assets.xcassets")
            ]
        ),
        .target(
            name: "Models",
            path: "Sources/Models"
        ),
        .target(
            name: "Services",
            dependencies: ["Models"],
            path: "Sources/Services"
        ),
        .target(
            name: "ViewModels",
            dependencies: ["Models", "Services"],
            path: "Sources/ViewModels"
        ),
        .target(
            name: "Views",
            dependencies: ["ViewModels", "Models"],
            path: "Sources/Views"
        ),
        .testTarget(
            name: "EloCalculatorTests",
            dependencies: ["Services"],
            path: "Tests"
        )
    ]
) 