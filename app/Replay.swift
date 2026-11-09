import AppKit

// v40 (9.11.2026), Marko: "After the voice is played, you keep the player in my menu bar and then I can replay the
// message. If I press stop on a message which is not playing, then this menu bar player disappears."
// MANTRA_VOICE's voiced.py writes every finished reading to ~/.voice_engine/last/<id>.json (text, clips with file, lang,
// words; the audio is copied beside it, newest three kept). While nothing is read and a record is there, two menu-bar
// items stand: REPLAY (play; stop while it plays) and STOP (stops a replay; pressed while nothing plays, the player
// is dismissed until the next message). A replay is POST /speak with the saved clips, so the subtitles run again.
// The items never take focus; a new reading takes them away and brings them back when it has ended.
final class ReplayPlayer: NSObject {
    static let shared = ReplayPlayer()
    let dir = NSString(string: "~/.voice_engine/last").expandingTildeInPath
    var playItem: NSStatusItem?, stopItem: NSStatusItem?
    var replaying = false, startedAt = Date.distantPast
    var record: [String: Any]?

    private func newest() -> [String: Any]? {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: dir) else { return nil }
        var best: (Date, String)?
        for n in names where n.hasSuffix(".json") {
            let p = dir + "/" + n
            if let d = (try? fm.attributesOfItem(atPath: p))?[.modificationDate] as? Date, best == nil || d > best!.0 { best = (d, p) }
        }
        guard let b = best, let data = fm.contents(atPath: b.1),
              let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return o
    }
    private func clips(_ r: [String: Any]) -> [[String: Any]] { (r["clips"] as? [[String: Any]]) ?? [] }
    private func ts(_ r: [String: Any]) -> Double { (r["ts"] as? Double) ?? 0 }
    private func dismissedTs() -> Double {
        Double((try? String(contentsOfFile: dir + "/dismissed.txt", encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "") ?? 0
    }
    private func available(_ r: [String: Any]) -> Bool {
        let c = clips(r)
        return !c.isEmpty && c.allSatisfy { FileManager.default.fileExists(atPath: ($0["file"] as? String) ?? "") }
    }

    // every answer of GET /speaking, through MenuControls.heard
    func tick(_ st: Speaking) {
        if st.on || !(st.held ?? "").isEmpty {
            if replaying && st.on { record = record ?? newest(); show(); return }
            remove(); return                       // a new message is being read: its own ▶ ■ SUB stand
        }
        if replaying && Date().timeIntervalSince(startedAt) > 2 { replaying = false }
        if replaying { show(); return }
        if let r = newest(), ts(r) > dismissedTs() { record = r; show() } else { record = nil; remove() }
    }

    private func symbol(_ name: String, _ desc: String) -> NSImage? {
        let img = NSImage(systemSymbolName: name, accessibilityDescription: desc); img?.isTemplate = true; return img
    }

    private func show() {
        if playItem == nil {
            // newest item stands left: STOP made first, then REPLAY to its left
            let s = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            s.button?.target = self; s.button?.action = #selector(stopPressed)
            s.button?.setAccessibilityIdentifier("replay-stop"); s.button?.setAccessibilityLabel("STOP REPLAY")
            let p = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            p.button?.target = self; p.button?.action = #selector(playPressed)
            p.button?.setAccessibilityIdentifier("replay-play")
            stopItem = s; playItem = p
        }
        let ok = record.map(available) ?? false
        if let s = stopItem?.button {
            s.image = symbol("stop.fill", "STOP")
            s.toolTip = replaying ? "Stop the replay" : "Close the player"
        }
        if let b = playItem?.button {
            b.image = symbol(replaying ? "stop.circle.fill" : "play.circle", replaying ? "STOP" : "REPLAY")
            b.isEnabled = ok || replaying
            b.setAccessibilityLabel(replaying ? "STOP" : "REPLAY")
            b.setAccessibilityValue(replaying ? "playing" : (ok ? "ready" : "missing"))
            b.toolTip = replaying ? "Playing. Click: stop"
                      : ok ? "Replay the last message: \(((record?["text"] as? String) ?? "").prefix(80))"
                      : "The audio of the last message is gone"
        }
    }

    func remove() {
        if let s = stopItem { NSStatusBar.system.removeStatusItem(s) }
        if let p = playItem { NSStatusBar.system.removeStatusItem(p) }
        stopItem = nil; playItem = nil
    }

    @objc func playPressed() {
        if replaying { stopReplay(); return }
        guard let r = record ?? newest(), available(r) else { show(); return }
        let cl = clips(r).map { ["text": $0["text"] ?? "", "file": $0["file"] ?? "", "lang": $0["lang"] ?? "en"] }
        guard let body = try? JSONSerialization.data(withJSONObject: ["clips": cl]) else { return }
        var q = URLRequest(url: URL(string: VOICE_URL + "/speak")!, timeoutInterval: 5)
        q.httpMethod = "POST"; q.httpBody = body; q.setValue("application/json", forHTTPHeaderField: "Content-Type")
        replaying = true; startedAt = Date(); show()
        URLSession.shared.dataTask(with: q) { _, resp, err in
            if err != nil { DispatchQueue.main.async { self.replaying = false; self.show() } }
        }.resume()
    }

    func stopReplay() {
        post("/speak/stop")
        replaying = false; show()
    }

    // STOP: while a replay plays it stops it; with nothing playing the player goes until the next message
    @objc func stopPressed() {
        if replaying { stopReplay(); return }
        if let r = record ?? newest() { try? String(ts(r)).write(toFile: dir + "/dismissed.txt", atomically: true, encoding: .utf8) }
        record = nil; remove()
    }

    func removeAll() { remove() }
}
