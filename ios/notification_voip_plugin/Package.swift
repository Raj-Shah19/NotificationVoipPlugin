// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to
// build this package and the Flutter Swift Package Manager integration.

import PackageDescription

let package = Package(
    name: "notification_voip_plugin",
    platforms: [
        .iOS("14.0")
    ],
    products: [
        .library(name: "notification-voip-plugin", targets: ["notification_voip_plugin"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "notification_voip_plugin",
            dependencies: [],
            resources: [
                .process("Resources/PrivacyInfo.xcprivacy")
            ]
        )
    ]
)
