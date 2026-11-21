// Keeps the macOS snapshot render's system text fields at the height of their own line (#99).
//
// The mechanism, in the operating system's SwiftUI (the framework a process runs; Xcode's SDK holds only `SwiftUI.tbd`,
// its exported symbols), read on macOS 26.7.1 and seen at work on the runner's macOS 27.0.1: SwiftUI lays out a system
// text field on one line, and one of several lines with a line limit, between limits it sets from the height of a line
// of the field's font (`VerticalTextField.updateLimits`, applied in `PlatformTextFieldAdaptor._overrideSizeThatFits`).
// That height comes from a cache keyed by the identity of the font object SwiftUI resolved and measures the field's
// line with, which is not the `NSTextField`'s own `font` object (a probe's dumps show two addresses):
// `NSFont.Storage.cache`, a `Cache3<ObjectIdentifier, CGFloat>`, the three fonts looked up last, each by its object's
// address, and on a miss the `NSFont.lineHeight` getter measures the font with
// `-[NSLayoutManager defaultLineHeightForFont:]`. The font object itself lives only in SwiftUI's font cache
// (`Font.FontCache.shared`, an `ObjectCache<Font.FontCache.Key, CTFontRef>`); when that cache lets it go, it is freed,
// and a font made later may be allocated at the same address. If the freed font's entry is still among the three, the
// new font takes its height: a field in the system font at 13 pt, a line of 16, laid out 17 high, the line of Onest at
// 13 pt, or the other way round, while AppKit's own measures of the field still say 16 (run 44932481160). The wrong
// height lasts as long as lookups keep hitting that entry and it is not evicted from the three; a miss would measure
// the font again and correct it. So a process falls in the state or not by what else it draws, and may leave it again:
// in run 44942981800, of the 10 processes in the state that laid their fields out a second round, 7 were back at their
// own heights in it.
//
// What is shown, and by what:
// - the internals named above exist under those names in the SwiftUI framework of macOS 26.7.1, found on a local Mac
//   by symbol lookup and disassembly (they are not exported, so Xcode's `SwiftUI.tbd` does not list them; not
//   documented API, so another macOS may change them). The runner's macOS 27.0.1 SwiftUI was not disassembled: there
//   the mechanism is shown by the traces and the forcing test only;
// - the state can be forced: `fieldsKeepTheirLineThroughFontChurn` without this (`WESTRON_FONT_CHURN_UNFIXED=1`)
//   failed locally and on 4 of 4 runner VMs in run 44941092448, 30 to 311 fields off their line in 2000 attempts;
//   with this, 0 on all four;
// - on the runner without this, the state came up by itself in 13 of 443 short processes (run 44942981800); in 12 of
//   them a trace shows the field's font looked up at an address last measured as another font (SF 13 where Onest 13
//   had been, laid out 17; SF 13 where SF 11 had been, 14; Onest 13 where SF 13 had been, 16). The thirteenth is
//   consistent with it, but the trace, which reports only the last miss at an address, does not show it;
// - with this, the same short-process loop on the runner (probe run 44948217745, matched to run 44942981800) had none
//   in the state: 0 of 458 processes (27,680 pictures), against 13 of 443 without it.
// What is inferred, not shown:
// - that the two failures of CI's render (runs 44885247356 and 44917113978), which had no trace, were this;
// - when and why SwiftUI's font cache lets a font go in a render (the test makes it, by filling the cache);
// - not verified: that an address comes back because CoreText's fonts are allocator blocks of one size (640 bytes).
//
// What this does about it: every font object whose line a layout manager measures, SwiftUI's among them, is kept
// alive for the rest of the process, so that no other font can be allocated at its address, and the cache, keyed by
// the address, always holds the height of the font that is there. It is installed before the first picture is laid
// out (`SnapshotRenderer.show`), so no font measured earlier can have left a height behind. What it keeps grows with
// the fonts made anew and measured, and the forcing test (`FieldLineHeightTests.swift`), which runs in every macOS
// render (`--component` renders and the workflow Snapshot references too), makes thousands: 7100 to 7300 are kept at
// the end of a local render, whose footprint at the end went from 119 MB without the fix and the test to 137 and 139 MB
// in two renders with them (the kept fonts are a part of that; macOS 26.7, Xcode 27.1). The test itself takes about
// 8 s of a local render, and 21.3 to 34.8 s of a render of about 190 to 230 s on the runner (run 44941092448).

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

        /// Whether this very font object is kept.
        static func keeps(_ font: NSFont) -> Bool { lock.withLock { kept[ObjectIdentifier(font)] === font } }

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
