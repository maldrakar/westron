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
            .defaultSize(CatalogScene.windowSize)
        #endif
    }

    /// The size of the catalog's window on macOS. A window the system restores with another size keeps it, except on a
    /// snapshot matrix sheet, which sets this size itself (`MatrixSheetView`).
    static let windowSize = CGSize(width: 720, height: 540)
}
