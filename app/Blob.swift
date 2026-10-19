// THE BLOB (v10, 19.10.2026). Marko: "sometimes I want to stop her. So please open the blob which looks like speechify
// blob, and I can pause, I can cancel, and I can start from the top. Start from the top is circular arrow, cancel is x
// ... blob can be moved by mouse, and then you need to remember the last position", then "this blob can enable disable
// subtitles as well."
//
// Speechify's dictation blob, copied from his screenshot: a dark pill, a grey round ✕ at the left, a white dotted wave
// in the middle, a blue round button at the right. Here: ✕ cancels the reading (POST /speak/stop), the wave moves while
// she speaks and stands still while paused, CC turns the subtitle on and off (kept in ~/.config/subtitle.json), ↻ says
// this reading again from its first sentence (/speak/top), the blue button pauses and plays (/speak/pause).
// It shows while the voice reads (the engine's GET /speaking) and goes when the reading ends. Dragged anywhere, its
// place is kept (UserDefaults "blobOrigin") and it comes back there.
import AppKit

let BLOB_W: CGFloat = 214, BLOB_H: CGFloat = 40
let BLUE = NSColor(calibratedRed: 0x3D / 255, green: 0x7B / 255, blue: 0xF7 / 255, alpha: 1)

final class BlobButton: NSView {
    var symbol: String { didSet { needsDisplay = true } }
    var circle: NSColor?; var tint: NSColor
    let action: () -> Void
    init(_ symbol: String, _ frame: NSRect, circle: NSColor?, tint: NSColor, _ action: @escaping () -> Void) {
        self.symbol = symbol; self.circle = circle; self.tint = tint; self.action = action; super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {}
    override func mouseUp(with e: NSEvent) { if bounds.contains(convert(e.locationInWindow, from: nil)) { action() } }
    override func draw(_ r: NSRect) {
        let d = min(bounds.width, bounds.height) - 6
        let c = NSRect(x: (bounds.width - d) / 2, y: (bounds.height - d) / 2, width: d, height: d)
        if let circle { circle.setFill(); NSBezierPath(ovalIn: c).fill() }
        let cfg = NSImage.SymbolConfiguration(pointSize: circle == nil ? 14 : 12, weight: .bold)
        guard let img = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?.withSymbolConfiguration(cfg) else { return }
        let t = NSImage(size: img.size, flipped: false) { rect in
            img.draw(in: rect); self.tint.set(); rect.fill(using: .sourceAtop); return true
        }
        t.draw(in: NSRect(x: c.midX - img.size.width / 2, y: c.midY - img.size.height / 2, width: img.size.width, height: img.size.height))
    }
}

// The dotted wave: short white bars, round-ended, rising and falling while she speaks; flat dots while paused.
final class WaveView: NSView {
    var moving = false
    var phase = 0.0
    override func draw(_ r: NSRect) {
        let n = 11, gap: CGFloat = 4, w: CGFloat = 2.6
        let x0 = (bounds.width - CGFloat(n) * w - CGFloat(n - 1) * gap) / 2
        NSColor(white: 1, alpha: 0.92).setFill()
        for i in 0..<n {
            let a = moving ? (0.5 + 0.5 * sin(phase * 2.3 + Double(i) * 0.9)) * (0.6 + 0.4 * sin(phase * 1.3 + Double(i) * 1.7)) : 0
            let h = max(w, CGFloat(a) * (bounds.height - 12) + w)
            let rect = NSRect(x: x0 + CGFloat(i) * (w + gap), y: (bounds.height - h) / 2, width: w, height: h)
            NSBezierPath(roundedRect: rect, xRadius: w / 2, yRadius: w / 2).fill()
        }
    }
}

final class PillView: NSView {
    var start: NSPoint?; var origin = NSPoint.zero
    var onMoved: () -> Void = {}
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func draw(_ r: NSRect) {
        let p = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: bounds.height / 2, yRadius: bounds.height / 2)
        NSColor(calibratedRed: 0.11, green: 0.11, blue: 0.12, alpha: 0.97).setFill(); p.fill()
        NSColor(white: 1, alpha: 0.10).setStroke(); p.lineWidth = 1; p.stroke()
    }
    // dragged by its body (the buttons keep their clicks)
    override func mouseDown(with e: NSEvent) { start = NSEvent.mouseLocation; origin = window?.frame.origin ?? .zero }
    override func mouseDragged(with e: NSEvent) {
        guard let s = start, let w = window else { return }
        let m = NSEvent.mouseLocation
        w.setFrameOrigin(NSPoint(x: origin.x + m.x - s.x, y: origin.y + m.y - s.y))
    }
    override func mouseUp(with e: NSEvent) { if start != nil { start = nil; onMoved() } }
}

final class Blob {
    static let shared = Blob()
    var panel: NSPanel?
    let wave = WaveView(frame: NSRect(x: 40, y: 0, width: 72, height: BLOB_H))
    var pauseKey: BlobButton!, ccKey: BlobButton!
    var timer: Timer?
    var paused = false
    var quiet = 0

    func make() -> NSPanel {
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: BLOB_W, height: BLOB_H),
                        styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        p.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)) + 1)   // above the subtitle band
        p.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        p.isOpaque = false; p.backgroundColor = .clear; p.hasShadow = true
        p.hidesOnDeactivate = false; p.becomesKeyOnlyIfNeeded = true
        let pill = PillView(frame: NSRect(x: 0, y: 0, width: BLOB_W, height: BLOB_H))
        pill.onMoved = { [weak self] in self?.remember() }
        let grey = NSColor(white: 0.36, alpha: 1), white = NSColor(white: 0.95, alpha: 1)
        pill.addSubview(BlobButton("xmark", NSRect(x: 4, y: 2, width: 36, height: 36), circle: grey, tint: white) { [weak self] in self?.cancel() })
        pill.addSubview(wave)
        ccKey = BlobButton("captions.bubble.fill", NSRect(x: 112, y: 2, width: 32, height: 36), circle: nil, tint: white) { [weak self] in self?.toggleSubtitles() }
        pill.addSubview(ccKey)
        pill.addSubview(BlobButton("arrow.counterclockwise", NSRect(x: 142, y: 2, width: 32, height: 36), circle: nil, tint: white) { [weak self] in self?.top() })
        pauseKey = BlobButton("pause.fill", NSRect(x: 174, y: 2, width: 36, height: 36), circle: BLUE, tint: white) { [weak self] in self?.togglePause() }
        pill.addSubview(pauseKey)
        for v in pill.subviews { v.toolTip = ["xmark": "Cancel", "captions.bubble.fill": "Subtitles on / off",
                                              "arrow.counterclockwise": "From the top", "pause.fill": "Pause / play"][(v as? BlobButton)?.symbol ?? ""] }
        p.contentView = pill
        p.setFrameOrigin(savedOrigin())
        return p
    }

    // the place he left it, if that is still on a screen; else the main screen's bottom middle, above the Dock
    func savedOrigin() -> NSPoint {
        if let a = UserDefaults.standard.array(forKey: "blobOrigin") as? [Double], a.count == 2 {
            let o = NSPoint(x: a[0], y: a[1])
            if NSScreen.screens.contains(where: { $0.frame.insetBy(dx: -BLOB_W / 2, dy: -BLOB_H / 2).contains(NSPoint(x: o.x + BLOB_W / 2, y: o.y + BLOB_H / 2)) }) { return o }
        }
        let v = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        return NSPoint(x: v.midX - BLOB_W / 2, y: v.minY + 60)
    }
    func remember() {
        guard let o = panel?.frame.origin else { return }
        UserDefaults.standard.set([Double(o.x), Double(o.y)], forKey: "blobOrigin")
    }

    func show() {
        if panel == nil { panel = make() }
        ccKey.symbol = SubtitleEngine.shared.conf.subtitles ? "captions.bubble.fill" : "captions.bubble"
        ccKey.tint = SubtitleEngine.shared.conf.subtitles ? NSColor(white: 0.95, alpha: 1) : NSColor(white: 0.5, alpha: 1)
        panel?.orderFrontRegardless()
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.wave.phase += 0.16; self.wave.needsDisplay = true
            }
        }
    }
    func hide() {
        timer?.invalidate(); timer = nil
        panel?.orderOut(nil)
    }

    // every answer of GET /speaking: shown while she reads, gone a moment after she has ended
    func heard(_ st: Speaking) {
        if st.on {
            quiet = 0
            paused = st.paused ?? false
            pauseKey?.symbol = paused ? "play.fill" : "pause.fill"
            show()
            wave.moving = !paused && (st.pos ?? -1) >= 0
        } else if panel?.isVisible == true {
            quiet += 1
            wave.moving = false
            if quiet >= 3 { hide() }
        }
    }

    func cancel() { post("/speak/stop"); hide(); SubtitleEngine.shared.hide() }
    func top() { postJSON("/speak/top", "{}"); paused = false; pauseKey.symbol = "pause.fill"; SubtitleEngine.shared.follow() }
    func togglePause() {
        paused.toggle()
        pauseKey.symbol = paused ? "play.fill" : "pause.fill"
        wave.moving = !paused
        postJSON("/speak/pause", paused ? "{\"paused\": true}" : "{\"paused\": false}")
    }
    func toggleSubtitles() {
        SubtitleEngine.shared.setSubtitles(!SubtitleEngine.shared.conf.subtitles)
        show()
    }
}

func postJSON(_ path: String, _ body: String) {
    var r = URLRequest(url: URL(string: VOICE_URL + path)!)
    r.httpMethod = "POST"; r.httpBody = Data(body.utf8); r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    URLSession.shared.dataTask(with: r).resume()
}
