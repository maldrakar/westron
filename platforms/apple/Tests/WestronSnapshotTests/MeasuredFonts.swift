// Keeps the macOS snapshot render's system text fields at the height of their own line (#99).
//
// The cause, found with Xcode 27.1 on macOS 26 and 27: SwiftUI lays out a system text field on one line, and one of
// several lines with a line limit, between limits it sets from the height of a line of the field's font
// (`VerticalTextField.updateLimits`, applied in `PlatformTextFieldAdaptor._overrideSizeThatFits`). That height comes
// from a cache keyed by the identity of the font object SwiftUI resolved for the field (`NSFont.lineHeight`, whose
// storage is a `Cache3<ObjectIdentifier, CGFloat>`): the three fonts measured last, each by its object's address, the
// height measured by `NSLayoutManager.defaultLineHeight(for:)` on a miss. The font object itself lives only in
// SwiftUI's font cache (`Font.FontCache`, an `ObjectCache` of a few buckets by the key's hash, which Swift seeds anew
// in each process), which lets one go when its bucket is full; it is then freed, and a font SwiftUI makes later may be
// allocated at the same address. If the freed font is still among the three measured last, the new one takes its
// height: a field in the system font at 13 pt, a line of 16, laid out 17 high, the line of Onest at 13 pt, or the
// other way round, while AppKit's own measures of the field still say 16 (run 44932481160). Whether a font is let go,
// and whether another comes back at its address, follows from the process's hash seed and its allocator, so a run
// falls in that state or does not, and once in it, usually stays.
//
// What this does about it: every font object whose line SwiftUI measures is kept alive for the rest of the process,
// so that no other font can be allocated at its address, and the cache, keyed by the address, always holds the height
// of the font that is there. It is installed before the first picture is laid out (`SnapshotRenderer.show`), so no
// font measured earlier can have left a height behind. What it keeps grows with the fonts SwiftUI makes anew: in a
// render, a few hundred objects of 640 bytes. `fieldsKeepTheirLineThroughFontChurn` forces the state and checks that
// every field keeps its own height.

#if os(macOS)
    import AppKit
    import ObjectiveC

    enum MeasuredFonts {
        private static let lock = NSLock()
        nonisolated(unsafe) private static var kept: [ObjectIdentifier: NSFont] = [:]
        nonisolated(unsafe) private static var installed = false

        typealias LineHeight = @convention(c) (NSLayoutManager, Selector, NSFont) -> CGFloat

        /// How many font objects are kept.
        static var count: Int { lock.withLock { kept.count } }

        /// Keeps from now on every font whose line height a layout manager measures, SwiftUI's own among them; the
        /// measurement itself is AppKit's, unchanged. Once per process.
        static func keep() {
            lock.withLock {
                guard !installed else { return }
                installed = true
                let selector = #selector(NSLayoutManager.defaultLineHeight(for:))
                guard let method = class_getInstanceMethod(NSLayoutManager.self, selector) else { return }
                let measure = unsafeBitCast(method_getImplementation(method), to: LineHeight.self)
                let keeping: @convention(block) (NSLayoutManager, NSFont) -> CGFloat = { manager, font in
                    MeasuredFonts.lock.withLock { MeasuredFonts.kept[ObjectIdentifier(font)] = font }
                    return measure(manager, selector, font)
                }
                method_setImplementation(method, imp_implementationWithBlock(keeping))
            }
        }
    }
#endif
