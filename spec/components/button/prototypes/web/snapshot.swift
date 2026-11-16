// Prototype only (#26): renders index.html in WebKit (WKWebView, the engine of Safari) to a PNG, or probes the real
// pseudo-classes and clicks with synthetic mouse and keyboard events. Run from the repository root:
//
//   source tools/apple/xcode-env.sh
//   swift spec/components/button/prototypes/web/snapshot.swift shot OUT.png [QUERY] [--dark]
//   swift spec/components/button/prototypes/web/snapshot.swift probe
//
// QUERY is the page's query string without "?", such as "theme=dark-hc" or "hit=44&hitarea". --dark gives the web
// view the dark appearance, so prefers-color-scheme: dark matches for real. The probe prints what WebKit reports.
import AppKit
import WebKit

let arguments = CommandLine.arguments.dropFirst()
let page = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    .appendingPathComponent("spec/components/button/prototypes/web/index.html")

final class Loader: NSObject, WKNavigationDelegate {
    var done = false
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) { done = true }
}

func spin(until condition: () -> Bool, timeout: TimeInterval = 20) {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() && Date() < deadline { RunLoop.main.run(until: Date().addingTimeInterval(0.02)) }
    if !condition() { fatalError("timed out") }
}

func pause(_ seconds: TimeInterval) { RunLoop.main.run(until: Date().addingTimeInterval(seconds)) }

@MainActor
func evaluate(_ webView: WKWebView, _ script: String) -> Any? {
    var result: Any?
    var finished = false
    webView.evaluateJavaScript(script) { value, error in
        if let error { fatalError("JavaScript failed: \(error)") }
        result = value
        finished = true
    }
    spin(until: { finished })
    return result
}

@MainActor
func open(query: String, dark: Bool, width: CGFloat = 1500, height: CGFloat = 900) -> (NSWindow, WKWebView) {
    _ = NSApplication.shared
    NSApp.setActivationPolicy(.accessory)
    let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: width, height: height))
    webView.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
    let window = NSWindow(
        contentRect: NSRect(x: -30000, y: -30000, width: width, height: height), styleMask: [.borderless],
        backing: .buffered, defer: false)  // off screen, so nothing shows on the person's display
    window.acceptsMouseMovedEvents = true
    window.contentView = webView
    window.orderFrontRegardless()
    let loader = Loader()
    webView.navigationDelegate = loader
    var components = URLComponents(url: page, resolvingAgainstBaseURL: false)!
    components.query = query.isEmpty ? nil : query
    webView.loadFileURL(components.url!, allowingReadAccessTo: page.deletingLastPathComponent())
    spin(until: { loader.done })
    pause(0.5)
    return (window, webView)
}

@MainActor
func shot(out: String, query: String, dark: Bool) {
    let (window, webView) = open(query: query, dark: dark)
    let height = (evaluate(webView, "document.documentElement.scrollHeight") as? NSNumber)?.doubleValue ?? 900
    let width = (evaluate(webView, "document.documentElement.scrollWidth") as? NSNumber)?.doubleValue ?? 1500
    window.setContentSize(NSSize(width: width, height: height))
    webView.frame = NSRect(x: 0, y: 0, width: width, height: height)
    pause(0.5)
    let configuration = WKSnapshotConfiguration()
    configuration.rect = NSRect(x: 0, y: 0, width: width, height: height)
    var image: NSImage?
    webView.takeSnapshot(with: configuration) { snapshot, error in
        if let error { fatalError("snapshot failed: \(error)") }
        image = snapshot
    }
    spin(until: { image != nil })
    guard let tiff = image?.tiffRepresentation, let bitmap = NSBitmapImageRep(data: tiff),
        let png = bitmap.representation(using: .png, properties: [:])
    else { fatalError("no PNG") }
    try! png.write(to: URL(fileURLWithPath: out))
    print(out)
}

/// Moves a real (synthetic) pointer over each live button, presses it, and reads back what WebKit matched.
@MainActor
func probe() {
    let (window, webView) = open(query: "", dark: false)
    window.makeKey()
    // Transitions do not advance in a window that is not on screen, so the probe reads end states without them.
    _ = evaluate(
        webView,
        "document.head.insertAdjacentHTML('beforeend', '<style>*, *::before, *::after { transition: none !important; }</style>'); 0"
    )
    func center(_ id: String) -> NSPoint {
        let point =
            evaluate(
                webView,
                "(() => { const b = document.getElementById('\(id)'); b.scrollIntoView({block: 'center'}); const s = b.getBoundingClientRect(); return [s.x + s.width / 2, s.y + s.height / 2]; })()"
            ) as! [NSNumber]
        return NSPoint(x: point[0].doubleValue, y: webView.bounds.height - point[1].doubleValue)
    }
    func mouse(_ type: NSEvent.EventType, _ point: NSPoint) {
        let event = NSEvent.mouseEvent(
            with: type, location: point, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1,
            pressure: type == .leftMouseUp ? 0 : 1)!
        switch type {
        case .mouseMoved: webView.mouseMoved(with: event)
        case .leftMouseDown: webView.mouseDown(with: event)
        case .leftMouseUp: webView.mouseUp(with: event)
        default: break
        }
        pause(0.3)
    }
    func state(_ id: String) -> String {
        evaluate(
            webView,
            "(() => { const b = document.getElementById('\(id)'); const s = getComputedStyle(b); return `:hover=${b.matches(':hover')} :active=${b.matches(':active')} :focus=${b.matches(':focus')} :focus-visible=${b.matches(':focus-visible')} background=${s.backgroundColor} transform=${s.transform} outline=${s.outlineStyle} ${s.outlineWidth}`; })()"
        ) as? String ?? "?"
    }
    // Counts every click WebKit dispatches, on window in the capture phase, ahead of the page's own listener on
    // document that refuses clicks on a busy button; the page's log shows the clicks its handlers accepted.
    _ = evaluate(
        webView,
        "window.dispatched = []; addEventListener('click', e => { const b = e.target.closest('button'); if (b) dispatched.push(b.id); }, true); 0"
    )
    func clicks(_ phase: String) {
        let dispatched = evaluate(webView, "dispatched.splice(0).join(', ')") as? String ?? "?"
        let accepted = evaluate(webView, "(() => { const l = document.getElementById('log'); const t = l.textContent.trim().split('\\n').filter(Boolean).map(s => s.replace('click accepted: #', '')).join(', '); l.textContent = ''; return t; })()") as? String ?? "?"
        print("  \(phase): clicks dispatched [\(dispatched)], accepted by the page's handlers [\(accepted)]")
    }
    print("Pointer (synthetic NSEvents to the WKWebView):")
    for id in ["live-primary", "live-busy", "live-disabled"] {
        let point = center(id)
        mouse(.mouseMoved, point)
        print("  \(id) after mouseMoved: \(state(id))")
        mouse(.leftMouseDown, point)
        print("  \(id) after mouseDown:  \(state(id))")
        mouse(.leftMouseUp, point)
        clicks("\(id) after mouseUp")
    }
    print("Keyboard (focus(), then Space and Return as NSEvents):")
    for id in ["live-primary", "live-busy"] {
        _ = evaluate(webView, "document.getElementById('\(id)').focus(); 0")
        print("  \(id) focused: \(state(id))")
        for (characters, keyCode) in [(" ", UInt16(49)), ("\r", UInt16(36))] {
            for type in [NSEvent.EventType.keyDown, .keyUp] {
                let event = NSEvent.keyEvent(
                    with: type, location: .zero, modifierFlags: [], timestamp: ProcessInfo.processInfo.systemUptime,
                    windowNumber: window.windowNumber, context: nil, characters: characters,
                    charactersIgnoringModifiers: characters, isARepeat: false, keyCode: keyCode)!
                if type == .keyDown { webView.keyDown(with: event) } else { webView.keyUp(with: event) }
                pause(0.2)
            }
        }
        clicks("\(id) after Space and Return")
    }
    print("Press scale of a forced pressed button, then with the reduced-motion rules forced:")
    let pressed = "getComputedStyle(document.querySelector('#states [data-state=pressed]:not([disabled]):not([aria-busy])')).transform"
    print("  " + (evaluate(webView, pressed) as? String ?? "?"))
    _ = evaluate(webView, "document.documentElement.dataset.motion = 'reduce'; 0")
    print("  " + (evaluate(webView, pressed) as? String ?? "?"))
    print("Media features WebKit reports here:")
    print(
        "  "
            + (evaluate(
                webView,
                "['(hover: hover)', '(pointer: fine)', '(pointer: coarse)', '(prefers-reduced-motion: reduce)', '(prefers-contrast: more)', '(forced-colors: active)'].map(q => `${q}=${matchMedia(q).matches}`).join(' ')"
            ) as? String ?? "?"))
}

MainActor.assumeIsolated {
    switch arguments.first {
    case "shot":
        let rest = Array(arguments.dropFirst())
        guard let out = rest.first else { fatalError("usage: shot OUT.png [QUERY] [--dark]") }
        let query = rest.dropFirst().first(where: { !$0.hasPrefix("--") }) ?? ""
        shot(out: out, query: query, dark: rest.contains("--dark"))
    case "probe":
        probe()
    default:
        print("usage: snapshot.swift shot OUT.png [QUERY] [--dark] | probe")
        exit(2)
    }
}
