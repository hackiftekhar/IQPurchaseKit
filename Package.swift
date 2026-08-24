// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "IQPurchaseKit",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "IQPurchaseKit",
            targets: ["IQPurchaseKit"]
        )
    ],
    targets: [
        .target(name: "IQPurchaseKit",
            path: "IQPurchaseKit",
            resources: [
                .copy("Assets/PrivacyInfo.xcprivacy")
            ],
            linkerSettings: [
                .linkedFramework("StoreKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("Security"),
                .linkedFramework("UIKit")
            ]
        )
    ]
)
