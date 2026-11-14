// swift-tools-version: 6.2

// westron generators and checks (decisions/0009). This is a separate package, so that its dependencies never
// reach the products that use the root package. It builds on macOS and Linux and uses Foundation only.
//
//   tools/westron lint raw-values      tools/westron generate [--check]      tools/check.sh

import PackageDescription

let package = Package(
    name: "WestronTools",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "westron", targets: ["westron"])
    ],
    targets: [
        // The logic of every tool; tests cover it here, the executable only parses arguments.
        .target(name: "WestronTools"),
        .executableTarget(name: "westron", dependencies: ["WestronTools"]),
        .testTarget(name: "WestronToolsTests", dependencies: ["WestronTools"]),
    ],
    swiftLanguageModes: [.v6]
)
