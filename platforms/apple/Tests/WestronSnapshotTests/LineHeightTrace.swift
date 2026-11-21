// PROBE ONLY (#99, second probe): records from the first layout on which font objects are asked for their leading on
// the main thread (SwiftUI asks the font it measured a field's line with, right after the lookup, hit or miss) and
// every line height a layout manager measures (a miss of SwiftUI's cache), by the font object's address, without
// retaining a font. A field laid out at another font's line then shows as a lookup at an address whose last measured
// line belongs to another font.
#if os(macOS)
    import AppKit
    import ObjectiveC

    enum LineHeightTrace {
        struct Lookup {
            let address: UInt
            let name: NSString?
            let size: CGFloat
        }

        struct Miss {
            let name: NSString?
            let size: CGFloat
            let height: CGFloat
            let manager: UInt
            let serial: Int
        }

        nonisolated(unsafe) static var lookups: [Lookup] = []
        nonisolated(unsafe) static var misses: [UInt: Miss] = [:]
        nonisolated(unsafe) static var missesSinceMark: [(UInt, Miss)] = []
        nonisolated(unsafe) static var serial = 0
        nonisolated(unsafe) static var installed = false

        static func name(_ font: NSFont) -> NSString? {
            (font as AnyObject).perform(NSSelectorFromString("fontName"))?.takeUnretainedValue() as? NSString
        }

        static func mark() {
            lookups.removeAll(keepingCapacity: true)
            missesSinceMark.removeAll(keepingCapacity: true)
        }

        typealias Leading = @convention(c) (NSFont, Selector) -> CGFloat
        typealias LineHeight = @convention(c) (NSLayoutManager, Selector, NSFont) -> CGFloat

        static func install() {
            guard !installed else { return }
            installed = true
            lookups.reserveCapacity(20000)
            if let fontClass = object_getClass(NSFont.systemFont(ofSize: 13)),
                let method = class_getInstanceMethod(fontClass, #selector(getter: NSFont.leading))
            {
                let selector = #selector(getter: NSFont.leading)
                let original = unsafeBitCast(method_getImplementation(method), to: Leading.self)
                let block: @convention(block) (NSFont) -> CGFloat = { font in
                    if Thread.isMainThread, LineHeightTrace.lookups.count < 20000 {
                        LineHeightTrace.lookups.append(
                            Lookup(
                                address: UInt(bitPattern: Unmanaged.passUnretained(font).toOpaque()),
                                name: LineHeightTrace.name(font), size: font.pointSize))
                    }
                    return original(font, selector)
                }
                method_setImplementation(method, imp_implementationWithBlock(block))
            }
            let selector = #selector(NSLayoutManager.defaultLineHeight(for:))
            if let method = class_getInstanceMethod(NSLayoutManager.self, selector) {
                let original = unsafeBitCast(method_getImplementation(method), to: LineHeight.self)
                let block: @convention(block) (NSLayoutManager, NSFont) -> CGFloat = { manager, font in
                    let height = original(manager, selector, font)
                    if Thread.isMainThread {
                        LineHeightTrace.serial += 1
                        let address = UInt(bitPattern: Unmanaged.passUnretained(font).toOpaque())
                        let miss = Miss(
                            name: LineHeightTrace.name(font), size: font.pointSize, height: height,
                            manager: UInt(bitPattern: Unmanaged.passUnretained(manager).toOpaque()),
                            serial: LineHeightTrace.serial)
                        LineHeightTrace.misses[address] = miss
                        LineHeightTrace.missesSinceMark.append((address, miss))
                    }
                    return height
                }
                method_setImplementation(method, imp_implementationWithBlock(block))
            }
        }

        static func describe(_ miss: Miss) -> String {
            String(
                format: "%@ %g -> %g (miss #%d, manager 0x%lx)", (miss.name as String?) ?? "?", miss.size, miss.height,
                miss.serial, miss.manager)
        }

        /// The lookups and misses since the mark, each address with the last line measured there.
        static func report() -> [String] {
            var lines: [String] = []
            var seen = Set<UInt>()
            for lookup in lookups where !seen.contains(lookup.address) {
                seen.insert(lookup.address)
                let last = misses[lookup.address].map(describe) ?? "never measured"
                let name = (lookup.name as String?) ?? "?"
                lines.append(
                    String(
                        format: "lookup 0x%lx %@ %g; last line measured there: %@", lookup.address, name, lookup.size,
                        last))
            }
            for (address, miss) in missesSinceMark {
                lines.append(String(format: "miss here 0x%lx %@", address, describe(miss)))
            }
            return lines
        }

        /// SwiftUI's limits on a field's height, stored on its AppKitTextField (`upperLimit`, `lowerLimit`: an optional
        /// CGFloat each).
        static func limits(_ field: NSTextField) -> String {
            var parts: [String] = []
            for name in ["upperLimit", "lowerLimit", "cachedIdealWidth"] {
                guard let ivar = class_getInstanceVariable(type(of: field), name) else {
                    parts.append("\(name) ?")
                    continue
                }
                let raw = Unmanaged.passUnretained(field).toOpaque().advanced(by: ivar_getOffset(ivar))
                let isNil = raw.advanced(by: 8).load(as: UInt8.self) == 1
                parts.append(isNil ? "\(name) nil" : "\(name) \(raw.load(as: Double.self))")
            }
            return parts.joined(separator: ", ")
        }
    }
#endif
