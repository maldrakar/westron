import SwiftUI

/// The catalog scene. The app in `platforms/apple/Catalog` is an `@main` over it and nothing more.
public struct CatalogScene: Scene {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            CatalogRootView()
        }
        #if os(macOS)
            // The window size is fixed so that macOS screenshots have the same size from run to run.
            .defaultSize(width: 720, height: 540)
        #endif
    }
}
