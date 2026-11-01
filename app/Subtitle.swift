// THE SUBTITLE ITSELF (v8, 13.10.2026). Marko: "We are quitting the Lua, no more Lua, only Swift". Until v7 the
// subtitle was drawn by the star (MANTRA_STAR apps/voice.lua, VOICEBUBBLE); now this app draws it, exactly as voice.lua
// did, and runs as the subtitle engine for as long as it runs.
//
// What it is (Marko, 3.10.2026): on EVERY screen a band across the whole width, translucent grey, the sentence being
// spoken in big letters, centred and wrapped like a film's subtitle, never cut short. At its left end − and +, big
// (the letters smaller or larger, live, kept in ~/.config/subtitle.json); at its right end PREVIOUS NEXT REPLAY CLOSE.
// The word being said turns from the sentence's colour to the word's colour, timed by the server's word timings
// (GET /speaking: pos, words) on MA Reader's clock. When the voice ends the last sentence stays for `linger` seconds
// (0: until clicked). A click on the text opens the answer box (Answer Claude (Mantra).app). `bandmain` false: no band
// on the main screen, letters only (13.10.2026).
//
// How it knows a reading started: voice.lua was told by voiced.py (`hs -c VOICEBUBBLE.show()`); this engine asks
// GET /speaking once a second while nothing shows, and five times a second while it does. It never starts the voice.
import AppKit

let VOICE_URL = "http://127.0.0.1:8837"
let FONT = "Helvetica Neue"
let KW: CGFloat = 430            // the right keys' width
let LW: CGFloat = 150            // the left keys' width
let LEAD = 0.05                  // MA Reader's WORD_LEAD: a word lit a breath early reads as on time
let HIDE_NOTE = "community.auroville.subtitle.hide"     // the answer box says: the subtitle closes

func nscolour(_ hex: String, _ alpha: CGFloat = 1) -> NSColor? {
    let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard !h.isEmpty, let v = UInt32(h, radix: 16) else { return nil }
    return NSColor(calibratedRed: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: alpha)
}

struct SubWord: Decodable { var s: Int?; var e: Int?; var t: Double?; var d: Double? }
struct Speaking: Decodable {
    var on: Bool; var paused: Bool?; var phase: String?; var i: Int?; var n: Int?; var sentence: String?; var pos: Double?; var words: [SubWord]?
    var held: String?        // v21: why the engine holds this reading ('' when it does not)
}

func post(_ path: String) {
    var r = URLRequest(url: URL(string: VOICE_URL + path)!)
    r.httpMethod = "POST"; r.httpBody = Data("{}".utf8); r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    URLSession.shared.dataTask(with: r).resume()
}

// MARK: one screen's subtitle: a borderless panel across the screen, above full-screen apps, never taking the focus

final class KeyLabel: NSView {
    let text: String; let size: CGFloat; let action: () -> Void
    init(_ text: String, _ size: CGFloat, _ frame: NSRect, _ action: @escaping () -> Void) {
        self.text = text; self.size = size; self.action = action; super.init(frame: frame)
    }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {}
    override func mouseUp(with e: NSEvent) { action() }
    override func draw(_ r: NSRect) {
        let p = NSMutableParagraphStyle(); p.alignment = .center
        let a: [NSAttributedString.Key: Any] = [.font: NSFont(name: FONT, size: size) ?? .systemFont(ofSize: size),
                                                .foregroundColor: NSColor(white: 0.92, alpha: 0.9), .paragraphStyle: p]
        let h = size * 1.3
        (text as NSString).draw(in: NSRect(x: 0, y: (bounds.height - h) / 2, width: bounds.width, height: h), withAttributes: a)
    }
}

final class BandView: NSView {
    var fill = NSColor.clear
    var text = NSAttributedString()
    var textRect = NSRect.zero
    var onClick: () -> Void = {}
    // v18 (Marko, 31.10.2026: "I clicked on the subtitle itself and it disappeared ... add a feature that I can click on the
    // subtitle and pull it vertically only on the screen, wherever I want to, with my mouse while it's reading"): a drag
    // moves the band up or down only (every screen follows, the place is kept in subtitle.json `ypos`); a click never
    // hides it; a double-click opens the answer box, as a single click did before.
    var onDrag: (CGFloat) -> Void = { _ in }            // the band's new centre y, in screen points
    var onDragEnd: () -> Void = {}
    private var grab: CGFloat?, startCentre: CGFloat = 0, moved = false
    override var isFlipped: Bool { true }                // top-left, as voice.lua laid it out
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func resetCursorRects() { addCursorRect(bounds, cursor: .resizeUpDown) }
    override func mouseDown(with e: NSEvent) {
        grab = NSEvent.mouseLocation.y; startCentre = window?.frame.midY ?? 0; moved = false
    }
    override func mouseDragged(with e: NSEvent) {
        guard let g = grab else { return }
        let dy = NSEvent.mouseLocation.y - g
        if abs(dy) > 3 { moved = true }
        if moved { onDrag(startCentre + dy) }
    }
    override func mouseUp(with e: NSEvent) {
        let wasDrag = moved; grab = nil; moved = false
        if wasDrag { onDragEnd(); return }
        if e.clickCount == 2 { onClick() }
    }
    override func draw(_ r: NSRect) {
        fill.setFill(); bounds.fill()
        text.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading])
    }
}

final class ScreenSub {
    let screen: NSScreen
    let panel: NSPanel
    let band = BandView()
    var size: CGFloat = 40
    init(_ screen: NSScreen, _ engine: SubtitleEngine) {
        self.screen = screen
        panel = NSPanel(contentRect: screen.visibleFrame, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.overlayWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.hidesOnDeactivate = false; panel.becomesKeyOnlyIfNeeded = true
        panel.contentView = band
        band.onClick = { [weak engine] in engine?.answer() }
        band.onDrag = { [weak engine, weak self] y in if let s = self { engine?.dragTo(y, on: s) } }
        band.onDragEnd = { [weak engine] in engine?.dragDone() }
        let left: [(String, CGFloat, () -> Void)] = [("−", 0, { [weak engine] in engine?.resize(-0.5) }),
                                                      ("+", 76, { [weak engine] in engine?.resize(0.5) })]
        for (t, x, f) in left { band.addSubview(KeyLabel(t, 52, NSRect(x: 12 + x, y: 0, width: 70, height: 70), f)) }
        // Marko: "add an action button replay ... the whole message"; "put the word close because this is the closing subtitle"
        let right: [(String, CGFloat, CGFloat, () -> Void)] = [
            ("PREVIOUS", 0, 130, { [weak engine] in post("/speak/prev"); engine?.follow() }),
            ("NEXT", 130, 100, { [weak engine] in post("/speak/next"); engine?.follow() }),
            ("REPLAY", 230, 100, { [weak engine] in post("/speak/replay"); engine?.follow() }),
            ("CLOSE", 330, 100, { [weak engine] in post("/speak/close"); engine?.hide() })]
        for (t, x, w, f) in right { band.addSubview(KeyLabel(t, 17, NSRect(x: x, y: 0, width: w, height: 44), f)) }
    }
    var keyViews: [KeyLabel] { band.subviews.compactMap { $0 as? KeyLabel } }

    // how tall the band must be for this text on this screen: the lines it wraps to, at the subtitle's size
    func layout(_ c: SubtitleSettings, _ text: String) {
        let vf = screen.visibleFrame
        size = max(14, floor(vf.height * CGFloat(c.size) / 100))
        let room = vf.width - LW - KW - 48
        let font = NSFont(name: c.bold ? FONT + " Bold" : FONT, size: size) ?? .systemFont(ofSize: size)
        let wide = (text as NSString).size(withAttributes: [.font: font]).width
        let lines = max(1, min(6, ceil(wide / (room * 0.92))))
        let h = max(floor(lines * size * 1.22 + size * 0.7), 110)
        var y = vf.minY + floor((vf.height - h) / 2)                  // Cocoa's y grows upward
        if c.position == "bottom" { y = vf.minY } else if c.position == "top" { y = vf.maxY - h }
        if c.ypos >= 0 { y = ScreenSub.clampY(vf.minY + CGFloat(c.ypos) * vf.height - h / 2, h, vf) }   // v18: dragged
        panel.setFrame(NSRect(x: vf.minX, y: y, width: vf.width, height: h), display: false)
        let main = NSScreen.screens.first.map { $0 == screen } ?? false
        let alpha = (!c.bandmain && main) ? 0 : CGFloat(c.band) / 100
        band.fill = NSColor(white: CGFloat(c.grey) / 100, alpha: alpha)
        band.textRect = NSRect(x: LW + 24, y: max(4, (h - lines * size * 1.22) / 2 - size * 0.08), width: room, height: h)
        let keys = keyViews
        for k in keys.prefix(2) { k.frame.origin.y = (h - 70) / 2 }
        for k in keys.dropFirst(2) { k.frame.origin.y = (h - 44) / 2 }       // x: SubtitleEngine.placeKeys
    }
    static func clampY(_ y: CGFloat, _ h: CGFloat, _ vf: NSRect) -> CGFloat { min(max(y, vf.minY), vf.maxY - h) }
    /// v18: the band moved so its centre is at this fraction of the screen's height (0 bottom, 1 top), height kept
    func moveTo(fraction f: CGFloat) {
        let vf = screen.visibleFrame, h = panel.frame.height
        panel.setFrameOrigin(NSPoint(x: vf.minX, y: ScreenSub.clampY(vf.minY + f * vf.height - h / 2, h, vf)))
    }
    func show() { panel.orderFrontRegardless() }
    func close() { panel.orderOut(nil); panel.close() }
}

// MARK: the engine

final class SubtitleEngine {
    static let shared = SubtitleEngine()
    var subs: [ScreenSub] = []
    var conf = SubtitleSettings.load()
    var text = ""; var words: [SubWord] = []; var lit = -2
    var testTimer: Timer?; var lingerTimer: Timer?; var tick: Timer?
    var following = false; var polling = false
    var quiet = 0; var shownI = -1
    var dismissed = false; var dismissedN = -1      // clicked away: the voice goes on unseen until the next reading
    // MA Reader's clock: predicted between answers, eased toward each answer, snapped when far off
    var pred = -1.0, wall = 0.0, sentence = -1, playing = false

    func start() {
        DistributedNotificationCenter.default().addObserver(forName: Notification.Name(HIDE_NOTE), object: nil, queue: .main) { [weak self] _ in self?.hide() }
        NotificationCenter.default.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self, !self.subs.isEmpty else { return }
            self.drop(); self.open(); self.show(self.text, self.words)      // a display plugged in or out
        }
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in self?.pollOnce() }
    }

    // the right keys are laid at the screen's right edge, the left ones at its left
    func placeKeys(_ s: ScreenSub) {
        let w = s.screen.visibleFrame.width, keys = s.keyViews
        let xs: [CGFloat] = [0, 130, 230, 330]
        for (i, k) in keys.dropFirst(2).enumerated() { k.frame.origin.x = w - KW - 12 + xs[i] }
    }

    func open() {
        conf = SubtitleSettings.load()
        guard subs.isEmpty, conf.subtitles else { return }      // v10: the blob's CC turns the subtitle off
        subs = NSScreen.screens.map { ScreenSub($0, self) }
        subs.forEach { $0.show() }
    }
    func drop() { subs.forEach { $0.close() }; subs = [] }
    // v10, the blob's CC: on, the subtitle comes back at once with the sentence being said; off, it goes and stays gone
    func setSubtitles(_ on: Bool) {
        var c = SubtitleSettings.load(); c.subtitles = on; c.save(); conf = c
        if on { bringBack() } else { drop() }          // v18: on brings it back at once, following or not
    }

    func styled(_ s: ScreenSub, _ k: Int) -> NSAttributedString {
        let font = NSFont(name: conf.bold ? FONT + " Bold" : FONT, size: s.size) ?? .systemFont(ofSize: s.size)
        let p = NSMutableParagraphStyle(); p.alignment = .center; p.lineBreakMode = .byWordWrapping
        let col = nscolour(conf.colour) ?? nscolour("#E8A33D")!
        let a = NSMutableAttributedString(string: text, attributes: [.font: font, .foregroundColor: col, .paragraphStyle: p])
        if k >= 0, k < words.count, let st = words[k].s, let en = words[k].e {
            // the server counts characters (code points), NSString counts UTF-16: convert
            let scalars = Array(text.unicodeScalars)
            if st >= 0, en <= scalars.count, st < en {
                let pre = String(String.UnicodeScalarView(scalars[0..<st])).utf16.count
                let len = String(String.UnicodeScalarView(scalars[st..<en])).utf16.count
                var at: [NSAttributedString.Key: Any] = [.foregroundColor: nscolour(conf.word) ?? nscolour("#FF3B30")!]
                if let bg = nscolour(conf.wordbg, 0.9) { at[.backgroundColor] = bg }
                a.addAttributes(at, range: NSRange(location: pre, length: len))
            }
        }
        return a
    }
    func paint(_ k: Int) { for s in subs { s.band.text = styled(s, k); s.band.needsDisplay = true } }
    func show(_ t: String, _ ws: [SubWord]) {
        text = t; words = ws; lit = -2
        conf = SubtitleSettings.load()                 // the settings window's changes, live
        for s in subs { s.layout(conf, t); placeKeys(s) }
        paint(-1)
    }
    func resize(_ step: Double) {
        var c = SubtitleSettings.load(); c.size = max(2, min(14, c.size + step)); c.save(); conf = c
        for s in subs { s.layout(conf, text); placeKeys(s) }
        paint(lit)
    }

    func hide() {
        tick?.invalidate(); tick = nil
        lingerTimer?.invalidate(); lingerTimer = nil
        following = false; playing = false
        drop()
    }
    // a look without a reading: the subtitle with this text for some seconds (for testing the design)
    func test(_ t: String, _ seconds: Double = 8) {
        drop(); open(); show(t, [])
        testTimer?.invalidate()
        testTimer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            self?.testTimer = nil; if self?.following == false { self?.drop() }
        }
    }
    func follow() {
        lingerTimer?.invalidate(); lingerTimer = nil
        dismissed = false
        if subs.isEmpty || !following { quiet = 0; shownI = -1; text = "" }
        open()
        following = true
        if tick == nil { tick = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in self?.frame() } }
    }
    // A CLICK ANSWERS (3.10.2026): the box opens (one at a time) and the band steps aside while he types
    func answer() {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "community.auroville.answerclaude").isEmpty {
            let cfg = NSWorkspace.OpenConfiguration(); cfg.createsNewApplicationInstance = true; cfg.arguments = ["--said", text]
            NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: "/Applications/Answer Claude (Mantra).app"), configuration: cfg)
        }
        // v18: the subtitle stays (Marko, 31.10.2026: "I clicked on the subtitle itself and it disappeared")
    }

    // v18: dragging. The band on the screen under the mouse follows it; every other screen takes the same height fraction
    var dragFraction: CGFloat?
    func dragTo(_ centreY: CGFloat, on s: ScreenSub) {
        let vf = s.screen.visibleFrame
        let f = min(max((centreY - vf.minY) / vf.height, 0), 1)
        dragFraction = f
        for x in subs { x.moveTo(fraction: f) }
    }
    func dragDone() {
        guard let f = dragFraction else { return }
        dragFraction = nil
        var c = SubtitleSettings.load(); c.ypos = Double(f); c.save(); conf = c
    }
    /// v18: the blob brings the subtitle back while she reads: CC on, dismissal forgotten, following again
    func bringBack() {
        var c = SubtitleSettings.load()
        if !c.subtitles { c.subtitles = true; c.save(); conf = c }
        dismissed = false
        follow()
        if !text.isEmpty { show(text, words) }
    }

    // GET /speaking: five times a second while following, once a second while idle
    var idleCount = 0
    func pollOnce() {
        if polling { return }
        if !following { idleCount += 1; if idleCount < 5 { return } }
        idleCount = 0
        var r = URLRequest(url: URL(string: VOICE_URL + "/speaking")!); r.timeoutInterval = 1
        polling = true
        URLSession.shared.dataTask(with: r) { d, _, _ in
            let st = d.flatMap { try? JSONDecoder().decode(Speaking.self, from: $0) }
            DispatchQueue.main.async { self.polling = false; if let st = st { self.heard(st) } }
        }.resume()
    }
    func heard(_ st: Speaking) {
        Blob.shared.heard(st)
        if !following {
            // a reading began (or goes on after he clicked it away: then only a new reading brings it back)
            guard st.on else { dismissed = false; return }
            if dismissed && (st.n ?? -1) == dismissedN { return }
            follow()
        }
        if !st.on {
            playing = false
            if lit != -1 { lit = -1; paint(-1) }
            quiet += 1
            // the voice has ended: the last sentence stays a while, so PREVIOUS can still be pressed (0: until clicked)
            if quiet == 3 && lingerTimer == nil && conf.linger > 0 {
                lingerTimer = Timer.scheduledTimer(withTimeInterval: conf.linger, repeats: false) { [weak self] _ in
                    self?.lingerTimer = nil; self?.hide()
                }
            }
            return
        }
        dismissedN = st.n ?? -1
        quiet = 0
        lingerTimer?.invalidate(); lingerTimer = nil
        let sent = st.sentence ?? ""
        if st.phase == "making" && sent.isEmpty { if text != "…" { show("…", []) }; return }
        if (st.i ?? -1) != shownI || text != sent { shownI = st.i ?? -1; show(sent, st.words ?? []) }
        sample(st.pos ?? -1, st.i ?? -1)
    }
    func sample(_ observed: Double, _ s: Int) {
        let now = Date().timeIntervalSince1970
        if s != sentence || observed < 0 { sentence = s; pred = observed; wall = now; playing = observed >= 0; return }
        pred += now - wall; wall = now
        let err = observed - pred
        if abs(err) > 0.35 { pred = observed } else { pred += err * 0.5 }
        playing = true
    }
    func frame() {
        guard playing, !subs.isEmpty else { return }
        let now = Date().timeIntervalSince1970
        pred += now - wall; wall = now
        let t = pred + LEAD + conf.offset / 1000
        var k = -1, lo = 0, hi = words.count - 1
        while lo <= hi {                                   // the last word started at t: a binary search
            let m = (lo + hi) / 2
            if (words[m].t ?? 0) <= t { k = m; lo = m + 1 } else { hi = m - 1 }
        }
        if k == words.count - 1, k >= 0, let d = words[k].d, t > (words[k].t ?? 0) + d + 0.12 { k = -1 }   // the last word lets go
        if k != lit { lit = k; paint(k) }
    }
}
