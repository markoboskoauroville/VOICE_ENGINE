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

    private func symbol(_ name: String, _ desc: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: desc)
        img?.isTemplate = true
        return img
    }

    private func make() {
        if stopItem != nil { return }
        // Marko 2.11.2026: "The order is triangle, square, and then sub." The newest item stands left, so they are made
        // right to left: SUB, then ■, then ▶ -> on screen ▶ ■ SUB.
        // v25 (Marko 2.11.2026: "a third button which looks like a subtitle ... put 'Sub', and when I click 'Sub', I can
        // see subtitles. But by default, you are not showing me subtitles."): SUB in a rounded box, orange while on
        let u = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        u.button?.target = self; u.button?.action = #selector(sub)
        u.button?.setAccessibilityLabel("SUB")
        let s = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        s.button?.image = symbol("stop.fill", "STOP")
        s.button?.toolTip = "Stop the reading completely"
        s.button?.target = self; s.button?.action = #selector(stop)
        s.button?.setAccessibilityLabel("STOP")
        let p = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        p.button?.image = symbol("play.fill", "PAUSE")
        p.button?.target = self; p.button?.action = #selector(play)
        p.button?.setAccessibilityLabel("PAUSE")
        stopItem = s; playItem = p; subItem = u
        paint()
    }

    private func remove() {
        if let s = stopItem { NSStatusBar.system.removeStatusItem(s) }
        if let p = playItem { NSStatusBar.system.removeStatusItem(p) }
        if let u = subItem { NSStatusBar.system.removeStatusItem(u) }
        stopItem = nil; playItem = nil; subItem = nil
    }

    private func subImage(_ on: Bool) -> NSImage {
        let font = NSFont.systemFont(ofSize: 10, weight: .bold)
        let txt = NSAttributedString(string: "SUB", attributes: [.font: font, .foregroundColor: NSColor.black])
        let sz = NSSize(width: ceil(txt.size().width) + 8, height: 15)
        let img = NSImage(size: sz, flipped: false) { r in
            let box = NSBezierPath(roundedRect: r.insetBy(dx: 0.5, dy: 0.5), xRadius: 3, yRadius: 3)
            NSColor.black.setStroke(); box.lineWidth = 1
            if on { NSColor.black.setFill(); box.fill() } else { box.stroke() }
            let t = NSAttributedString(string: "SUB", attributes: [.font: font,
                         .foregroundColor: on ? NSColor.clear : NSColor.black])
            if on {   // the word cut out of the filled box
                NSGraphicsContext.current?.compositingOperation = .destinationOut
            }
            t.draw(at: NSPoint(x: 4, y: (r.height - t.size().height) / 2))
            return true
        }
        img.isTemplate = !on
        return img
    }

    private func paint() {
        if let ub = subItem?.button {
            let on = SubtitleEngine.shared.conf.subtitles
            ub.image = subImage(on)
            ub.contentTintColor = on ? NSColor.systemOrange : nil
            ub.toolTip = on ? "Subtitles on. Click: off" : "Subtitles off. Click: on"
        }
        guard let b = playItem?.button else { return }
        let orange = paused || !held.isEmpty
        b.contentTintColor = orange ? NSColor.systemOrange : nil
        b.toolTip = !held.isEmpty ? "Held: \(held). Click: read anyway"
                  : paused ? "Paused. Click: play on" : "Playing. Click: pause"
        b.setAccessibilityLabel(!held.isEmpty ? "READ ANYWAY" : paused ? "PLAY" : "PAUSE")
    }

    // every answer of GET /speaking (SubtitleEngine's poll)
    func heard(_ st: Speaking) {
        if st.on || !(st.held ?? "").isEmpty {
            quiet = 0
            paused = st.paused ?? false
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
        paused.toggle()
        postJSON("/speak/pause", paused ? "{\"paused\": true}" : "{\"paused\": false}")
        paint()
    }
}
