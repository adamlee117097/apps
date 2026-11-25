// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NecroRules",
    products: [
        .library(name: "NecroRules", targets: ["NecroRules"])
    ],
    targets: [
        .target(
            name: "NecroRules",
            resources: [.copy("Resources")]
        ),
        .testTarget(
            name: "NecroRulesTests",
            dependencies: ["NecroRules"]
        ),
    ]
)
