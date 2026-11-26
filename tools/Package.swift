// swift-tools-version: 6.2

// westron generators and checks (decisions/0009). This is a separate package, so that its dependencies never
// reach the products that use the root package. It builds on macOS and Linux and uses Foundation only.
//
//   tools/westron lint raw-values      tools/westron generate [--check]      tools/westron tokens check
//   tools/westron icons check          tools/westron spec check              tools/westron lint api-parity
//   tools/westron patterns check       tools/check.sh

import PackageDescription

let package = Package(
    name: "WestronTools",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "westron", targets: ["westron"])
    ],
    dependencies: [
        // Validation of token files against the official DTCG JSON Schemas (Sources/WestronTools/Tokens/README.md).
        .package(url: "https://github.com/ajevans99/swift-json-schema", exact: "0.15.0"),
        // YAML: the icon registry (spec/icons/icons.yaml), then the component contracts (decisions/0004, 0009) and
        // the patterns' front matter (decisions/0018).
        .package(url: "https://github.com/jpsim/Yams", exact: "6.2.2"),
        // Swift's own parser: the API parity lint reads WestronUI's public declarations from its sources (#21). The
        // version is the one swift-json-schema already resolves, for Swift 6.4.
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "604.0.0"),
    ],
    targets: [
        // The logic of every tool; tests cover it here, the executable only parses arguments.
        .target(
            name: "WestronTools",
            dependencies: [
                .product(name: "JSONSchema", package: "swift-json-schema"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ],
            exclude: ["Tokens/README.md"]
        ),
        .executableTarget(name: "westron", dependencies: ["WestronTools"]),
        .testTarget(
            name: "WestronToolsTests",
            dependencies: ["WestronTools"],
            resources: [.copy("Fixtures")]
        ),
    ],
    swiftLanguageModes: [.v6]
)
