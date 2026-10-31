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
//
// v11 (19.10.2026). Marko: "it's just animation, it should react to the voice itself ... divided by bands ... FFT ... in
// these vertical lines": the bars are the engine's GET /speak/bands, 11 bands of the sound reaching the speaker now
// (low at the left, high at the right), asked 24 times a second, through Spectral Analyzer's spectrum meter. Then "please also add to the blob setup gear
// icon": ⚙ opens this app's settings window.
import AppKit

let BLOB_W: CGFloat = 248, BLOB_H: CGFloat = 40, NAME_H: CGFloat = 16

// v15 (28.10.2026, Marko: "I want to be aware of what kind of engine is used for voice. We have API to Speechify. Then
// you need to put Speechify API. I have a local voice engine. Then you put Local Voice Engine"): the engine in his
// words, at the top of the window and in small letters above the blob, with the voice (and the local model reading now).
func engineName(_ engine: String, _ voice: String, _ model: String = "") -> String {
    if engine == "beatrice" { return "SPEECHIFY API · BEATRICE" }
    if engine == "clone" { return (["LOCAL VOICE ENGINE", voice.uppercased(), model.uppercased()].filter { !$0.isEmpty }).joined(separator: " · ") }
    return engine.isEmpty ? "NO ENGINE" : engine.uppercased()
}
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

// The wave: short white bars, round-ended, each one band of her sound, rising from one line; dots on it while silent.
// v11: SPECTRAL_ANALYZER's SPECTRUM meter, made small (Marko: "I have a professional meter ... take the code from that
// audio tools ... find a suitable meter from there and just attach it to this blob"). Its ballistics, as in
// Analyzer.spectrumAndPictures: FabFilter's 4.5 dB/oct tilt about 1 kHz, an attack at once, a release of 120 dB/s
// (SPEED VERY FAST: "make it fall off much faster"); no peak line (Marko: "looking good, but don't hold the peaks, please"). RANGE is 54 dB below a top
// of -6 dB, the height of a voice in a bar of 28 points.
struct Bands: Decodable { var on: Bool; var bands: [Double]; var db: [Double]? }
final class WaveView: NSView {
    static let TILT = 4.5, RELEASE = 120.0, TOP = -6.0, RANGE = 54.0
    static let centres: [Double] = (0..<11).map { 80 * pow(11000.0 / 80, (Double($0) + 0.5) / 11) }
    var moving = false
    var spec = [Double](repeating: -140, count: 11)
    var last = CFAbsoluteTimeGetCurrent()
    var levels: [Double] { spec.map { WaveView.height($0) } }
    static func height(_ db: Double) -> Double { min(1, max(0, (db - (TOP - RANGE)) / RANGE)) }
    func take(_ b: Bands?) {
        let t = CFAbsoluteTimeGetCurrent(), dt = min(0.2, t - last); last = t
        let db = b?.db ?? b?.bands.map { $0 > 0 ? $0 * 50 - 62 : -140 } ?? []
        for c in 0..<spec.count {
            var m = moving && c < db.count ? db[c] : -140
            if m > -140 { m += WaveView.TILT * log2(WaveView.centres[c] / 1000) }
            spec[c] = m > spec[c] ? m : max(m, spec[c] - WaveView.RELEASE * dt)
        }
        needsDisplay = true
    }
    override func draw(_ r: NSRect) {
        let n = levels.count, gap: CGFloat = 4, w: CGFloat = 2.6
        let x0 = (bounds.width - CGFloat(n) * w - CGFloat(n - 1) * gap) / 2
        NSColor(white: 1, alpha: 0.92).setFill()
        for i in 0..<n {
            let a = WaveView.height(spec[i])
            // only the upper half (Marko, 19.10.2026): each bar stands on one line and rises, as a spectrum does
            let h = max(w, CGFloat(a) * (bounds.height - 16) + w)
            let rect = NSRect(x: x0 + CGFloat(i) * (w + gap), y: 9, width: w, height: h)
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
    let wave = WaveView(frame: NSRect(x: 40, y: 0, width: 74, height: BLOB_H))
    let name = NSTextField(labelWithString: "")
    var pauseKey: BlobButton!, ccKey: BlobButton!
    var timer: Timer?
    var asking = false
    var paused = false
    var quiet = 0

    func make() -> NSPanel {
        let p = NSPanel(contentRect: NSRect(x: 0, y: 0, width: BLOB_W, height: BLOB_H + NAME_H),
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
        ccKey = BlobButton("captions.bubble.fill", NSRect(x: 114, y: 2, width: 32, height: 36), circle: nil, tint: white) { [weak self] in self?.toggleSubtitles() }
        pill.addSubview(ccKey)
        pill.addSubview(BlobButton("gearshape.fill", NSRect(x: 146, y: 2, width: 32, height: 36), circle: nil, tint: white) {
            (NSApp.delegate as? Delegate)?.openSettings() })
        pill.addSubview(BlobButton("arrow.counterclockwise", NSRect(x: 176, y: 2, width: 32, height: 36), circle: nil, tint: white) { [weak self] in self?.top() })
        pauseKey = BlobButton("pause.fill", NSRect(x: 208, y: 2, width: 36, height: 36), circle: BLUE, tint: white) { [weak self] in self?.togglePause() }
        pill.addSubview(pauseKey)
        for v in pill.subviews { v.toolTip = ["xmark": "Cancel", "captions.bubble.fill": "Subtitles on / off", "gearshape.fill": "Setup",
                                              "arrow.counterclockwise": "From the top", "pause.fill": "Pause / play"][(v as? BlobButton)?.symbol ?? ""] }
        let box = NSView(frame: NSRect(x: 0, y: 0, width: BLOB_W, height: BLOB_H + NAME_H))
        // v16 (Marko, 31.10.2026: "Whatever is written atop of the voice blob ... It's written over subtitles"): the
        // engine's name goes UNDER the pill. The blob sits at the bottom of the subtitle band, so above it the name
        // lay on the subtitle's words; under it, it is below the text.
        pill.setFrameOrigin(NSPoint(x: 0, y: NAME_H))
        box.addSubview(pill)
        name.frame = NSRect(x: 0, y: 1, width: BLOB_W, height: NAME_H - 2)
        name.isBezeled = false; name.drawsBackground = false; name.isEditable = false; name.isSelectable = false
        name.alignment = .center; name.font = .monospacedSystemFont(ofSize: 9.5, weight: .semibold)
        name.textColor = NSColor(white: 1, alpha: 0.75)
        let sh = NSShadow(); sh.shadowColor = .black; sh.shadowBlurRadius = 3; name.shadow = sh
        box.addSubview(name)
        p.contentView = box
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
        askName()
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24, repeats: true) { [weak self] _ in
                self?.askBands()
            }
        }
    }
    // v15: which engine reads: GET /health (engine, voice), GET /speaking (the local model of this reading)
    func askName() {
        func get(_ path: String, _ done: @escaping ([String: Any]) -> Void) {
            var r = URLRequest(url: URL(string: VOICE_URL + path)!); r.timeoutInterval = 1
            URLSession.shared.dataTask(with: r) { d, _, _ in
                done((d.flatMap { try? JSONSerialization.jsonObject(with: $0) } as? [String: Any]) ?? [:])
            }.resume()
        }
        get("/health") { h in get("/speaking") { s in
            let t = engineName(h["engine"] as? String ?? "", h["voice"] as? String ?? "", s["model"] as? String ?? "")
            DispatchQueue.main.async { self.name.stringValue = t }
        } }
    }
    // GET /speak/bands, one question at a time: a late answer is skipped, never queued
    func askBands() {
        if asking { return }
        asking = true
        var r = URLRequest(url: URL(string: VOICE_URL + "/speak/bands")!); r.timeoutInterval = 0.5
        URLSession.shared.dataTask(with: r) { [weak self] d, _, _ in
            let b = d.flatMap { try? JSONDecoder().decode(Bands.self, from: $0) }
            DispatchQueue.main.async { self?.asking = false; self?.wave.take(b) }
        }.resume()
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
