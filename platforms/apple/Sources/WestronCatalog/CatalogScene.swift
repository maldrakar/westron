import SwiftUI

/// The catalog scene. The app in `platforms/apple/Catalog` is an `@main` over it and nothing more.
public struct CatalogScene: Scene {
    public init() {
        #if os(macOS)
            // The launch arguments decide what the catalog shows, not a saved state. AppKit restores a state the
            // system keeps for the bundle id, shared by every copy of the catalog on the Mac, and a state saved with
            // no window open restores none: SwiftUI then opens no window, and every macOS UI test fails
            // (platforms/apple/README.md, "Screenshots on macOS"). This is the default Xcode's "Launch application
            // without state restoration" passes as an argument; registered here, it holds for a UI test or a launch
            // from a shell too. The scenes are built before AppKit restores windows at the end of launch, so it is in
            // place in time.
            UserDefaults.standard.register(defaults: ["ApplePersistenceIgnoreState": true])
        #endif
    }

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
