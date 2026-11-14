// swift-tools-version: 6.2
import PackageDescription

// Манифест лежит в корне, потому что SwiftPM берёт удалённый пакет только из корня репозитория,
// а версии — из тегов репозитория. Исходники — в platforms/apple/ (decisions/0005, 0008).
let package = Package(
    name: "Westron",
    // Минимум совпадает с пилотом todo-app (decisions/0006, 0008).
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        // Стили и компоненты westron. Подключают продукты.
        .library(name: "WestronUI", targets: ["WestronUI"]),
        // Записи каталога, их хост и снимки. Подключает только приложение-каталог
        // в platforms/apple/Catalog; продукт нужен, потому что Xcode-проект видит пакет только через продукты.
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
