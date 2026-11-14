// swift-tools-version: 6.2
import PackageDescription

// The manifest lives at the root because SwiftPM takes a remote package only from the repository root,
// and its versions from the repository tags. The sources are in platforms/apple/ (decisions/0005, 0008).
let package = Package(
    name: "Westron",
    // The minimum matches the todo-app pilot (decisions/0006, 0008).
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        // westron styles and components. Products depend on it.
        .library(name: "WestronUI", targets: ["WestronUI"]),
        // Catalog entries, their host and snapshots. Only the catalog app depends on it,
        // in platforms/apple/Catalog; the product exists because an Xcode project sees a package only through
        // its products.
        .library(name: "WestronCatalog", targets: ["WestronCatalog"]),
    ],
    targets: [
        .target(
            name: "WestronUI",
            path: "platforms/apple/Sources/WestronUI"
        ),
        .target(
            name: "WestronCatalog",
            dependencies: ["WestronUI"],
            path: "platforms/apple/Sources/WestronCatalog"
        ),
        .testTarget(
            name: "WestronCatalogTests",
            dependencies: ["WestronCatalog"],
            path: "platforms/apple/Tests/WestronCatalogTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
