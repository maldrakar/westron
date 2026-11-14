import SwiftUI
import WestronCatalog

// Оболочка приложения-каталога: всё содержимое — в таргете WestronCatalog пакета (decisions/0008).
@main
struct CatalogApp: App {
    var body: some Scene {
        CatalogScene()
    }
}
