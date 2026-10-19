// ANSWER CLAUDE: the box a click on the subtitle opens (MANTRA_STAR apps/voice.lua).
// Marko, 3.10.2026: "when I click on it ... open the text input window when I'm going to answer you, and then when I
// send the answer you're receiving it right here in this chat ... if I send an empty message it means I will just
// close the thing." Plain AppKit, its own small app: the SwiftUI scene of v4/v5 never opened a window on launch
// (the process ran, nothing was seen). Enter sends (the words to ~/.voice/replies/<time>.txt, which the Claude Code
// session watches); Shift+Enter is a new line; Escape or an empty Enter closes. Either way the subtitle closes and
// the reading's wave files go (POST /speak/close).
import AppKit

let REPLIES = NSHomeDirectory() + "/.voice/replies"
let said: String = {
    let a = CommandLine.arguments
    if let i = a.firstIndex(of: "--said"), i + 1 < a.count { return a[i + 1] }
    return ""
}()
let AMBER = NSColor(calibratedRed: 0.91, green: 0.64, blue: 0.24, alpha: 1)
let SAND = NSColor(calibratedRed: 0.95, green: 0.87, blue: 0.71, alpha: 1)
let GREY = NSColor(calibratedRed: 0.48, green: 0.50, blue: 0.53, alpha: 1)

func closeSubtitle() {
    var r = URLRequest(url: URL(string: "http://127.0.0.1:8837/speak/close")!)
    r.httpMethod = "POST"; r.httpBody = Data("{}".utf8); r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let done = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: r) { _, _, _ in done.signal() }.resume()
    _ = done.wait(timeout: .now() + 2)
    // v8: the subtitle is drawn by Claude to Marko Voice (Mantra); this tells it to close. The hs line stays while the
    // star's voice.lua may still draw it (until the switch-over), and does nothing after.
    DistributedNotificationCenter.default().postNotificationName(Notification.Name("community.auroville.subtitle.hide"), object: nil, userInfo: nil, deliverImmediately: true)
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/hs")
    p.arguments = ["-t", "3", "-c", "if VOICEBUBBLE then VOICEBUBBLE.hide() end"]
    try? p.run(); p.waitUntilExit()
}

final class Box: NSPanel, NSTextViewDelegate {
    let text = NSTextView()
    init() {
        let W: CGFloat = 820, H: CGFloat = 260
        let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main!
        let f = screen.visibleFrame
        super.init(contentRect: NSRect(x: f.midX - W / 2, y: f.midY - H / 2, width: W, height: H),
                   styleMask: [.titled, .closable], backing: .buffered, defer: false)
        title = "Answer Claude (Mantra)"
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backgroundColor = NSColor(calibratedRed: 0.043, green: 0.051, blue: 0.063, alpha: 1)
        appearance = NSAppearance(named: .darkAqua)
        let v = NSView(frame: NSRect(x: 0, y: 0, width: W, height: H))
        let quote = NSTextField(wrappingLabelWithString: said)
        quote.font = NSFont(name: "Helvetica Neue", size: 16); quote.textColor = AMBER
        quote.frame = NSRect(x: 20, y: H - 74, width: W - 76, height: 56)
        v.addSubview(quote)
        // v14 (19.10.2026), Marko: "It's far upper right corner. There is X to close the dialog in every dialog, same."
        let x = NSButton(image: NSImage(systemSymbolName: "xmark", accessibilityDescription: "Close")!
                            .withSymbolConfiguration(.init(pointSize: 15, weight: .bold))!, target: self, action: #selector(closeBox))
        x.isBordered = false; x.contentTintColor = GREY; x.toolTip = "Close"
        x.frame = NSRect(x: W - 44, y: H - 42, width: 30, height: 30)
        v.addSubview(x)
        let scroll = NSScrollView(frame: NSRect(x: 20, y: 44, width: W - 40, height: H - 128))
        scroll.hasVerticalScroller = true; scroll.borderType = .noBorder
        text.frame = scroll.bounds
        text.font = NSFont(name: "Helvetica Neue", size: 21); text.textColor = SAND
        text.backgroundColor = NSColor(white: 0.12, alpha: 1); text.insertionPointColor = SAND
        text.isRichText = false; text.delegate = self; text.allowsUndo = true
        text.textContainerInset = NSSize(width: 8, height: 8)
        text.autoresizingMask = [.width]
        scroll.documentView = text
        v.addSubview(scroll)
        let hint = NSTextField(labelWithString: "ENTER sends to Claude · SHIFT+ENTER new line · ESC or empty ENTER closes")
        hint.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular); hint.textColor = GREY
        hint.frame = NSRect(x: 20, y: 14, width: W - 40, height: 18)
        v.addSubview(hint)
        contentView = v
    }
    override var canBecomeKey: Bool { true }

    func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
        if sel == #selector(NSResponder.insertNewline(_:)) {
            if NSEvent.modifierFlags.contains(.shift) { tv.insertNewlineIgnoringFieldEditor(nil); return true }
            send(); return true
        }
        if sel == #selector(NSResponder.cancelOperation(_:)) { text.string = ""; send(); return true }
        return false
    }

    func send() {
        let words = text.string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !words.isEmpty {
            try? FileManager.default.createDirectory(atPath: REPLIES, withIntermediateDirectories: true)
            let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss-SSS"
            try? (words + "\n").write(toFile: REPLIES + "/" + f.string(from: Date()) + ".txt", atomically: true, encoding: .utf8)
        }
        orderOut(nil)
        closeSubtitle()
        NSApp.terminate(nil)
    }
    override func close() { text.string = ""; send() }
    @objc func closeBox() { close() }
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
// COPY AND PASTE (Marko: "please enable copy paste in text box it should work like any text box on mac"): the keys
// ⌘X ⌘C ⌘V ⌘A ⌘Z live in the Edit menu; an app without one has none of them. The menu is never seen (no menu bar for
// an accessory app), only its keys.
let menu = NSMenu()
let edit = NSMenuItem(); menu.addItem(edit)
let em = NSMenu(title: "Edit"); edit.submenu = em
em.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
let redo = em.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "z"); redo.keyEquivalentModifierMask = [.command, .shift]
em.addItem(.separator())
em.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
em.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
em.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
em.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
app.mainMenu = menu
let box = Box()
box.makeKeyAndOrderFront(nil)
box.makeFirstResponder(box.text)
app.activate(ignoringOtherApps: true)
app.run()
