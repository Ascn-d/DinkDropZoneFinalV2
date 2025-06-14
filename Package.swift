// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "DinkDropZoneFinal",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "DinkDropZoneFinal",
            targets: ["DinkDropZoneFinal"]),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.0"),
    ],
    targets: [
        .target(
            name: "DinkDropZoneFinal",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestoreSwift", package: "firebase-ios-sdk"),
            ]),
        .testTarget(
            name: "DinkDropZoneFinalTests",
            dependencies: ["DinkDropZoneFinal"]),
    ]
) 