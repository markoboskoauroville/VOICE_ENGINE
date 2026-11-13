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
let KW: CGFloat = 0              // v43: no keys at the right any more; the group is one centred row under the text (alignment.md)
let ROWW: [CGFloat] = [224, 152, 112]   // the three rows' widths (v43)
let ROWH: CGFloat = 52
let LW: CGFloat = 24             // v29: no keys on the left any more (− + gone, Marko: "font size is good")
let LEAD = 0.05                  // MA Reader's WORD_LEAD: a word lit a breath early reads as on time
let HIDE_NOTE = "community.auroville.subtitle.hide"     // the answer box says: the subtitle closes

func nscolour(_ hex: String, _ alpha: CGFloat = 1) -> NSColor? {
    let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    guard !h.isEmpty, let v = UInt32(h, radix: 16) else { return nil }
    return NSColor(calibratedRed: CGFloat((v >> 16) & 255) / 255, green: CGFloat((v >> 8) & 255) / 255, blue: CGFloat(v & 255) / 255, alpha: alpha)
}

struct SubWord: Decodable { var s: Int?; var e: Int?; var t: Double?; var d: Double? }
struct Speaking: Decodable {
    var on: Bool; var speed: Double?; var queue: Int?; var paused: Bool?; var phase: String?; var i: Int?; var n: Int?; var sentence: String?; var pos: Double?; var words: [SubWord]?
    var held: String?        // v21: why the engine holds this reading ('' when it does not)
}

// v30 (Marko, 4.11.2026: "When I press Stop ... the sub icon is left on the title bar. Everything should exit"; his v29
// words: "Stop stops the talking completely. It exits the engine"). The subtitle's STOP ends the reading, waits for the
// voice server's answer (1.5 s at most, post() alone was fire-and-forget), takes ▶ ■ SUB out of the menu bar and quits.
func stopAndExit() {
    var done = false
    let finish = { DispatchQueue.main.async {
        if done { return }; done = true
        MenuControls.shared.removeAll()
        NSApp.terminate(nil)
    } }
    var r = URLRequest(url: URL(string: VOICE_URL + "/speak/stop")!, timeoutInterval: 1.5)
    r.httpMethod = "POST"; r.httpBody = Data("{\"clear\": true}".utf8); r.setValue("application/json", forHTTPHeaderField: "Content-Type")   // v43: STOP ends the reading and the queue
    URLSession.shared.dataTask(with: r) { _, _, _ in finish() }.resume()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { finish() }
}

func subLog(_ m: String) {
    let f = NSString(string: "~/.voice_engine/subtitle.log").expandingTildeInPath
    let line = ISO8601DateFormatter().string(from: Date()) + " " + m + "\n"
    if let h = FileHandle(forWritingAtPath: f) { h.seekToEndOfFile(); h.write(Data(line.utf8)); try? h.close() }
    else { try? FileManager.default.createDirectory(atPath: (f as NSString).deletingLastPathComponent, withIntermediateDirectories: true); try? line.write(toFile: f, atomically: true, encoding: .utf8) }
}

func post(_ path: String) {
    var r = URLRequest(url: URL(string: VOICE_URL + path)!)
    r.httpMethod = "POST"; r.httpBody = Data("{}".utf8); r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    URLSession.shared.dataTask(with: r).resume()
}

// MARK: one screen's subtitle: a borderless panel across the screen, above full-screen apps, never taking the focus

final class KeyLabel: NSView {
    let text: String; let size: CGFloat; let action: () -> Void
    var row = 0
    var slot: CGFloat = 0        // v42: x inside the keys' group
    var display: String?         // v42: the speed's text (1.0x), the name stays SPEED
    var symbol: String?          // v29: an SF Symbol (Apple's symbol font) instead of the word; the word stays its name
    init(_ text: String, _ size: CGFloat, _ frame: NSRect, symbol: String? = nil, _ action: @escaping () -> Void) {
        self.text = text; self.size = size; self.action = action; self.symbol = symbol; super.init(frame: frame)
        toolTip = text.capitalized
        setAccessibilityElement(true); setAccessibilityRole(.button); setAccessibilityLabel(text.capitalized)
        setAccessibilityIdentifier("subtitle-" + text.lowercased())
    }
    /// v38: PAUSE turns into CONTINUE (and back): word, symbol, tooltip and AX label follow
    func rename(_ t: String, _ sym: String) {
        symbol = sym; toolTip = t.capitalized; setAccessibilityLabel(t.capitalized); needsDisplay = true
    }
    override func accessibilityPerformPress() -> Bool { action(); return true }
    required init?(coder: NSCoder) { fatalError() }
    override func acceptsFirstMouse(for e: NSEvent?) -> Bool { true }
    override func mouseDown(with e: NSEvent) {}
    override func mouseUp(with e: NSEvent) { action() }
    override func draw(_ r: NSRect) {
        // v43 (Marko, 13.11.2026: "exactly the same for the controls as for the subtitles. They need to have hard shadow"):
        // the subtitle's rules: its colour, its font, a hard black shadow, no blur, down and right by 7 % of the glyph (>= 2 pt).
        // This view is not flipped: down is minus y.
        let conf = SubtitleEngine.shared.conf
        let col = nscolour(conf.colour) ?? NSColor(white: 0.92, alpha: 1)
        let off = max(2, round(size * 0.07))
        if let name = symbol, let base = NSImage(systemSymbolName: name, accessibilityDescription: text) {
            func img(_ c: NSColor) -> NSImage {
                let cfg = NSImage.SymbolConfiguration(pointSize: size, weight: conf.bold ? .bold : .regular).applying(.init(paletteColors: [c]))
                return base.withSymbolConfiguration(cfg) ?? base
            }
            let sz = img(col).size
            let x = (bounds.width - sz.width) / 2, y = (bounds.height - sz.height) / 2
            img(.black).draw(in: NSRect(x: x + off, y: y - off, width: sz.width, height: sz.height))
            img(col).draw(in: NSRect(x: x, y: y, width: sz.width, height: sz.height))
            return
        }
        let p = NSMutableParagraphStyle(); p.alignment = .center
        let font = NSFont(name: conf.bold ? FONT + " Bold" : FONT, size: size) ?? .systemFont(ofSize: size)
        let h = size * 1.3
        let rect = NSRect(x: 0, y: (bounds.height - h) / 2, width: bounds.width, height: h)
        let shadowed = (display ?? text) as NSString
        shadowed.draw(in: rect.offsetBy(dx: off, dy: -off), withAttributes: [.font: font, .foregroundColor: NSColor.black, .paragraphStyle: p])
        shadowed.draw(in: rect, withAttributes: [.font: font, .foregroundColor: col, .paragraphStyle: p])
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
        // v29 (Marko, 4.11.2026: "Hide hides the subtitle, so I don't need to reach for the menu bar. Stop stops the talking
        // completely ... These two controls I need on the right side. All other controls can just disappear ... They can
        // also be symbolic"): two SF Symbols on the right. HIDE (captions crossed out): the subtitle goes, the voice reads
        // on (the menu bar's SUB brings subtitles back). STOP (a square): the reading ends completely.
        // v38 (Marko, 8.11.2026: "There is a stop, there is a hide, but there is no pause to continue later"): PAUSE first
        // (POST /speak/pause holds the voice at the word being said; the same button then reads CONTINUE).
        // v42 (Marko, 13.11.2026: "more action buttons ... arrows to speed up or slow down reading ... simple skip buttons,
        // like in any player ... the last sentence, then the next thing in queue is playing"): one group in player order,
        // mouse only: previous sentence, PAUSE, next sentence (on the last one: the next reading in the queue), skip to the
        // next reading, speed - / speed / speed +, then HIDE and STOP.
        // v43 (Marko, 13.11.2026: "center them and make controls in multiple lines, in three lines"): three centred rows under
        // the text: playback / speed / HIDE STOP. (name, symbol, row, x in the row, width, action)
        let right: [(String, String?, Int, CGFloat, CGFloat, () -> Void)] = [
            ("PREVIOUS", "backward.end.fill", 0, 0, 56, { post("/speak/previous") }),
            ("PAUSE", "pause.fill", 0, 56, 56, { [weak engine] in engine?.togglePause() }),
            ("NEXT", "forward.end.fill", 0, 112, 56, { post("/speak/next") }),
            ("SKIP", "forward.fill", 0, 168, 56, { post("/speak/skip") }),
            ("SLOWER", "minus.circle", 1, 0, 44, { [weak engine] in engine?.nudgeSpeed(-0.1) }),
            ("SPEED", nil, 1, 44, 64, {}),
            ("FASTER", "plus.circle", 1, 108, 44, { [weak engine] in engine?.nudgeSpeed(0.1) }),
            ("HIDE", "captions.bubble.fill", 2, 0, 56, { [weak engine] in engine?.hide() }   // v43: HIDE only hides; /speak/close ended the reading (found by the click test)),
            ("STOP", "stop.fill", 2, 56, 56, { [weak engine] in engine?.hide(); stopAndExit() })]
        for (t, sym, row, x, w, f) in right {
            let k = KeyLabel(t, sym == nil ? 24 : 26, NSRect(x: x, y: 0, width: w, height: 48), symbol: sym, f)
            k.slot = x; k.row = row
            if t == "SPEED" { k.display = "1.0x" }
            band.addSubview(k)
        }
    }
    var keyViews: [KeyLabel] { band.subviews.compactMap { $0 as? KeyLabel } }

    // how tall the band must be for this text on this screen: the lines it wraps to, at the subtitle's size
    func layout(_ c: SubtitleSettings, _ text: String) {
        let vf = screen.visibleFrame
        size = max(14, floor(vf.height * CGFloat(c.size) / 100))
        let room = max(260, floor(vf.width * CGFloat(c.column) / 100))   // v43: the column, centred on the screen
        let pw = room + 48                  // the band: the column plus 24 each side
        let font = NSFont(name: c.bold ? FONT + " Bold" : FONT, size: size) ?? .systemFont(ofSize: size)
        let wide = (text as NSString).size(withAttributes: [.font: font]).width
        _ = wide; let lines: CGFloat = 2            // v43: at most four words at a time: the band is two lines high, never jumping
        let kh: CGFloat = ROWH * 3 + 8    // v43: three rows of keys under the text
        let h = max(floor(lines * size * 1.22 + size * 0.7 + kh), 110 + kh)
        var y = vf.minY + floor((vf.height - h) / 2)                  // Cocoa's y grows upward
        if c.position == "bottom" { y = vf.minY } else if c.position == "top" { y = vf.maxY - h }
        if c.ypos >= 0 { y = ScreenSub.clampY(vf.minY + CGFloat(c.ypos) * vf.height - h / 2, h, vf) }   // v18: dragged
        panel.setFrame(NSRect(x: vf.minX + floor((vf.width - pw) / 2), y: y, width: pw, height: h), display: false)
        let main = NSScreen.screens.first.map { $0 == screen } ?? false
        let alpha = (!c.bandmain && main) ? 0 : CGFloat(c.band) / 100
        band.fill = NSColor(white: CGFloat(c.grey) / 100, alpha: alpha)
        band.textRect = NSRect(x: 24, y: max(4, (h - kh - lines * size * 1.22) / 2 - size * 0.08), width: room, height: h)
        let keys = keyViews
        for k in keys { k.frame.origin.y = h - kh + CGFloat(k.row) * ROWH + 2 }                  // x: SubtitleEngine.placeKeys
    }
    /// v43: the chunk's lines (1 or 2) put in the middle of the band's text part
    func place(_ chunk: String, _ c: SubtitleSettings) {
        let font = NSFont(name: c.bold ? FONT + " Bold" : FONT, size: size) ?? .systemFont(ofSize: size)
        let wide = (chunk as NSString).size(withAttributes: [.font: font]).width
        let room = band.textRect.width
        let n = max(1, min(2, ceil(wide / (room * 0.92))))
        let h = panel.frame.height, kh = ROWH * 3 + 8
        band.textRect.origin.y = max(4, (h - kh - n * size * 1.22) / 2 - size * 0.08)
    }
    static func clampY(_ y: CGFloat, _ h: CGFloat, _ vf: NSRect) -> CGFloat { min(max(y, vf.minY), vf.maxY - h) }
    /// v18: the band moved so its centre is at this fraction of the screen's height (0 bottom, 1 top), height kept
    func moveTo(fraction f: CGFloat) {
        let vf = screen.visibleFrame, h = panel.frame.height
        panel.setFrameOrigin(NSPoint(x: panel.frame.minX, y: ScreenSub.clampY(vf.minY + f * vf.height - h / 2, h, vf)))
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
    var chunkOf: [Int] = []; var chunkRanges: [(Int, Int)] = []; var chunkIdx = 0   // v43: at most 4 words at a time
    var testTimer: Timer?; var lingerTimer: Timer?; var tick: Timer?
    var following = false; var polling = false
    var pollSince = Date()   // v23 (2.11.2026): a poll that never answered left `polling` true for ever: no blob, no subtitle, no ✕
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
        // v41 (Marko, 13.11.2026: "I am pressing subtitles ten fifty times. And nothing's happening"): after sleep, wake or a
        // Space change the window server can keep cached panels off screen for good; rebuild them while a reading is on.
        let ws = NSWorkspace.shared.notificationCenter
        for n in [NSWorkspace.didWakeNotification, NSWorkspace.screensDidWakeNotification, NSWorkspace.activeSpaceDidChangeNotification] {
            ws.addObserver(forName: n, object: nil, queue: .main) { [weak self] note in
                guard let self = self, self.following || !self.subs.isEmpty else { return }
                subLog("rebuild on " + note.name.rawValue)
                self.rebuild()
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in self?.pollOnce() }
    }

    // the right keys are laid at the screen's right edge, the left ones at its left
    func placeKeys(_ s: ScreenSub) {
        let w = s.panel.frame.width, keys = s.keyViews
        for k in keys { k.frame.origin.x = floor((w - ROWW[k.row]) / 2) + k.slot }
    }

    func open() {
        conf = SubtitleSettings.load()
        guard conf.subtitles else { return }                    // v10: the blob's CC turns the subtitle off
        if !subs.isEmpty {                                      // v41: panels kept from before: order them front again, check them
            subs.forEach { $0.show() }; verifyShown(retry: true); return
        }
        subs = NSScreen.screens.map { ScreenSub($0, self) }
        subs.forEach { $0.show() }
        verifyShown(retry: true)
    }
    /// v41: drop and recreate the panels, put the sentence back
    func rebuild() {
        drop(); open()
        if !subs.isEmpty { show(text, words) }
    }
    /// v41: within 0.5 s every panel must be on screen (the window server says so); if not, rebuild once and log it
    func verifyShown(retry: Bool) {
        let wanted = subs.map { $0.panel.windowNumber }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, !self.subs.isEmpty, self.conf.subtitles else { return }
            if self.subs.map({ $0.panel.windowNumber }) != wanted { return }      // already rebuilt by someone else
            let info = (CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]]) ?? []
            let on = Set(info.compactMap { $0[kCGWindowNumber as String] as? Int })
            let bad = self.subs.filter { !on.contains($0.panel.windowNumber) }
            if bad.isEmpty { return }
            subLog("panels not on screen (\(bad.count) of \(self.subs.count)); " + (retry ? "recreating" : "giving up"))
            if retry {
                self.drop(); self.subs = NSScreen.screens.map { ScreenSub($0, self) }
                self.show(self.text, self.words)
                self.subs.forEach { $0.show() }
                self.verifyShown(retry: false)
            }
        }
    }
    func drop() { subs.forEach { $0.close() }; subs = [] }
    // v10, the blob's CC: on, the subtitle comes back at once with the sentence being said; off, it goes and stays gone
    func setSubtitles(_ on: Bool) {
        var c = SubtitleSettings.load(); c.subtitles = on; c.save(); conf = c
        if on { bringBack() } else { drop() }          // v18: on brings it back at once, following or not
    }

    /// v43 (Marko, 13.11.2026: "maximum 4 words at one time on the screen. That's it."): the sentence in chunks of at most four
    /// words, broken at punctuation first, each clause split evenly (5 = 3+2, never one word stranded when 2+2 fits).
    func makeChunks() {
        chunkOf = []; chunkRanges = []
        guard !words.isEmpty else { return }
        let sc = Array(text.unicodeScalars)
        var clauses: [[Int]] = [[]]
        for (i, w) in words.enumerated() {
            clauses[clauses.count - 1].append(i)
            if let e = w.e, e > 0, e <= sc.count, ",;:.!?—–".unicodeScalars.contains(sc[e - 1]) { clauses.append([]) }
        }
        // phrase boundaries (research, 13.11.2026): never break after an article, preposition or conjunction ("the | drum",
        // "on | the chair"); a natural 2-4 word phrase is preferred; the cost is minimal for few, balanced chunks.
        let binders: Set<String> = ["a", "an", "the", "of", "to", "in", "on", "at", "for", "with", "by", "from", "as", "into", "onto",
                                    "and", "or", "but", "that", "than", "if", "my", "your", "his", "her", "its", "our", "their", "this",
                                    "these", "those", "is", "are", "was", "be", "not", "no", "so", "about", "over", "under", "through"]
        func binder(_ i: Int) -> Bool {
            guard let st = words[i].s, let en = words[i].e, st >= 0, en <= sc.count, st < en else { return false }
            let w = String(String.UnicodeScalarView(sc[st..<en])).lowercased().trimmingCharacters(in: .punctuationCharacters)
            return binders.contains(w)
        }
        for cl in clauses where !cl.isEmpty {
            let n = cl.count
            var best = [Double](repeating: 1e9, count: n + 1), from = [Int](repeating: 0, count: n + 1)
            best[0] = 0
            if n >= 1 { for e in 1...n {
                for L in 1...min(4, e) {
                    let st = e - L
                    guard best[st] < 1e9 else { continue }
                    var c = 10.0 + Double(4 - L) * 0.6 + (L == 1 && n > 1 ? 12 : 0)
                    if e < n, binder(cl[e - 1]) { c += 30 }                   // a break after an article or preposition
                    if best[st] + c < best[e] { best[e] = best[st] + c; from[e] = st }
                }
            } }
            var cuts: [(Int, Int)] = []; var e = n
            while e > 0 { let st = from[e]; cuts.append((cl[st], cl[e - 1])); e = st }
            chunkRanges.append(contentsOf: cuts.reversed())
        }
        // a stranded single word joins its neighbour when that stays within four
        var j = 0
        while j < chunkRanges.count {
            let (a, b) = chunkRanges[j]
            if a == b, chunkRanges.count > 1 {
                if j > 0, chunkRanges[j - 1].1 - chunkRanges[j - 1].0 + 1 + 1 <= 4 { chunkRanges[j - 1].1 = b; chunkRanges.remove(at: j); continue }
                if j + 1 < chunkRanges.count, chunkRanges[j + 1].1 - chunkRanges[j + 1].0 + 1 + 1 <= 4 { chunkRanges[j + 1].0 = a; chunkRanges.remove(at: j); continue }
            }
            j += 1
        }
        chunkOf = Array(repeating: 0, count: words.count)
        for (ci, r) in chunkRanges.enumerated() { for i in r.0...r.1 { chunkOf[i] = ci } }
    }
    func styled(_ s: ScreenSub, _ k: Int) -> NSAttributedString {
        let font = NSFont(name: conf.bold ? FONT + " Bold" : FONT, size: s.size) ?? .systemFont(ofSize: s.size)
        let p = NSMutableParagraphStyle(); p.alignment = .center; p.lineBreakMode = .byWordWrapping
        let col = nscolour(conf.colour) ?? nscolour("#E8A33D")!
        // v37 (Marko, 8.11.2026: "they don't have shadow. So if something is in the background I don't see make a hard
        // shadow"): a hard black shadow, no blur, offset down and right by 7 % of the letter size (at least 2 pt).
        // NSShadow's offset is in screen space (not flipped with the view): a negative height moves it down.
        let sh = NSShadow(); sh.shadowColor = NSColor.black; sh.shadowBlurRadius = 0
        let off = max(2, round(s.size * 0.07)); sh.shadowOffset = NSSize(width: off, height: -off)
        // v43: only the chunk holding the word being said (the first chunk before the first word, the last one stays at the end)
        let scalars = Array(text.unicodeScalars)
        var base = 0, shown = text
        if !chunkRanges.isEmpty {
            if k >= 0, k < chunkOf.count { chunkIdx = chunkOf[k] }
            chunkIdx = min(max(chunkIdx, 0), chunkRanges.count - 1)
            let r = chunkRanges[chunkIdx]
            if let a = words[r.0].s, let b = words[r.1].e, a >= 0, b <= scalars.count, a < b {
                base = a; shown = String(String.UnicodeScalarView(scalars[a..<b]))
            }
        }
        s.place(shown, conf)
        let a = NSMutableAttributedString(string: shown, attributes: [.font: font, .foregroundColor: col, .paragraphStyle: p, .shadow: sh])
        if k >= 0, k < words.count, let st = words[k].s, let en = words[k].e {
            // the server counts characters (code points), NSString counts UTF-16: convert
            if st >= base, en <= base + shown.unicodeScalars.count, st < en {
                let sc2 = Array(shown.unicodeScalars)
                let pre = String(String.UnicodeScalarView(sc2[0..<(st - base)])).utf16.count
                let len = String(String.UnicodeScalarView(sc2[(st - base)..<(en - base)])).utf16.count
                var at: [NSAttributedString.Key: Any] = [.foregroundColor: nscolour(conf.word) ?? nscolour("#FF3B30")!]
                if let bg = nscolour(conf.wordbg, 0.9) { at[.backgroundColor] = bg }
                a.addAttributes(at, range: NSRange(location: pre, length: len))
            }
        }
        return a
    }
    func paint(_ k: Int) { for s in subs { s.band.text = styled(s, k); s.band.needsDisplay = true } }
    func show(_ t: String, _ ws: [SubWord]) {
        text = t; words = ws; lit = -2; chunkIdx = 0
        makeChunks()
        conf = SubtitleSettings.load()                 // the settings window's changes, live
        for s in subs { s.layout(conf, t); placeKeys(s) }
        paintPause(); paintSpeed()
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
        if polling && Date().timeIntervalSince(pollSince) < 3 { return }
        if !following { idleCount += 1; if idleCount < 5 { return } }
        idleCount = 0
        var r = URLRequest(url: URL(string: VOICE_URL + "/speaking")!); r.timeoutInterval = 1
        polling = true; pollSince = Date()
        URLSession.shared.dataTask(with: r) { d, _, _ in
            let st = d.flatMap { try? JSONDecoder().decode(Speaking.self, from: $0) }
            DispatchQueue.main.async { self.polling = false; if let st = st { self.heard(st) } }
        }.resume()
    }
    var pause = PauseSync()          // v39: the rule lives in VOICE_ENGINE_UNIVERSAL (SPEC.md §3), shared with the phones
    var paused: Bool { pause.paused }
    func togglePause() {
        _ = pause.press()
        paintPause()
        playing = playing && !paused; wall = Date().timeIntervalSince1970
        let q = pause.request
        var r = URLRequest(url: URL(string: VOICE_URL + q.path)!, timeoutInterval: 1.5)
        r.httpMethod = "POST"; r.httpBody = Data(q.body.utf8)
        r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        URLSession.shared.dataTask(with: r).resume()
    }
    var speed = 1.0
    func nudgeSpeed(_ d: Double) {
        speed = max(0.8, min(1.6, (((speed + d) * 10).rounded()) / 10))
        paintSpeed()
        postJSON("/speak/rate", "{\"rate\": \(speed)}")
    }
    func paintSpeed() {
        for s in subs { for k in s.keyViews where k.text == "SPEED" { k.display = String(format: "%.1fx", speed); k.needsDisplay = true } }
    }
    func paintPause() {
        for s in subs { for k in s.keyViews where k.text == "PAUSE" { k.rename(pause.label, pause.symbol) } }
    }
    func heard(_ st: Speaking) {
        if pause.sync(st.paused ?? false) { paintPause() }
        if let sp = st.speed, abs(sp - speed) > 0.01 { speed = sp; paintSpeed() }
        MenuControls.shared.heard(st)       // v24: ▶ ■ in the menu bar instead of the blob (Marko 2.11.2026)
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
        if paused { playing = false; return }      // v38: paused, the lit word stands still (the clock does not run on)
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
