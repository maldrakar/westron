// swift-tools-version: 6.2
import PackageDescription

// The manifest lives at the root because SwiftPM takes a remote package only from the repository root,
// and its versions from the repository tags. The sources are in platforms/apple/ (decisions/0005, 0008).
let package = Package(
    name: "Westron",
    // The language of the strings westron writes, such as a button's "Loading" (WestronUI/Localizable.xcstrings).
    // Which other languages westron ships is the owner's decision.
    defaultLocalization: "en",
    // The minimum matches the todo-app pilot (decisions/0006, 0008).
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        // westron's token values as plain Swift, with no SwiftUI and no Foundation: for a product's shared code,
        // which may build for WebAssembly and Linux (decisions/0006, 0010).
        .library(name: "WestronTokens", targets: ["WestronTokens"]),
        // westron styles and components, and the SwiftUI accessors of the tokens. Products depend on it.
        .library(name: "WestronUI", targets: ["WestronUI"]),
        // Catalog entries, their host and snapshots. Only the catalog app depends on it,
        // in platforms/apple/Catalog; the product exists because an Xcode project sees a package only through
        // its products.
        .library(name: "WestronCatalog", targets: ["WestronCatalog"]),
    ],
    targets: [
        // Generated/ is written by `tools/westron generate` from tokens/westron.resolver.json.
        .target(
            name: "WestronTokens",
            path: "platforms/apple/Sources/WestronTokens"
        ),
        // Generated/ and Tokens.xcassets are written by `tools/westron generate`. Fonts/ holds the fonts westron
        // ships, each with its license (decisions/0011). Localizable.xcstrings holds the strings westron's components
        // show or announce.
        .target(
            name: "WestronUI",
            dependencies: ["WestronTokens"],
            path: "platforms/apple/Sources/WestronUI",
            resources: [.process("Tokens.xcassets"), .copy("Fonts"), .process("Localizable.xcstrings")]
        ),
        .target(
            name: "WestronCatalog",
            dependencies: ["WestronUI"],
            path: "platforms/apple/Sources/WestronCatalog"
        ),
        .testTarget(
            name: "WestronUITests",
            dependencies: ["WestronUI"],
            path: "platforms/apple/Tests/WestronUITests"
        ),
        .testTarget(
            name: "WestronCatalogTests",
            dependencies: ["WestronCatalog"],
            path: "platforms/apple/Tests/WestronCatalogTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
