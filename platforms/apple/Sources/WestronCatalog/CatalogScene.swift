import SwiftUI

/// Сцена каталога. Приложение в `platforms/apple/Catalog` — это `@main` над ней и ничего больше.
public struct CatalogScene: Scene {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            CatalogRootView()
        }
        #if os(macOS)
            // Размер окна задан, чтобы скриншоты macOS были одного размера от запуска к запуску.
            .defaultSize(width: 720, height: 540)
        #endif
    }
}
