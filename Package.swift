// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FHKFirebase",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "FHKFirebase",
            targets: ["FHKFirebase"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git",
            .upToNextMajor(from: "12.6.0")),
        
        .package(url: "https://github.com/leonodev/fintechKids-modulo-domain-ios.git",
                branch: "main"),
        
            .package(url: "https://github.com/leonodev/fintechKids-modulo-utils-ios.git",
                     branch: "main")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FHKFirebase",
            dependencies: [
                // Modules Firebase
                .product(name: "FirebaseAnalytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseCrashlytics", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk"),
                .product(name: "FirebaseMessaging", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                
                // Modules FHK
                .product(name: "FHKDomain", package: "fintechKids-modulo-domain-ios"),
                .product(name: "FHKUtils", package: "fintechKids-modulo-utils-ios")
            ]
        ),
        .testTarget(
            name: "FHKFirebaseTests",
            dependencies: ["FHKFirebase"]
        ),
    ]
)
