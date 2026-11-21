// Draws one snapshot matrix picture in-process (#92, decisions/0008, note of 2026-11-21). One source for two test
// bundles: the package's `WestronSnapshotTests` (macOS, `swift test`) and the catalog's `CatalogSnapshotTests` (iOS,
// a unit-test bundle hosted by the catalog app), whose project takes this folder as it is.
//
// Each picture is the catalog's own view for `-WestronMatrixSheet` (`CatalogRootView` with the capture's launch
// arguments), so the sheet, the theme, the contrast and the text size are applied exactly as in the app. What draws it:
// - iOS: a window in the host app's scene, over the app's own, with the device's size and safe area; the render server
//   draws it, so `drawHierarchy(in:afterScreenUpdates:)` sees what the screen would. Without a host app, iOS draws
//   nothing.
// - macOS: a borderless window that is never ordered in, with a fixed backing scale of 2 whatever the screens', and
//   its layer tree drawn by Core Animation's own renderer into a Metal texture. `ImageRenderer`, `CALayer.render(in:)`
//   and `cacheDisplay` misdraw system controls (a text field's placeholder, a spinner, a capsule's stroke, shadows).
//
// The sheet is laid out as in the app and reports its own layout (`MatrixSheetProbe`): the frame of its content and of
// each cell drawn. The picture is cut to the content, the window's width, from the top of the sheet (under the status
// bar's safe area on iOS) down to the sheet's bottom and the reach of the deepest shadow token below it, as far as the
// window goes. A cell outside the window, on either axis, makes the picture "cut off"; a cell that drew nothing makes
// it short of cells. Each attempt's outcome is logged.
//
// The main thread goes back to its run loop before every draw and while a sheet settles (`pause`), instead of turning
// the run loop from inside one long call. Run 44835019906 on the CI runner (a VM with 3 cores and 7 GB) drew the last
// five pictures blank, four times each, after the draws had slowed from 0.3 s to 5 s over the run. The cause: the
// whole matrix ran as one job on the main queue, and `RunLoop.main.run(until:)` inside a job does not serve the main
// queue, so whatever UIKit and SwiftUI scheduled there never ran, the release of each picture's window and hosting
// controller among it. Every window and controller ever made stayed alive (388 of 388), with its layers in the render
// server, and the process grew to 4.2 GB by the end of a local run; with the main thread free between draws, one of
// each is alive at a time and the process stays near 90 MB. Each draw also runs in its own autorelease pool, and a
// picture's window leaves the scene when it is done, so a draw holds nothing of the one before it.

import CoreGraphics
import Foundation
import ImageIO
import SwiftUI
import UniformTypeIdentifiers
import WestronUI

@testable import WestronCatalog

#if os(macOS)
    import AppKit
    import Metal
    import QuartzCore
#elseif os(iOS)
    import UIKit
#endif

/// One rendered picture: an opaque sRGB image cut to the sheet, and what the manifest says of it.
struct SnapshotPicture {
    let image: CGImage
    /// The picture's size in points.
    let size: CGSize
    /// Whether every cell lies wholly inside the window and the sheet is no wider than it.
    let fits: Bool
    /// The cells that drew something: a frame of their own with an area.
    let found: Int
    /// How many draws it took, and what each one gave.
    let attempts: Int
    let log: [String]
}

enum SnapshotRenderError: Error, CustomStringConvertible {
    case noHost
    case failed(log: [String])
    case noImage(String)

    var description: String {
        switch self {
        case .noHost:
            "no window scene: on iOS the snapshot tests run in the catalog app (CatalogSnapshotTests), which "
                + "tools/apple/snapshot-matrix.sh ios builds and runs"
        case .failed(let log): "no complete picture in \(log.count) draws: " + log.joined(separator: "; ")
        case .noImage(let why): "no image: \(why)"
        }
    }
}

/// What one draw of a sheet gave.
struct SnapshotDraw {
    /// The picture cut to the sheet, opaque.
    let image: CGImage
    let size: CGSize
    let window: CGSize
    /// The sheet's and the cells' frames in the window, as the sheet reported them.
    let sheet: CGRect
    let cells: [CGRect]
}

/// Why a draw gave no picture.
enum SnapshotMiss: Error, CustomStringConvertible {
    /// The sheet reported no frame: SwiftUI had not laid it out.
    case noFrame
    /// `drawHierarchy` returned false (iOS), or Core Animation's renderer gave no image (macOS).
    case drawFailed
    /// The picture holds fewer than three colors: nothing but the canvas, or nothing at all.
    case blank(colors: Int)
    /// A second draw, taken because the first was slow or a retry, differed from it.
    case unstable

    var description: String {
        switch self {
        case .noFrame: "no frame reported"
        case .drawFailed: "drawHierarchy returned false"
        case .blank(let colors): "blank (\(colors) color\(colors == 1 ? "" : "s"))"
        case .unstable: "a second draw differed"
        }
    }
}

@MainActor
enum SnapshotRenderer {
    /// Lets the main thread go back to its run loop for `seconds`: what UIKit and SwiftUI scheduled on the main queue
    /// runs (a window's release, a view's asynchronous update), Core Animation commits, the run loop turns. On macOS
    /// the run loop is also turned here: under `swift test` the main thread may serve the main queue without it.
    static func pause(_ seconds: TimeInterval) async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { continuation.resume() }
        }
        #if os(macOS)
            turnRunLoop(seconds)
        #endif
    }

    /// Turns the main run loop from inside a call, which an async function may not do itself.
    static func turnRunLoop(_ seconds: TimeInterval) {
        RunLoop.main.run(until: Date().addingTimeInterval(seconds))
    }

    /// How many draws a picture gets in all before it fails: the first and up to three more.
    static let attempts = 4

    /// A sheet settles this long before each draw, longer after a miss (`pause`): SwiftUI commits what it scheduled
    /// (its asynchronous updates, the representables) on the next turn of the run loop.
    static func settle(attempt: Int) -> TimeInterval { [0.01, 0.1, 0.5, 2][min(attempt, 3)] }

    /// On iOS, a draw slower than this is taken a second time and must agree pixel for pixel: `drawHierarchy` goes
    /// through the simulator's render server, and a draw that comes back slow from it on a loaded machine is the one
    /// that may be incomplete. Locally a draw takes about 0.1 s; on the CI runner up to about 1.2 s once the main
    /// thread is freed between draws (run 44846443416). On macOS a slow draw is not checked (`checksSlowDraws`):
    /// `CARenderer` draws into the test's own texture, in the process and in the call, with no server to fall behind,
    /// no incomplete draw has been seen there, and the runner's ordinary macOS draws take up to 5.4 s, so a threshold
    /// would only double them (35 of 196 there, 176 s of render became 269 s). A retry after a failed draw is checked
    /// on both.
    static let verifyAfter: TimeInterval = 1.5

    #if os(iOS)
        static let checksSlowDraws = true
    #else
        static let checksSlowDraws = false
    #endif

    /// How far below a view the deepest shadow token reaches, in points: the most of its layers' offset, blur and
    /// spread in any theme (`shadow.dragged`, 16 + 40 pt, in the tokens' CSS sense). The picture keeps that much below
    /// the sheet, as far as the window goes, so that a dragged surface's shadow at the bottom of a sheet is compared
    /// whole.
    static let shadowReach: CGFloat =
        Westron.Shadow.all.flatMap { shadow in Westron.Theme.allCases.flatMap { shadow[$0] } }
        .map { CGFloat($0.y + $0.blur + $0.spread) }.max() ?? 0

    /// The arguments the catalog app would get for this picture.
    static func view(key: String, capture: ComponentMatrix.Capture, probe: MatrixSheetProbe) throws -> some View {
        let options = try CatalogLaunchOptions(arguments: ["-WestronMatrixSheet", key] + capture.launchArguments)
        return CatalogRootView(options: .success(options))
            // The process's locale is the machine's; SwiftUI's formatting takes the environment's.
            .environment(\.locale, Locale(identifier: "en_US"))
            .environment(\.matrixSheetProbe, probe)
    }

    /// Draws a picture until a draw gives a complete one: a frame, a successful draw, more than the canvas, and, for a
    /// slow draw on iOS or a retry, a second draw that agrees. Each draw's outcome and time go into the picture's log, or the
    /// error's.
    static func render(key: String, capture: ComponentMatrix.Capture) async throws -> SnapshotPicture {
        var log: [String] = []
        for attempt in 0..<attempts {
            let began = Date()
            let outcome = try await drawOnce(key: key, capture: capture, settle: settle(attempt: attempt))
            let seconds = Date().timeIntervalSince(began)
            switch outcome {
            case .failure(let miss):
                log.append(String(format: "#%d %@ after %.2f s", attempt + 1, miss.description, seconds))
            case .success(let first):
                guard (checksSlowDraws && seconds > verifyAfter) || attempt > 0 else {
                    log.append(String(format: "#%d drawn in %.2f s", attempt + 1, seconds))
                    return picture(first, attempts: attempt + 1, log: log)
                }
                let again = try await drawOnce(key: key, capture: capture, settle: settle(attempt: attempt))
                guard case .success(let second) = again, pixels(of: first.image) == pixels(of: second.image) else {
                    let why: SnapshotMiss
                    if case .failure(let miss) = again { why = miss } else { why = .unstable }
                    log.append(
                        String(
                            format: "#%d drawn in %.2f s, its check draw: %@", attempt + 1, seconds, why.description))
                    continue
                }
                log.append(
                    String(
                        format: "#%d drawn in %.2f s, the same again in %.2f s", attempt + 1, seconds,
                        Date().timeIntervalSince(began) - seconds))
                return picture(first, attempts: attempt + 1, log: log)
            }
        }
        throw SnapshotRenderError.failed(log: log)
    }

    /// One draw, after the main thread has had its turn, so that nothing of the draw before is left.
    static func drawOnce(key: String, capture: ComponentMatrix.Capture, settle: TimeInterval) async throws -> Result<
        SnapshotDraw, SnapshotMiss
    > {
        await pause(0)
        let probe = MatrixSheetProbe()
        let window = try autoreleasepool {
            try show(try view(key: key, capture: capture, probe: probe), dark: capture.theme.isDark)
        }
        defer { autoreleasepool { hide(window) } }
        await pause(settle)
        let drawn = try autoreleasepool { try draw(window, probe: probe) }
        guard case .success(let draw) = drawn else { return drawn }
        let colors = colorCount(draw.image, upTo: 3)
        return colors < 3 ? .failure(.blank(colors: colors)) : .success(draw)
    }

    static func picture(_ draw: SnapshotDraw, attempts: Int, log: [String]) -> SnapshotPicture {
        let window = CGRect(origin: .zero, size: draw.window).insetBy(dx: -0.5, dy: -0.5)
        let drawn = draw.cells.filter { $0.width > 0 && $0.height > 0 }
        let fits =
            drawn.allSatisfy { window.contains($0) } && draw.sheet.minX >= window.minX
            && draw.sheet.maxX <= window.maxX
        return SnapshotPicture(
            image: draw.image, size: draw.size, fits: fits, found: drawn.count, attempts: attempts, log: log)
    }

    /// The part of a window's picture of `scale` pixels a point that holds the sheet: the window's width, from the
    /// sheet's top to its bottom and the shadows' reach below it, inside the window; opaque.
    static func cut(_ image: CGImage, to sheet: CGRect, window: CGSize, scale: CGFloat) -> (CGImage, CGSize)? {
        let top = max(0, sheet.minY)
        let bottom = min(sheet.maxY + shadowReach, window.height)
        let pixels = CGRect(x: 0, y: top * scale, width: window.width * scale, height: max(0, bottom - top) * scale)
            .integral
        guard pixels.width > 0, pixels.height > 0, let cropped = image.cropping(to: pixels),
            let opaque = opaque(cropped)
        else { return nil }
        return (opaque, CGSize(width: pixels.width / scale, height: pixels.height / scale))
    }

    /// A draw from what the window drew and what the sheet reported.
    static func result(
        _ whole: CGImage, probe: MatrixSheetProbe, window: CGSize, scale: CGFloat
    ) throws -> Result<SnapshotDraw, SnapshotMiss> {
        guard let (image, size) = cut(whole, to: probe.sheet, window: window, scale: scale) else {
            throw SnapshotRenderError.noImage("the sheet's frame \(probe.sheet) is outside the window")
        }
        return .success(
            SnapshotDraw(
                image: image, size: size, window: window, sheet: probe.sheet, cells: Array(probe.cells.values)))
    }

    #if os(iOS)
        /// A window in the host app's scene with the view as its content, shown over the app's own and laid out.
        static func show(_ view: some View, dark: Bool) throws -> UIWindow {
            guard
                let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
            else { throw SnapshotRenderError.noHost }
            let controller = UIHostingController(rootView: view)
            let window = UIWindow(windowScene: scene)
            window.frame = scene.screen.bounds
            window.windowLevel = .alert + 1
            // The sheet sets its scheme itself (`preferredColorScheme`); the window agrees, for what UIKit draws.
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            window.rootViewController = controller
            window.isHidden = false
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            return window
        }

        /// Takes the window away: hidden, without its content, out of the scene, which otherwise keeps it.
        static func hide(_ window: UIWindow) {
            window.isHidden = true
            window.rootViewController = nil
            window.windowScene = nil
        }

        static func draw(_ window: UIWindow, probe: MatrixSheetProbe) throws -> Result<SnapshotDraw, SnapshotMiss> {
            window.rootViewController?.view.layoutIfNeeded()
            guard probe.sheet.height > 0 else { return .failure(.noFrame) }
            let scale = window.screen.scale
            let format = UIGraphicsImageRendererFormat()
            format.scale = scale
            format.preferredRange = .standard
            format.opaque = false
            var drawn = false
            let image = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { _ in
                drawn = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            guard drawn, let whole = image.cgImage else { return .failure(.drawFailed) }
            return try result(whole, probe: probe, window: window.bounds.size, scale: scale)
        }

        /// What may change a picture besides the code: the device, its OS and scale.
        static var environment: (os: String, device: String, scale: Double) {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let device =
                ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] ?? UIDevice.current.model
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
            return (
                "iOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)", device,
                Double(scene?.screen.scale ?? 0)
            )
        }

        /// The windows the process holds: the app's own and any a picture left behind.
        static var liveWindows: Int {
            UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.map(\.windows.count)
                .reduce(0, +)
        }
    #elseif os(macOS)
        /// The backing scale of every picture, whatever the screens': SwiftUI rounds its layout and rasterizes its text
        /// at the window's scale, so a 1x runner would otherwise draw differently from a Retina Mac.
        static let scale: CGFloat = 2

        final class FixedScaleWindow: NSWindow {
            override var backingScaleFactor: CGFloat { SnapshotRenderer.scale }
        }

        /// A borderless window with the view as its content, never ordered in, laid out.
        static func show(_ view: some View, dark: Bool) throws -> NSWindow {
            _ = NSApplication.shared
            let size = CatalogScene.windowSize
            let hosting = NSHostingView(rootView: view)
            // The window keeps the catalog's size; the hosting view does not resize it to the sheet.
            hosting.sizingOptions = []
            hosting.frame = CGRect(origin: .zero, size: size)
            // Borderless and never ordered in: nothing shows on screen, and it never becomes key.
            let window = FixedScaleWindow(
                contentRect: CGRect(origin: CGPoint(x: -20000, y: -20000), size: size), styleMask: [.borderless],
                backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            // The sheet sets its scheme itself (`preferredColorScheme`); the window agrees, for what AppKit draws.
            window.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
            window.contentView = hosting
            hosting.layoutSubtreeIfNeeded()
            return window
        }

        static func hide(_ window: NSWindow) {
            window.contentView = nil
            window.close()
        }

        static func draw(_ window: NSWindow, probe: MatrixSheetProbe) throws -> Result<SnapshotDraw, SnapshotMiss> {
            guard let hosting = window.contentView else { return .failure(.drawFailed) }
            hosting.layoutSubtreeIfNeeded()
            hosting.displayIfNeeded()
            guard probe.sheet.height > 0 else { return .failure(.noFrame) }
            let size = CatalogScene.windowSize
            guard let whole = try caRender(hosting, size: size) else { return .failure(.drawFailed) }
            return try result(whole, probe: probe, window: size, scale: scale)
        }

        /// Draws a view's layer tree through Core Animation's renderer into a Metal texture, whose rows are bottom up.
        static func caRender(_ view: NSView, size: CGSize) throws -> CGImage? {
            guard let layer = view.layer else { throw SnapshotRenderError.noImage("the hosting view has no layer") }
            guard let device = MTLCreateSystemDefaultDevice(), let queue = device.makeCommandQueue() else {
                throw SnapshotRenderError.noImage("no Metal device")
            }
            let width = Int(size.width * scale)
            let height = Int(size.height * scale)
            let descriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm, width: width, height: height, mipmapped: false)
            descriptor.usage = [.renderTarget, .shaderRead]
            descriptor.storageMode = .managed
            guard let texture = device.makeTexture(descriptor: descriptor) else {
                throw SnapshotRenderError.noImage("no Metal texture")
            }
            let renderer = CARenderer(
                mtlTexture: texture, options: [kCARendererColorSpace: srgb, kCARendererMetalCommandQueue: queue])
            // The renderer takes its own root: a layer has one superlayer, so the view's is lent for the frame and put
            // back, under a container that scales points to pixels.
            let superlayer = layer.superlayer
            let root = CALayer()
            root.frame = CGRect(x: 0, y: 0, width: width, height: height)
            let container = CALayer()
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.removeFromSuperlayer()
            container.frame = CGRect(origin: .zero, size: size)
            container.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale))
            container.anchorPoint = .zero
            container.position = .zero
            container.addSublayer(layer)
            root.addSublayer(container)
            CATransaction.commit()
            // The renderer sees only committed layers.
            CATransaction.flush()
            renderer.layer = root
            renderer.bounds = root.frame
            CATransaction.flush()
            renderer.beginFrame(atTime: CACurrentMediaTime(), timeStamp: nil)
            renderer.addUpdate(renderer.bounds)
            renderer.render()
            renderer.endFrame()
            if let buffer = queue.makeCommandBuffer(), let blit = buffer.makeBlitCommandEncoder() {
                blit.synchronize(resource: texture)
                blit.endEncoding()
                buffer.commit()
                buffer.waitUntilCompleted()
            }
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            layer.removeFromSuperlayer()
            superlayer?.addSublayer(layer)
            CATransaction.commit()
            var bytes = [UInt8](repeating: 0, count: width * height * 4)
            texture.getBytes(
                &bytes, bytesPerRow: width * 4, from: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0)
            guard let provider = CGDataProvider(data: Data(bytes) as CFData),
                let image = CGImage(
                    width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                    space: srgb,
                    bitmapInfo: CGBitmapInfo(
                        rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue
                            | CGBitmapInfo.byteOrder32Little.rawValue),
                    provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent),
                let flipped = context(width: width, height: height, alpha: true)
            else { return nil }
            flipped.translateBy(x: 0, y: CGFloat(height))
            flipped.scaleBy(x: 1, y: -1)
            flipped.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return flipped.makeImage()
        }

        static var environment: (os: String, device: String, scale: Double) {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            return (
                "macOS \(version.majorVersion).\(version.minorVersion).\(version.patchVersion)", "Mac",
                Double(scale)
            )
        }

        /// The windows the process holds.
        static var liveWindows: Int { NSApplication.shared.windows.count }

        /// The language and the region the render pins (`pinLanguage`), as on iOS, where xcodebuild's `-testLanguage
        /// en -testRegion en_US` puts the same two values in the catalog's argument domain.
        static let pinnedLanguages = ["en"]
        static let pinnedLocale = "en_US"

        /// Pins the process's preferred languages and locale for the run, in its argument domain, which outranks the
        /// app's and the machine's preferences. Under `swift test` the process otherwise takes the Mac's, and AppKit
        /// and Core Text read them when they make a font: the line height of a text style follows them (the system
        /// field's line of body text is 16 pt with English, 17.3 with Vietnamese or Arabic among the languages, 18.3
        /// with Thai, 21 with Burmese; measured with Xcode 27.1 on macOS 26.7), and a fresh font after a change of the
        /// machine's preferences takes the new ones. The posted notification makes Core Text read them now.
        static func pinLanguage() {
            var arguments = UserDefaults.standard.volatileDomain(forName: UserDefaults.argumentDomain)
            arguments["AppleLanguages"] = pinnedLanguages
            arguments["AppleLocale"] = pinnedLocale
            UserDefaults.standard.setVolatileDomain(arguments, forName: UserDefaults.argumentDomain)
            NotificationCenter.default.post(name: NSLocale.currentLocaleDidChangeNotification, object: nil)
        }

        /// What AppKit's text field, the system field under SwiftUI's TextField, measures one line of body text and an
        /// empty field with a prompt at now, with the process's languages: a picture is comparable only with the
        /// metrics the run began with (#98: in run 44885247356 every system field of seven pictures in a row was 1 pt
        /// taller than in every other run, and nothing else in them changed).
        static var textMetrics: String? {
            let font = NSFont.preferredFont(forTextStyle: .body)
            let line = NSTextFieldCell(textCell: "Groceries")
            line.font = font
            let empty = NSTextFieldCell(textCell: "")
            empty.font = font
            empty.placeholderString = "Untitled"
            return "a field's line of \(font.fontName) \(font.pointSize) pt is \(line.cellSize.height) pt high, an "
                + "empty one \(empty.cellSize.height) pt; languages \(Locale.preferredLanguages.joined(separator: ", "))"
        }

        /// Whether the run draws a few pictures a second time at its end and requires the same pixels
        /// (SnapshotMatrixRenderTests, "Reproducible within the run").
        static let checksReproducible = true
    #else
        static func show(_ view: some View, dark: Bool) throws -> Never { throw SnapshotRenderError.noHost }
        static func hide(_ window: Never) {}
        static func draw(_ window: Never, probe: MatrixSheetProbe) throws -> Result<SnapshotDraw, SnapshotMiss> {}

        static var environment: (os: String, device: String, scale: Double) { ("", "", 0) }
        static var liveWindows: Int { 0 }
    #endif

    #if !os(macOS)
        /// On iOS xcodebuild pins the language and the region (`-testLanguage en -testRegion en_US`), and no render
        /// has been seen to differ within a run (388 of 388 the same in every CI run), so neither the text metrics
        /// nor a second draw are checked.
        static func pinLanguage() {}
        static var textMetrics: String? { nil }
        static let checksReproducible = false
    #endif

    /// The process's physical memory footprint in megabytes, as the system counts it against its limit.
    static var footprint: Int {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<natural_t>.size)
        let status = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        return status == KERN_SUCCESS ? Int(info.phys_footprint / 1_048_576) : -1
    }

    static let srgb = CGColorSpace(name: CGColorSpace.sRGB)!

    /// An 8-bit sRGB context, top row first; with alpha, or opaque with a padding byte.
    static func context(width: Int, height: Int, alpha: Bool) -> CGContext? {
        CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: srgb,
            bitmapInfo: (alpha ? CGImageAlphaInfo.premultipliedLast : CGImageAlphaInfo.noneSkipLast).rawValue)
    }

    /// The image redrawn opaque: the sheet's canvas covers every pixel, so the alpha channel only costs space.
    static func opaque(_ image: CGImage) -> CGImage? {
        guard let context = context(width: image.width, height: image.height, alpha: false) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        return context.makeImage()
    }

    /// An image's pixels, for comparing two draws.
    static func pixels(of image: CGImage) -> Data? { image.dataProvider?.data as Data? }

    /// Reads a PNG.
    static func read(_ url: URL) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    /// How many pixels of two images differ by more than `tolerance` levels in a channel, the tolerance of
    /// `tools/apple/snapshot-matrix.sh compare`; nil when their sizes differ.
    static func differingPixels(_ a: CGImage, _ b: CGImage, tolerance: Int = 1) -> Int? {
        guard a.width == b.width, a.height == b.height,
            let first = context(width: a.width, height: a.height, alpha: true),
            let second = context(width: b.width, height: b.height, alpha: true)
        else { return nil }
        let rect = CGRect(x: 0, y: 0, width: a.width, height: a.height)
        first.draw(a, in: rect)
        second.draw(b, in: rect)
        guard let one = first.data?.assumingMemoryBound(to: UInt8.self),
            let other = second.data?.assumingMemoryBound(to: UInt8.self)
        else { return nil }
        // The same bytes, the usual outcome, without a pass over every pixel.
        if memcmp(one, other, a.width * a.height * 4) == 0 { return 0 }
        var count = 0
        for pixel in 0..<(a.width * a.height) {
            let offset = pixel * 4
            for channel in 0..<3 where abs(Int(one[offset + channel]) - Int(other[offset + channel])) > tolerance {
                count += 1
                break
            }
        }
        return count
    }

    /// How many colors a sample of an image's pixels holds, counted up to `limit`. A sheet always has text on its
    /// canvas; a blank render is one color, black or transparent.
    static func colorCount(_ image: CGImage, upTo limit: Int) -> Int {
        guard let context = context(width: image.width, height: image.height, alpha: true) else { return 0 }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let data = context.data else { return 0 }
        let bytes = data.assumingMemoryBound(to: UInt32.self)
        var seen = Set<UInt32>()
        var index = 0
        let count = image.width * image.height
        while index < count {
            seen.insert(bytes[index])
            if seen.count >= limit { break }
            index += 7
        }
        return seen.count
    }

    /// Writes a PNG; returns its size in bytes.
    @discardableResult
    static func write(_ image: CGImage, to url: URL) throws -> Int {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.png.identifier as CFString, 1, nil)
        else { throw SnapshotRenderError.noImage("no PNG encoder") }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else { throw SnapshotRenderError.noImage("PNG encoding") }
        try (data as Data).write(to: url)
        return data.length
    }
}

extension ComponentMatrix.Theme {
    var isDark: Bool { self == .dark || self == .darkHighContrast }
}
