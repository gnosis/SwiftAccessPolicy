// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "SwiftAccessPolicy",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftAccessPolicy",
            targets: ["SwiftAccessPolicy"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftAccessPolicy"
        ),
        .testTarget(
            name: "SwiftAccessPolicyTests",
            dependencies: ["SwiftAccessPolicy"]
        ),
    ]
)
