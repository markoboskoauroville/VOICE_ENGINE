// VOICE ENGINE (Mantra): the voice of the whole Mac in one app, its switch, its voice and its subtitles.
// v20 (Marko, 1.11.2026: "Please unite both applications into one. Voice of Claude Mantra and Claude to Marko Voice Mantra
// should be one app ... we need to call it voice engine ... We need to call what's appearing on the on the screen
// subtitles ... I don't understand this control panel. So the band on the big screen. this confusing word"): Voice of
// Claude's switch (start / stop MANTRA_VOICE through launchd, its three parts RUNNING / STOPPED) is the first row here;
// the controls are named for what they do (SUBTITLES, BACKGROUND, MAIN SCREEN); "OFF, ANSWERS NOT READ" is gone (it fed
// only the Stop hook subtitle_answer.py, taken out on 31.10.2026). Before v20 this app was Claude to Marko Voice.
//
// v26 (2.11.2026): the order ▶ ■ SUB. v25: SUB beside ▶ ■ turns the subtitles on/off, off by default. v24: no blob; while she reads ▶ (pause/play) and ■ (stop) stand in the menu bar (MenuControls.swift). v23: a stuck GET /speaking poll is dropped after 3 s, so the blob (✕ stops her) always comes. v22: the notice as wide as its words. v21 (1.11.2026): a held reading says why under the blob, with READ ANYWAY (Blob.swift showHeld); the engine holds
// only for Voice to Text (Mantra) and Speechify listening to him (MANTRA_VOICE voiced.py MicGuard.LISTENERS).
//
// CLAUDE TO MARKO VOICE (until v19): the speaking subtitle and its settings.
// Marko, 3.10.2026: "In the star menu you can call it Claude to Marko voice, and then I can adjust parameters of
// this subtitle display"; "any settings are now Swift applications, and this is the rule."
// v8 (13.10.2026, "no more Lua, only Swift"): the subtitle itself is drawn by this app (Subtitle.swift), no longer by
// the star's voice.lua. The app is the engine for as long as it runs; this window, opened on demand (at launch and
// at every reopen), writes ~/.config/subtitle.json and shows a preview on the screens after every change.
import SwiftUI
import AppKit

// v19 (31.10.2026, Marko: "Each needs to have the same user interface elements. On, off and top. Please build it in
// every application."): TOP on the settings window's ON / OFF row before the ✕, green = the window stays above every
// other window (NSWindow.level .floating), kept in UserDefaults "onTop" and applied when the window opens; TOP and ✕
// are Accessibility buttons `top`, `close`. ON / OFF themselves are left as they were. Answer Claude (Mantra) got its
// own first row: ON OFF · ANSWER CLAUDE · TOP ✕ (reply/main.swift).
let VERSION = 39

struct SubtitleSettings: Codable, Equatable {
    var size: Double = 6.0          // letter height, % of the screen's height
    var colour: String = "#E8A33D"  // the letters
    var band: Double = 62           // the grey band's opacity, %
    var grey: Double = 18           // the band's grey, % white
    var position: String = "middle" // middle, bottom, top
    var bold: Bool = false
    var word: String = "#FF3B30"    // v2: the word being said (MA Reader web's word highlight)
    var wordbg: String = ""         // v2: a block behind that word, "" for none
    var linger: Double = 2          // v2: seconds the last sentence stays after the voice ends; 0 = until clicked (v3); 2 s by default (Marko, 13.10.2026)
    var offset: Double = 0          // v2: ms, the highlight earlier (−) or later (+) than the voice
    var bandmain: Bool = true       // v7: the band on the main (big) screen; off = letters only there (Marko, 13.10.2026)
    var subtitles: Bool = true      // v10: the blob's CC, the subtitle on or off (Marko, 19.10.2026)
    var voice: Bool = true          // v13: THE VOICE ENGINE ON / OFF; off, the Stop hook reads no answer (Marko, 19.10.2026)
    var ypos: Double = -1           // v18: where he dragged the band, its centre as a fraction of the screen's height from
                                    // the bottom (0..1); -1 = `position` decides (Marko, 31.10.2026)

    init() {}
    // a file from an older version lacks the new keys: each one missing takes its default
    init(from d: Decoder) throws {
        let c = try d.container(keyedBy: CodingKeys.self)
        let z = SubtitleSettings()
        size = (try? c.decode(Double.self, forKey: .size)) ?? z.size
        colour = (try? c.decode(String.self, forKey: .colour)) ?? z.colour
        band = (try? c.decode(Double.self, forKey: .band)) ?? z.band
        grey = (try? c.decode(Double.self, forKey: .grey)) ?? z.grey
        position = (try? c.decode(String.self, forKey: .position)) ?? z.position
        bold = (try? c.decode(Bool.self, forKey: .bold)) ?? z.bold
        word = (try? c.decode(String.self, forKey: .word)) ?? z.word
        wordbg = (try? c.decode(String.self, forKey: .wordbg)) ?? z.wordbg
        linger = (try? c.decode(Double.self, forKey: .linger)) ?? z.linger
        offset = (try? c.decode(Double.self, forKey: .offset)) ?? z.offset
        bandmain = (try? c.decode(Bool.self, forKey: .bandmain)) ?? z.bandmain
        subtitles = (try? c.decode(Bool.self, forKey: .subtitles)) ?? z.subtitles
        voice = (try? c.decode(Bool.self, forKey: .voice)) ?? z.voice
        ypos = (try? c.decode(Double.self, forKey: .ypos)) ?? z.ypos
    }

    static let file = URL(fileURLWithPath: NSHomeDirectory() + "/.config/subtitle.json")
    static func load() -> SubtitleSettings {
        guard let d = try? Data(contentsOf: file), let s = try? JSONDecoder().decode(SubtitleSettings.self, from: d) else { return SubtitleSettings() }
        return s
    }
    func save() {
        try? FileManager.default.createDirectory(at: Self.file.deletingLastPathComponent(), withIntermediateDirectories: true)
        let e = JSONEncoder(); e.outputFormatting = [.prettyPrinted, .sortedKeys]
        if let d = try? e.encode(self) { try? d.write(to: Self.file, options: .atomic) }
    }
}

// the CAMERA language: words, green on, grey off, amber the value
let GREEN = Color(red: 0x33/255, green: 0xD1/255, blue: 0x7A/255)
let GREY = Color(red: 0x7A/255, green: 0x80/255, blue: 0x87/255)
let AMBER = Color(red: 0xE8/255, green: 0xA3/255, blue: 0x3D/255)
let INK = Color(red: 0x0B/255, green: 0x0D/255, blue: 0x10/255)
let SAND = Color(red: 0xF2/255, green: 0xDD/255, blue: 0xB4/255)

func colour(_ hex: String) -> Color {
    let h = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
    let v = UInt32(h, radix: 16) ?? 0xE8A33D
    return Color(red: Double((v >> 16) & 255) / 255, green: Double((v >> 8) & 255) / 255, blue: Double(v & 255) / 255)
}

let WORD_SWATCHES: [(String, String)] = [("RED", "#FF3B30"), ("WHITE", "#FFFFFF"), ("YELLOW", "#F5E663"), ("ORANGE", "#E8A33D"), ("GREEN", "#33D17A"), ("CYAN", "#7FDBFF")]
let BG_SWATCHES: [(String, String)] = [("NONE", ""), ("YELLOW", "#F5E663"), ("RED", "#FF3B30"), ("WHITE", "#FFFFFF"), ("BLACK", "#000000")]
let SWATCHES: [(String, String)] = [("ORANGE", "#E8A33D"), ("WHITE", "#FFFFFF"), ("YELLOW", "#F5E663"), ("SAND", "#F2DDB4"), ("GREEN", "#33D17A"), ("CYAN", "#7FDBFF")]

final class Model: ObservableObject {
    @Published var s = SubtitleSettings.load() { didSet { if s != oldValue && !outside { s.save(); if s.voice == oldValue.voice { schedulePreview() } } } }
    private var pending: DispatchWorkItem?
    private var outside = false
    private var watch: Timer?
    // the − and + on the subtitle itself change the same file: the window follows it, without a preview of its own
    init() {
        watch = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let f = SubtitleSettings.load()
            if f != self.s { self.outside = true; self.s = f; self.outside = false }
        }
    }
    func schedulePreview() {
        pending?.cancel()
        let w = DispatchWorkItem { Self.preview() }
        pending = w
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: w)
    }
    static func preview() {
        SubtitleEngine.shared.test("Marko, this is how I will be written while I speak to you.", 4)
    }
}

struct Word: View {
    let text: String; let on: Bool; let action: () -> Void
    var body: some View {
        Text(text).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(on ? GREEN : GREY)
            .padding(.horizontal, 6).padding(.vertical, 4).contentShape(Rectangle()).onTapGesture(perform: action)
    }
}

struct Row<Content: View>: View {
    let name: String; let value: String; @ViewBuilder let content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(name).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY)
                Spacer()
                Text(value).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(AMBER)
            }
            content
        }
    }
}

struct Swatches: View {
    let list: [(String, String)]; @Binding var value: String
    var body: some View {
        HStack(spacing: 10) {
            ForEach(list, id: \.1) { sw in
                ZStack {
                    if sw.1.isEmpty { Circle().stroke(GREY, lineWidth: 1.5); Text("—").foregroundColor(GREY) }
                    else { Circle().fill(colour(sw.1)) }
                }
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(value == sw.1 ? GREEN : Color.clear, lineWidth: 3).padding(-4))
                .onTapGesture { value = sw.1 }
            }
        }.padding(.vertical, 4)
    }
}

// 0 is forever: the subtitle stays until a click on its text (Marko, 3.10.2026: "for now it's forever")
func lingerName(_ v: Double) -> String { v <= 0 ? "FOREVER" : v >= 60 ? "\(Int(v / 60)) MIN" : "\(Int(v)) S" }

struct BigKey: View {
    let text: String; let action: () -> Void
    var body: some View {
        Text(text).font(.system(size: 34, weight: .regular)).foregroundColor(SAND)
            .frame(width: 54, height: 44).contentShape(Rectangle()).onTapGesture(perform: action)
    }
}

// THE ENGINE (v6). Marko, 13.10.2026: "there must also be options for which engine to use. Now we can add the original
// Speechify engine to talk with me". The choice lives in MANTRA_VOICE (~/.voice/voice.json) and is changed only
// through its API (API.md): GET /voices for the list and the current one, POST /current to change it. Beatrice is
// the Speechify voice (paid); CLONE is one of the cloned voices. The app never starts the voice: off, it says so.
let VOICE_API = "http://127.0.0.1:8837"

final class Engine: ObservableObject {
    @Published var up = false
    @Published var engine = ""          // "clone" or "beatrice"
    @Published var voice = ""
    @Published var voices: [String] = []
    @Published var busy = false
    private var timer: Timer?
    init() {
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in self?.refresh() }
    }
    func refresh() {
        var r = URLRequest(url: URL(string: VOICE_API + "/voices")!); r.timeoutInterval = 2
        URLSession.shared.dataTask(with: r) { d, _, _ in
            let j = d.flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }
            DispatchQueue.main.async {
                guard let j = j else { self.up = false; return }
                self.up = true
                let cur = j["current"] as? [String: Any] ?? [:]
                self.engine = cur["engine"] as? String ?? ""
                self.voice = cur["voice"] as? String ?? ""
                self.voices = (j["voices"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
            }
        }.resume()
    }
    func post(_ path: String, _ body: [String: Any], then: (() -> Void)? = nil) {
        var r = URLRequest(url: URL(string: VOICE_API + path)!)
        r.httpMethod = "POST"; r.setValue("application/json", forHTTPHeaderField: "Content-Type")
        r.httpBody = try? JSONSerialization.data(withJSONObject: body)
        busy = true
        URLSession.shared.dataTask(with: r) { _, _, _ in
            DispatchQueue.main.async { self.busy = false; self.refresh(); then?() }
        }.resume()
    }
    func use(engine e: String, voice v: String? = nil) {
        var b: [String: Any] = ["engine": e]; if let v = v { b["voice"] = v }
        engine = e; if let v = v { voice = v }            // the window answers at once; refresh() confirms
        post("/current", b)
    }
    func hear() { post("/speak", ["text": "Marko, this is how I sound now."]) }
}

// THE SWITCH (v20, from Voice of Claude v6, 8.10.2026: "make [a Swift app] ... in which I can easily turn on and off the
// engine"). The engine is three processes: voiced.py (the HTTP API on :8837), ears.py (Whisper) and clone.py (the cloned
// voice). ON asks launchd to start voiced (com.mantra.voiced, no KeepAlive) and remembers it (the agent enabled, so
// login starts it); OFF stops all three and remembers it (the agent disabled). The window stays either way.
let HOME = NSHomeDirectory()
let VOICE_DIR = HOME + "/Developer/MANTRA_VOICE"
let PYTHON = HOME + "/.pyenv/versions/3.10.14/bin/python3"
let AGENT = "com.mantra.voiced"

@discardableResult
func sh(_ cmd: String) -> (Int32, String) {
    let p = Process(); let pipe = Pipe()
    p.executableURL = URL(fileURLWithPath: "/bin/sh"); p.arguments = ["-c", cmd]
    p.standardOutput = pipe; p.standardError = pipe
    do { try p.run() } catch { return (-1, "") }
    let d = pipe.fileHandleForReading.readDataToEndOfFile(); p.waitUntilExit()
    return (p.terminationStatus, String(data: d, encoding: .utf8) ?? "")
}
func alive(_ pattern: String) -> Bool { sh("/usr/bin/pgrep -f '\(pattern)' >/dev/null").0 == 0 }

struct Part: Identifiable { let id: String; let what: String; let pattern: String }
let PARTS = [
    Part(id: "SPEAKING SERVER", what: "the door every app talks to, 127.0.0.1:8837", pattern: "^/[^ ]*python3[.0-9]* /[^ ]*/MANTRA_VOICE/voiced[.]py"),
    Part(id: "LISTENING", what: "Whisper, speech to text; wakes when asked", pattern: "^/[^ ]*python3[.0-9]* /[^ ]*/MANTRA_VOICE/ears[.]py serve"),
    Part(id: "CLONED VOICE", what: "the voice model on the Mac; wakes when asked", pattern: "^/[^ ]*python3[.0-9]* /[^ ]*/MANTRA_VOICE/clone[.]py serve"),
]

final class Switch: ObservableObject {
    @Published var up: [String: Bool] = [:]
    @Published var busy: String? = nil          // "STARTING" / "STOPPING" while the switch works
    private var timer: Timer?
    private let q = DispatchQueue(label: "switch")
    var on: Bool { up[PARTS[0].id] ?? false }   // the engine is on when its server answers
    init() {
        look()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.look() }
    }
    func look() {
        q.async {
            var u: [String: Bool] = [:]
            for p in PARTS { u[p.id] = alive(p.pattern) }
            DispatchQueue.main.async { self.up = u }
        }
    }
    func start() { busy = "STARTING"; q.async { Switch.startNow(); DispatchQueue.main.async { self.busy = nil; self.look() } } }
    func stop() { busy = "STOPPING"; q.async { Switch.stopNow(); DispatchQueue.main.async { self.busy = nil; self.look() } } }
    static func startNow() {
        let uid = getuid()
        sh("launchctl enable gui/\(uid)/\(AGENT)")
        if sh("launchctl kickstart gui/\(uid)/\(AGENT)").0 != 0 {
            sh("launchctl bootstrap gui/\(uid) '\(HOME)/Library/LaunchAgents/\(AGENT).plist'")
        }
        for _ in 0..<40 where !alive(PARTS[0].pattern) { usleep(250_000) }
    }
    static func stopNow() {
        sh("launchctl disable gui/\(getuid())/\(AGENT)")
        // v31: anchored on the python binary, so a shell or a session whose command line only MENTIONS voiced.py is never hit
        sh("/usr/bin/pkill -f '^/[^ ]*python3[.0-9]* /[^ ]*/MANTRA_VOICE/voiced[.]py'")
        sh("'\(PYTHON)' '\(VOICE_DIR)/clone.py' stop; '\(PYTHON)' '\(VOICE_DIR)/ears.py' stop")
        for _ in 0..<20 where PARTS.contains(where: { alive($0.pattern) }) { usleep(250_000) }
        sh("/usr/bin/pkill -f '^/[^ ]*python3[.0-9]* /[^ ]*/MANTRA_VOICE/(ears|clone)[.]py serve'")
    }
}

// The first row (v20): ON OFF · VOICE ENGINE · TOP ✕, then the three parts. ON / OFF start and stop the engine itself.
struct SwitchRow: View {
    @ObservedObject var sw: Switch
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 0) {
                if let b = sw.busy {
                    Text(b).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(AMBER).padding(.horizontal, 6)
                } else {
                    Word(text: "ON", on: sw.on) { if !sw.on { sw.start() } }
                        .axButton("Voice engine on", id: "engine-on", value: sw.on ? "on" : "off") { if sw.busy == nil && !sw.on { sw.start() } }
                    Word(text: "OFF", on: !sw.on) { if sw.on { sw.stop() } }
                        .axButton("Voice engine off", id: "engine-off", value: sw.on ? "on" : "off") { if sw.busy == nil && sw.on { sw.stop() } }
                }
                Text("VOICE ENGINE").font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(SAND).padding(.leading, 12)
                Spacer()
                TopWord()
                CloseX()
            }
            ForEach(PARTS) { p in
                let u = sw.up[p.id] ?? false
                HStack(spacing: 10) {
                    Circle().fill(u ? GREEN : GREY).frame(width: 8, height: 8)
                    Text(p.id).font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(u ? GREEN : GREY).frame(width: 128, alignment: .leading)
                    Text(p.what).font(.system(size: 11)).foregroundColor(SAND.opacity(0.7)).lineLimit(1)
                    Spacer()
                    Text(u ? "RUNNING" : "STOPPED").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(u ? GREEN : GREY)
                }
            }
        }
    }
}

// v13 (19.10.2026). Marko: "in that window at the top voice engine on off so I can turn it off": OFF stops the reading
// now (/speak/stop) and is kept in subtitle.json as `voice: false`, which the Stop hook subtitle_answer.py obeys, so no
// answer is read until ON. The voice server itself keeps running (this app never starts or stops it).
struct EngineRow: View {
    @ObservedObject var e: Engine
    var body: some View {
        // v20: which voice speaks; the switch above starts and stops the engine itself
        Row(name: "WHICH VOICE SPEAKS", value: !e.up ? "ENGINE OFF" : engineName(e.engine, e.voice)) {
            HStack(spacing: 0) {
                Word(text: "SPEECHIFY", on: e.up && e.engine == "beatrice") { e.use(engine: "beatrice") }
                Text("|").font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(AMBER)
                Word(text: "CLONED VOICE ON THE MAC", on: e.up && e.engine == "clone") { e.use(engine: "clone", voice: e.voice.isEmpty ? e.voices.first : e.voice) }
                Spacer()
                if e.up { Word(text: e.busy ? "…" : "HEAR IT", on: false) { e.hear() } }
            }
            if !e.up {
                Text("The engine is off: ON above starts it.")
                    .font(.system(size: 11, design: .monospaced)).foregroundColor(GREY)
            } else if e.engine == "clone" {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(e.voices, id: \.self) { v in
                            Word(text: v.uppercased(), on: e.voice == v) { e.use(engine: "clone", voice: v) }
                        }
                    }
                }
            }
        }
    }
}

// v14 (19.10.2026). Marko: "please unify the position of the close button on every application. It's far upper right
// corner. There is X to close the dialog in every dialog, same." The ✕ closes the window; the app stays on.
struct CloseX: View {
    var body: some View {
        Image(systemName: "xmark").font(.system(size: 15, weight: .bold)).foregroundColor(GREY)
            .frame(width: 30, height: 30).contentShape(Rectangle())
            .onTapGesture { (NSApp.delegate as? Delegate)?.window?.performClose(nil) }
            .axButton("Close window", id: "close") { (NSApp.delegate as? Delegate)?.window?.performClose(nil) }
            .help("Close")
    }
}

// v19 (31.10.2026): TOP, green = the settings window stays above every other window; remembered in "onTop"
struct TopWord: View {
    @AppStorage("onTop") private var onTop = false
    var body: some View {
        Word(text: "TOP", on: onTop) { onTop.toggle(); TopWord.float(onTop) }
            .axButton("Top", id: "top", value: onTop ? "on" : "off") { onTop.toggle(); TopWord.float(onTop) }
            .help("Always on top: green, the window stays above every other window")
            .onAppear { DispatchQueue.main.async { TopWord.float(onTop) } }
    }
    static func float(_ on: Bool) {
        for w in NSApp.windows where w.title.hasPrefix("Voice Engine") { w.level = on ? .floating : .normal }
    }
}

// every control an Accessibility button (MANTRA_MANIFEST swift-apps.md, "Accessibility built in")
extension View {
    func axButton(_ label: String, id: String, value: String? = nil, _ action: @escaping () -> Void) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityIdentifier(id)
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(.default, action)
    }
}

struct Settings: View {
    @ObservedObject var m: Model
    @StateObject var engine = Engine()
    @StateObject var sw = Switch()
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SwitchRow(sw: sw)
            Divider().overlay(GREY.opacity(0.35))
            EngineRow(e: engine)
            Divider().overlay(GREY.opacity(0.35))
            // v20: SUBTITLES, the words written on the screens while the voice speaks
            Row(name: "SUBTITLES", value: m.s.subtitles ? "SHOWN WHILE THE VOICE SPEAKS" : "OFF, VOICE ONLY") {
                HStack {
                    Word(text: "ON", on: m.s.subtitles) { m.s.subtitles = true }
                    Word(text: "OFF", on: !m.s.subtitles) { m.s.subtitles = false }
                    Spacer()
                    Word(text: "SHOW A TEST SUBTITLE", on: false) { Model.preview() }
                }
            }
            // the subtitle as it will look, small
            ZStack {
                Rectangle().fill(Color(white: m.s.grey / 100).opacity(m.s.band / 100))
                (Text("Marko, this is how I ").foregroundColor(colour(m.s.colour))
                 + Text("will").foregroundColor(colour(m.s.word))
                 + Text(" be written.").foregroundColor(colour(m.s.colour)))
                    .font(.custom("Helvetica Neue", size: 22).weight(m.s.bold ? .bold : .regular))
            }
            .frame(height: 64)
            .background(LinearGradient(colors: [Color(white: 0.35), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing))

            Row(name: "LETTER SIZE", value: String(format: "%.1f %% of the screen height", m.s.size)) {
                HStack {
                    BigKey(text: "−") { m.s.size = max(2, m.s.size - 0.5) }
                    Slider(value: $m.s.size, in: 2...14, step: 0.5)
                    BigKey(text: "+") { m.s.size = min(14, m.s.size + 0.5) }
                }
            }
            Row(name: "LETTER COLOUR", value: SWATCHES.first { $0.1 == m.s.colour }?.0 ?? m.s.colour) {
                HStack(spacing: 10) {
                    ForEach(SWATCHES, id: \.1) { sw in
                        Circle().fill(colour(sw.1)).frame(width: 26, height: 26)
                            .overlay(Circle().stroke(m.s.colour == sw.1 ? GREEN : Color.clear, lineWidth: 3).padding(-4))
                            .onTapGesture { m.s.colour = sw.1 }
                    }
                    Spacer()
                    Word(text: "BOLD", on: m.s.bold) { m.s.bold.toggle() }
                }.padding(.vertical, 4)
            }
            Row(name: "COLOUR OF THE WORD BEING SPOKEN", value: WORD_SWATCHES.first { $0.1 == m.s.word }?.0 ?? m.s.word) {
                Swatches(list: WORD_SWATCHES, value: $m.s.word)
            }
            Row(name: "MARKER BEHIND THE SPOKEN WORD", value: BG_SWATCHES.first { $0.1 == m.s.wordbg }?.0 ?? m.s.wordbg) {
                Swatches(list: BG_SWATCHES, value: $m.s.wordbg)
            }
            Row(name: "SPOKEN WORD LIT EARLIER / LATER", value: String(format: "%+.0f ms", m.s.offset)) {
                Slider(value: $m.s.offset, in: -400...400, step: 10)
            }
            Row(name: "SUBTITLE STAYS AFTER THE VOICE STOPS", value: lingerName(m.s.linger)) {
                HStack {
                    ForEach([2.0, 30.0, 120.0, 600.0, 0.0], id: \.self) { v in
                        Word(text: lingerName(v), on: m.s.linger == v) { m.s.linger = v }
                    }
                }
            }
            Row(name: "BACKGROUND BEHIND THE SUBTITLE", value: m.s.band < 1 ? "NONE" : String(format: "%.0f %% solid", m.s.band)) {
                HStack(spacing: 8) {
                    Text("CLEAR").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY)
                    Slider(value: $m.s.band, in: 0...100, step: 1)
                    Text("SOLID").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY)
                }
            }
            Row(name: "BACKGROUND SHADE", value: String(format: "%.0f %% light", m.s.grey)) {
                HStack(spacing: 8) {
                    Text("DARK").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY)
                    Slider(value: $m.s.grey, in: 0...60, step: 1)
                    Text("LIGHT").font(.system(size: 10, weight: .bold, design: .monospaced)).foregroundColor(GREY)
                }
            }
            Row(name: "BACKGROUND ON THE MAIN SCREEN", value: m.s.bandmain ? "ON" : "OFF, LETTERS ONLY THERE") {
                HStack {
                    Word(text: "ON", on: m.s.bandmain) { m.s.bandmain = true }
                    Word(text: "OFF", on: !m.s.bandmain) { m.s.bandmain = false }
                }
            }
            Row(name: "WHERE ON THE SCREEN", value: m.s.ypos >= 0 ? "WHERE YOU DRAGGED IT" : m.s.position.uppercased()) {
                HStack {
                    ForEach(["top", "middle", "bottom"], id: \.self) { p in
                        // v20: a click places it there, also after a drag (the drag kept `ypos`, which won over this choice)
                        Word(text: p.uppercased(), on: m.s.ypos < 0 && m.s.position == p) { m.s.ypos = -1; m.s.position = p }
                    }
                    Spacer()
                }
            }
            HStack {
                Spacer()
                Text("v\(VERSION)").font(.system(size: 11, design: .monospaced)).foregroundColor(GREY)
            }
        }
        .padding(24)
        .frame(width: 560)
        .background(INK)
        .tint(AMBER)
        .preferredColorScheme(.dark)
    }
}

// THE ANSWER (v4). Marko, 3.10.2026: "when I click on it instead of closing it ... open the text input window when
// I'm going to answer you, and then when I send the answer you're receiving it right here in this chat ... if I send
// an empty message it means I will just close the thing." `--reply` opens only this box, over everything, with the
// sentence he answers above it. Enter sends: the words go to ~/.voice/replies/<time>.txt, which the Claude Code
// session watches and reads as his message; empty, nothing is sent. Either way the subtitle closes (and its wave
// files go, POST /speak/close) and the box quits.
let REPLIES = NSHomeDirectory() + "/.voice/replies"

func closeSubtitle() {
    var r = URLRequest(url: URL(string: "http://127.0.0.1:8837/speak/close")!)
    r.httpMethod = "POST"; r.httpBody = Data("{}".utf8); r.setValue("application/json", forHTTPHeaderField: "Content-Type")
    let done = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: r) { _, _, _ in done.signal() }.resume()
    _ = done.wait(timeout: .now() + 2)
    DistributedNotificationCenter.default().postNotificationName(Notification.Name(HIDE_NOTE), object: nil, userInfo: nil, deliverImmediately: true)
}

// v5: the box opened UNDER the subtitle (an overlay-level window across the middle of the screen): his clicks
// launched it nine times and nothing was seen. Now its window is raised above every overlay, sits in the upper
// third of the screen with the pointer, and takes the keyboard.
struct OnTop: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.screenSaverWindow)) + 1)
            w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            let screen = NSScreen.screens.first { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) } ?? NSScreen.main
            if let f = screen?.visibleFrame {
                w.setFrameOrigin(NSPoint(x: f.midX - w.frame.width / 2, y: f.maxY - f.height / 3 - w.frame.height / 2))
            }
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return v
    }
    func updateNSView(_ v: NSView, context: Context) {}
}

struct Reply: View {
    let said: String
    @State var text = ""
    @FocusState var focus: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !said.isEmpty {
                Text(said).font(.custom("Helvetica Neue", size: 17)).foregroundColor(AMBER).fixedSize(horizontal: false, vertical: true)
            }
            TextField("Your answer to Claude (Enter sends; empty closes)", text: $text, axis: .vertical)
                .font(.custom("Helvetica Neue", size: 20)).textFieldStyle(.plain).lineLimit(1...8)
                .padding(12).background(Color(white: 0.12)).focused($focus)
                .onSubmit { send() }
            HStack {
                Text("ENTER sends · ESC closes").font(.system(size: 11, design: .monospaced)).foregroundColor(GREY)
                Spacer()
                Text("SEND").font(.system(size: 14, weight: .bold, design: .monospaced)).foregroundColor(GREEN).onTapGesture { send() }
            }
        }
        .padding(20).frame(width: 760).background(INK).preferredColorScheme(.dark)
        .background(OnTop())
        .onAppear { focus = true; NSApp.activate(ignoringOtherApps: true) }
        .onExitCommand { text = ""; send() }
    }

    func send() {
        let words = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !words.isEmpty {
            try? FileManager.default.createDirectory(atPath: REPLIES, withIntermediateDirectories: true)
            let f = DateFormatter(); f.dateFormat = "yyyyMMdd-HHmmss-SSS"
            try? (words + "\n").write(toFile: REPLIES + "/" + f.string(from: Date()) + ".txt", atomically: true, encoding: .utf8)
        }
        closeSubtitle()
        NSApp.terminate(nil)
    }
}

// v8: an AppKit life, so the engine runs with no window open. The settings window is made at launch and at every
// reopen (the star's click, the Dock, Finder); closing it leaves the subtitle working; quitting the app ends it.
// --reply keeps the old answer box of v4 (Answer Claude (Mantra).app is the one the subtitle opens).
final class Delegate: NSObject, NSApplicationDelegate {
    let replying = CommandLine.arguments.contains("--reply")
    let said: String = {
        let a = CommandLine.arguments
        if let i = a.firstIndex(of: "--said"), i + 1 < a.count { return a[i + 1] }
        return ""
    }()
    var model: Model?
    var window: NSWindow?
    func applicationDidFinishLaunching(_ n: Notification) {
        if replying { open(NSHostingController(rootView: Reply(said: said)), "Answer Claude (Mantra)"); return }
        SubtitleEngine.shared.start()
        // `--test-subtitle "text"`: the subtitle shows that text for 8 s (a check without a reading)
        let a = CommandLine.arguments
        if let i = a.firstIndex(of: "--test-subtitle") { Owner.shared.testing = true; SubtitleEngine.shared.test(i + 1 < a.count ? a[i + 1] : "Marko, this is a test of the subtitle.", 8); return }
        Owner.shared.begin()                    // v31: this app IS the engine: the voice comes and goes with it
        // v9 (18.10.2026): brought back by the star at login (--login), the subtitle runs and the window waits
        if a.contains("--login") { return }
        openSettings()
    }
    func applicationShouldHandleReopen(_ s: NSApplication, hasVisibleWindows: Bool) -> Bool { if !replying { openSettings() }; return true }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { replying }
    func applicationWillTerminate(_ n: Notification) {
        guard !replying else { return }
        MenuControls.shared.removeAll()
        if !Owner.shared.testing { Switch.stopNow() }   // v31: quitting the app quits the voice
    }
    func openSettings() {
        if model == nil { model = Model() }
        if let w = window { w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true); return }
        open(NSHostingController(rootView: Settings(m: model!)), "Voice Engine (Mantra)")
    }
    func open<V: View>(_ vc: NSHostingController<V>, _ title: String) {
        let w = NSWindow(contentViewController: vc)
        w.title = title; w.styleMask = [.titled, .closable, .miniaturizable]; w.isReleasedWhenClosed = false
        w.center(); w.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true)
        window = w
    }
}

// v31 ONE APP (Marko, 4.11.2026: "Now you close the engine, and the sub icon is remaining ... the whole engine which
// generates subtitles and reads everything, should be under one app ... background app, same as my API for Star Menu").
// The app owns the voice server (launchd com.mantra.voiced, Python: the voice models live there): it starts it when the
// app starts, stops it when the app quits, and when the server is stopped from outside (voicectl stop, the ON/OFF
// switch, a crash) the app quits too, so no icon is ever left without a voice behind it. voicectl start opens the app.
final class Owner {
    static let shared = Owner()
    var testing = false
    private var seenUp = false, down = 0
    private let q = DispatchQueue(label: "owner")
    func begin() {
        q.async { if !alive(PARTS[0].pattern) { Switch.startNow() } }
        Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.q.async {
                guard let self = self else { return }
                if alive(PARTS[0].pattern) { self.seenUp = true; self.down = 0; return }
                guard self.seenUp else { return }
                self.down += 1
                if self.down >= 4 { DispatchQueue.main.async { NSApp.terminate(nil) } }   // 8 s gone: the engine closed
            }
        }
    }
}

@main
struct Main {
    static func main() {
        // v20: the engine's switch from a terminal (Voice of Claude's): --on, --off, --status print, then exit
        let a = CommandLine.arguments
        if a.contains("--on") || a.contains("--off") || a.contains("--status") {
            if a.contains("--on") { Switch.startNow() }
            if a.contains("--off") { Switch.stopNow() }
            for p in PARTS { print(p.id + ": " + (alive(p.pattern) ? "running" : "stopped")) }
            let off = sh("launchctl print-disabled gui/\(getuid()) | grep -q '\"\(AGENT)\" => \\(true\\|disabled\\)'").0 == 0
            print("AT LOGIN: " + (off ? "stays off" : "starts"))
            exit(0)
        }
        let app = NSApplication.shared
        let d = Delegate(); app.delegate = d
        app.setActivationPolicy(.accessory)        // an engine: no Dock icon; the window comes and goes
        app.run()
    }
}
