import AppKit

// v24 (2.11.2026), Marko: "Let's forget the blob. Make a triangle when you are playing at the menu bar and then I can just
// stop you ... two buttons, one is square to stop completely and the triangle to pause."
// While the voice reads (GET /speaking on), two items stand in the menu bar: ■ stops the reading completely
// (POST /speak/stop), ▶ pauses it and plays it on (POST /speak/pause); paused, the triangle is orange. When the engine
// holds a reading (Voice to Text recording him), the triangle is orange too and its click is READ ANYWAY
// (POST /micguard/skip). Both go a moment after the reading ends. The blob no longer shows.
final class MenuControls: NSObject {
    static let shared = MenuControls()
    var stopItem: NSStatusItem?, playItem: NSStatusItem?, subItem: NSStatusItem?
    var paused = false, held = "", quiet = 0
    var clickedAt = Date.distantPast      // v30: a click wins over the next poll for 1.5 s (no flicker back)

    private func symbol(_ name: String, _ desc: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: desc)
        img?.isTemplate = true
        return img
    }

    // v28 (Marko, 4.11.2026: "I want to switch it on/off like a display switch: Subtitles on/off, and the icon is always
    // there"): SUB stands in the menu bar from the engine's start until it quits, never removed; a click switches the
    // subtitles on (filled, orange) or off (outlined). Only ▶ ■ come and go with the reading, to the left of SUB.
    func startSub() {
        if subItem != nil { return }
        let u = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        u.autosaveName = "VoiceEngineSUB"
        u.isVisible = true
        u.button?.target = self; u.button?.action = #selector(sub)
        u.button?.setAccessibilityLabel("SUB")
        u.button?.setAccessibilityIdentifier("sub")
        subItem = u
        paint()
    }

    private func make() {
        if stopItem != nil { return }
        startSub()
        // Marko 2.11.2026: "The order is triangle, square, and then sub." The newest item stands left: ■ then ▶ -> ▶ ■ SUB
        let s = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        s.button?.image = symbol("stop.fill", "STOP")
        s.button?.toolTip = "Stop the reading completely"
        s.button?.target = self; s.button?.action = #selector(stop)
        s.button?.setAccessibilityLabel("STOP")
        let p = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        p.button?.image = symbol("pause.fill", "PAUSE")
        p.button?.target = self; p.button?.action = #selector(play)
        p.button?.setAccessibilityLabel("PAUSE")
        stopItem = s; playItem = p
        paint()
    }

    private func remove() {
        if let s = stopItem { NSStatusBar.system.removeStatusItem(s) }
        if let p = playItem { NSStatusBar.system.removeStatusItem(p) }
        stopItem = nil; playItem = nil          // SUB stays (v28)
    }

    // v30: quitting the engine takes every item out, SUB too (it stays only while the engine runs)
    func removeAll() {
        remove()
        if let u = subItem { NSStatusBar.system.removeStatusItem(u) }
        subItem = nil
    }

    // v28: drawn in real colours. Until v27 "on" was a BLACK filled box (not a template, so the system did not tint it):
    // on the dark menu bar it vanished, the bug Marko saw ("If I press Subtitle, then this icon ... disappears").
    // ON = an orange box with the word cut out; OFF = a template outline (white on a dark bar, black on a light one).
    private func subImage(_ on: Bool) -> NSImage {
        let font = NSFont.systemFont(ofSize: 10, weight: .bold)
        let txt = NSAttributedString(string: "SUB", attributes: [.font: font])
        let sz = NSSize(width: ceil(txt.size().width) + 8, height: 15)
        let img = NSImage(size: sz, flipped: false) { r in
            let box = NSBezierPath(roundedRect: r.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
            if on { NSColor.systemOrange.setFill(); box.fill() } else { NSColor.black.setStroke(); box.lineWidth = 1; box.stroke() }
            let t = NSAttributedString(string: "SUB", attributes: [.font: font, .foregroundColor: NSColor.black])
            if on { NSGraphicsContext.current?.compositingOperation = .destinationOut }   // the word cut out of the orange
            t.draw(at: NSPoint(x: 4, y: (r.height - t.size().height) / 2))
            return true
        }
        img.isTemplate = !on
        return img
    }

    // v30 (Marko, 4.11.2026: "I'm missing the pause button ... play/pause must be a toggle"): one button, two faces.
    // Playing: ⏸ (white, template); a click pauses. Paused or held: ▶ in orange; a click plays on (or reads anyway).
    private func playImage(_ orange: Bool) -> NSImage? {
        guard orange else { return symbol("pause.fill", "PAUSE") }
        let cfg = NSImage.SymbolConfiguration(paletteColors: [NSColor.systemOrange])
        let img = NSImage(systemSymbolName: "play.fill", accessibilityDescription: "PLAY")?.withSymbolConfiguration(cfg)
        img?.isTemplate = false
        return img
    }

    private func paint() {
        if let ub = subItem?.button {
            let on = SubtitleEngine.shared.conf.subtitles
            ub.image = subImage(on)
            ub.contentTintColor = nil
            ub.toolTip = on ? "Subtitles ON. Click: off" : "Subtitles OFF. Click: on"
            ub.setAccessibilityValue(on ? "on" : "off")
        }
        guard let b = playItem?.button else { return }
        let orange = paused || !held.isEmpty
        b.image = playImage(orange); b.contentTintColor = nil
        b.toolTip = !held.isEmpty ? "Held: \(held). Click: read anyway"
                  : paused ? "Paused. Click: play on" : "Playing. Click: pause"
        b.setAccessibilityLabel(!held.isEmpty ? "READ ANYWAY" : paused ? "PLAY" : "PAUSE")
    }

    // every answer of GET /speaking (SubtitleEngine's poll)
    func heard(_ st: Speaking) {
        startSub()
        if st.on || !(st.held ?? "").isEmpty {
            quiet = 0
            if Date().timeIntervalSince(clickedAt) > 1.5 { paused = st.paused ?? false }
            held = st.held ?? ""
            make(); paint()
        } else if stopItem != nil {
            quiet += 1
            if quiet >= 3 { remove() }
        }
    }

    @objc func stop() {
        post("/speak/stop")
        SubtitleEngine.shared.hide()
        remove()
    }

    @objc func sub() {
        let e = SubtitleEngine.shared
        e.setSubtitles(!e.conf.subtitles)
        paint()
    }

    @objc func play() {
        if !held.isEmpty { postJSON("/micguard/skip", "{}"); held = ""; paint(); return }
        paused.toggle(); clickedAt = Date()
        postJSON("/speak/pause", paused ? "{\"paused\": true}" : "{\"paused\": false}")
        paint()
    }
}
