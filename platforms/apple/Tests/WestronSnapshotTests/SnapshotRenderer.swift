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
// The sheet is laid out as in the app, and the picture is cut to the sheet's content, as the macOS UI test cut it: the
// window's width, from the top of the sheet (under the status bar's safe area on iOS) to its bottom, its own padding
// included; the sheet reports that frame itself (`EnvironmentValues.matrixSheetFrame`). A sheet that runs past the
// window is cut where the window ends and reported as not fitting.

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
    /// Whether the whole sheet, its cells to the last row, lies inside the window.
    let fits: Bool
    /// How many renders it took: more than 1 when a render came back blank.
    let attempts: Int
}

enum SnapshotRenderError: Error, CustomStringConvertible {
    case noHost
    case blank(attempts: Int)
    case noImage(String)

    var description: String {
        switch self {
        case .noHost:
            "no window scene: on iOS the snapshot tests run in the catalog app (CatalogSnapshotTests), which "
                + "tools/apple/snapshot-matrix.sh ios builds and runs"
        case .blank(let attempts): "the render came back blank \(attempts) times"
        case .noImage(let why): "no image: \(why)"
        }
    }
}

@MainActor
enum SnapshotRenderer {
    /// How many times a blank render is drawn again before the picture fails. On the CI runner `drawHierarchy`
    /// sometimes returns nothing for a slow sheet (text fields at accessibility5, 13–17 s a render).
    static let attempts = 4

    /// The run loop turns this long before each attempt's picture, longer after a blank one: SwiftUI commits what it
    /// scheduled (its asynchronous updates, the representables) on the next turn.
    static func settle(attempt: Int) -> TimeInterval { [0.01, 0.1, 0.5, 2][min(attempt, 3)] }

    /// The arguments the catalog app would get for this picture.
    static func view(key: String, capture: ComponentMatrix.Capture) throws -> some View {
        let options = try CatalogLaunchOptions(arguments: ["-WestronMatrixSheet", key] + capture.launchArguments)
        return CatalogRootView(options: .success(options))
            // The process's locale is the machine's; SwiftUI's formatting takes the environment's.
            .environment(\.locale, Locale(identifier: "en_US"))
    }

    static func render(key: String, capture: ComponentMatrix.Capture) throws -> SnapshotPicture {
        var attempt = 0
        while attempt < attempts {
            if let picture = try draw(
                try view(key: key, capture: capture), dark: capture.theme.isDark, settle: settle(attempt: attempt)),
                !isBlank(picture.image)
            {
                return SnapshotPicture(
                    image: picture.image, size: picture.size, fits: picture.fits, attempts: attempt + 1)
            }
            attempt += 1
        }
        throw SnapshotRenderError.blank(attempts: attempts)
    }

    /// The sheet's frame in the window, in points, as laid out.
    final class Frame {
        var rect = CGRect.zero
    }

    /// The catalog's view with the sheet's frame reported into `frame`.
    static func reportingFrame(_ view: some View, into frame: Frame) -> some View {
        view.environment(\.matrixSheetFrame) { frame.rect = $0 }
    }

    /// Whether the cells end inside a window of `height` points: the sheet's frame less its bottom padding
    /// (`MatrixSheetView`), as the UI test checked every cell's frame against the window's.
    static func fits(_ frame: CGRect, height: CGFloat) -> Bool {
        frame.maxY - SampleMetrics.pagePadding <= height + 0.5
    }

    /// The part of a window's picture of `scale` pixels a point that holds the sheet.
    static func cut(_ image: CGImage, to frame: CGRect, window: CGSize, scale: CGFloat) -> (CGImage, CGSize)? {
        let top = max(0, frame.minY)
        let points = CGRect(x: 0, y: top, width: window.width, height: max(0, min(frame.maxY, window.height) - top))
        let pixels = CGRect(
            x: points.minX * scale, y: points.minY * scale, width: points.width * scale,
            height: points.height * scale
        ).integral
        guard pixels.width > 0, pixels.height > 0, let cropped = image.cropping(to: pixels),
            let opaque = opaque(cropped)
        else { return nil }
        return (opaque, CGSize(width: pixels.width / scale, height: pixels.height / scale))
    }

    #if os(iOS)
        static func draw(_ view: some View, dark: Bool, settle: TimeInterval) throws -> (
            image: CGImage, size: CGSize, fits: Bool
        )? {
            guard
                let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
            else { throw SnapshotRenderError.noHost }
            let frame = Frame()
            let controller = UIHostingController(rootView: reportingFrame(view, into: frame))
            let window = UIWindow(windowScene: scene)
            let screen = scene.screen
            window.frame = screen.bounds
            window.windowLevel = .alert + 1
            // The sheet sets its scheme itself (`preferredColorScheme`); the window agrees, for what UIKit draws.
            window.overrideUserInterfaceStyle = dark ? .dark : .light
            window.rootViewController = controller
            window.isHidden = false
            defer {
                window.isHidden = true
                window.rootViewController = nil
            }
            controller.view.setNeedsLayout()
            controller.view.layoutIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(settle))
            controller.view.layoutIfNeeded()
            let format = UIGraphicsImageRendererFormat()
            format.scale = screen.scale
            format.preferredRange = .standard
            format.opaque = false
            var drawn = false
            let image = UIGraphicsImageRenderer(size: window.bounds.size, format: format).image { _ in
                drawn = window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
            }
            // No frame yet: SwiftUI has not reported its layout, which counts as a blank render.
            guard drawn, let whole = image.cgImage, frame.rect.height > 0 else { return nil }
            guard let (picture, size) = cut(whole, to: frame.rect, window: window.bounds.size, scale: screen.scale)
            else { throw SnapshotRenderError.noImage("the sheet's frame \(frame.rect) is outside the window") }
            return (picture, size, fits(frame.rect, height: window.bounds.height))
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
    #elseif os(macOS)
        /// The backing scale of every picture, whatever the screens': SwiftUI rounds its layout and rasterizes its text
        /// at the window's scale, so a 1x runner would otherwise draw differently from a Retina Mac.
        static let scale: CGFloat = 2

        final class FixedScaleWindow: NSWindow {
            override var backingScaleFactor: CGFloat { SnapshotRenderer.scale }
        }

        static func draw(_ view: some View, dark: Bool, settle: TimeInterval) throws -> (
            image: CGImage, size: CGSize, fits: Bool
        )? {
            _ = NSApplication.shared
            let size = CatalogScene.windowSize
            let frame = Frame()
            let hosting = NSHostingView(rootView: reportingFrame(view, into: frame))
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
            defer {
                window.contentView = nil
                window.close()
            }
            hosting.layoutSubtreeIfNeeded()
            RunLoop.main.run(until: Date().addingTimeInterval(settle))
            hosting.layoutSubtreeIfNeeded()
            hosting.displayIfNeeded()
            guard let whole = try caRender(hosting, size: size), frame.rect.height > 0 else { return nil }
            guard let (picture, cutSize) = cut(whole, to: frame.rect, window: size, scale: scale) else {
                throw SnapshotRenderError.noImage("the sheet's frame \(frame.rect) is outside the window")
            }
            return (picture, cutSize, fits(frame.rect, height: size.height))
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
    #else
        static func draw(_ view: some View, dark: Bool, settle: TimeInterval) throws -> (
            image: CGImage, size: CGSize, fits: Bool
        )? { throw SnapshotRenderError.noHost }

        static var environment: (os: String, device: String, scale: Double) { ("", "", 0) }
    #endif

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

    /// Whether a picture holds next to nothing: fewer than three colors among a sample of its pixels. A sheet always
    /// has text on its canvas; a blank render is one color, black or transparent.
    static func isBlank(_ image: CGImage) -> Bool {
        guard let context = context(width: image.width, height: image.height, alpha: true) else { return true }
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let data = context.data else { return true }
        let bytes = data.assumingMemoryBound(to: UInt32.self)
        var seen = Set<UInt32>()
        var index = 0
        let count = image.width * image.height
        while index < count {
            seen.insert(bytes[index])
            if seen.count >= 3 { return false }
            index += 7
        }
        return true
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
