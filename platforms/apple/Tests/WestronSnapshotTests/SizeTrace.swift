// PROBE ONLY (#99): records every size AppKit gives for a text field or its cell while a picture is laid out, so that
// a picture whose field is laid out 1 pt off names the call that gave the size.
#if os(macOS)
    import AppKit
    import ObjectiveC

    @MainActor
    enum SizeTrace {
        static var lines: [String] = []
        static var installed = false

        /// The object's class and address only: reading a field's font or text here would change what is retained
        /// and when, and so the state this traces.
        static func describe(_ object: AnyObject) -> String {
            "\(type(of: object)) \(Unmanaged.passUnretained(object).toOpaque())"
        }

        static func record(_ line: String) {
            if lines.count < 4000 { lines.append(line) }
        }

        static func wanted(_ object: AnyObject) -> Bool { object is NSTextField || object is NSTextFieldCell }

        typealias SizeIMP = @convention(c) (AnyObject, Selector) -> CGSize
        typealias SizeForRectIMP = @convention(c) (AnyObject, Selector, CGRect) -> CGSize
        typealias SizeForSizeIMP = @convention(c) (AnyObject, Selector, CGSize) -> CGSize
        typealias SetSizeIMP = @convention(c) (AnyObject, Selector, CGSize) -> Void

        static func hookSize(_ cls: AnyClass, _ name: String) {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector) else { return }
            let original = unsafeBitCast(method_getImplementation(method), to: SizeIMP.self)
            let block: @convention(block) (AnyObject) -> CGSize = { object in
                let size = original(object, selector)
                if wanted(object) { MainActor.assumeIsolated { record("\(name) \(describe(object)) -> \(size)") } }
                return size
            }
            method_setImplementation(method, imp_implementationWithBlock(block))
        }

        static func hookSizeForRect(_ cls: AnyClass, _ name: String) {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector) else { return }
            let original = unsafeBitCast(method_getImplementation(method), to: SizeForRectIMP.self)
            let block: @convention(block) (AnyObject, CGRect) -> CGSize = { object, rect in
                let size = original(object, selector, rect)
                if wanted(object) { MainActor.assumeIsolated { record("\(name) \(describe(object)) in \(rect) -> \(size)") } }
                return size
            }
            method_setImplementation(method, imp_implementationWithBlock(block))
        }

        static func hookSizeForSize(_ cls: AnyClass, _ name: String) {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector) else { return }
            let original = unsafeBitCast(method_getImplementation(method), to: SizeForSizeIMP.self)
            let block: @convention(block) (AnyObject, CGSize) -> CGSize = { object, proposed in
                let size = original(object, selector, proposed)
                if wanted(object) { MainActor.assumeIsolated { record("\(name) \(describe(object)) for \(proposed) -> \(size)") } }
                return size
            }
            method_setImplementation(method, imp_implementationWithBlock(block))
        }

        static func hookSetSize(_ cls: AnyClass, _ name: String) {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector) else { return }
            let original = unsafeBitCast(method_getImplementation(method), to: SetSizeIMP.self)
            let block: @convention(block) (AnyObject, CGSize) -> Void = { object, size in
                original(object, selector, size)
                if wanted(object) { MainActor.assumeIsolated { record("\(name) \(describe(object)) to \(size)") } }
            }
            method_setImplementation(method, imp_implementationWithBlock(block))
        }

        typealias SetRectIMP = @convention(c) (AnyObject, Selector, CGRect) -> Void

        static func hookSetRect(_ cls: AnyClass, _ name: String) {
            let selector = NSSelectorFromString(name)
            guard let method = class_getInstanceMethod(cls, selector) else { return }
            let original = unsafeBitCast(method_getImplementation(method), to: SetRectIMP.self)
            let block: @convention(block) (AnyObject, CGRect) -> Void = { object, rect in
                original(object, selector, rect)
                if wanted(object) { MainActor.assumeIsolated { record("\(name) \(describe(object)) to \(rect)") } }
            }
            method_setImplementation(method, imp_implementationWithBlock(block))
        }

        static func install() {
            hookSetRect(NSView.self, "setFrame:")
            guard !installed else { return }
            installed = true
            hookSize(NSTextFieldCell.self, "cellSize")
            hookSizeForRect(NSTextFieldCell.self, "cellSizeForBounds:")
            hookSize(NSTextField.self, "intrinsicContentSize")
            hookSize(NSTextField.self, "fittingSize")
            hookSizeForSize(NSTextField.self, "sizeThatFits:")
            hookSetSize(NSTextField.self, "setFrameSize:")
        }
    }
#endif
