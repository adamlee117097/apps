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
            // Not named "Resources": Foundation reads a folder of that name as a bundle layout marker, and it is
            // reported (not yet confirmed on a Mac) to make code signing reject the bundle on Apple platforms.
            resources: [.copy("Data")]
        ),
        .testTarget(
            name: "NecroRulesTests",
            dependencies: ["NecroRules"]
        ),
    ]
)
