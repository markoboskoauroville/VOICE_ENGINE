// CLAUDE TO MARKO VOICE: the settings of the speaking subtitle.
// Marko, 3.10.2026: "In the star menu you can call it Claude to Marko voice, and then I can adjust parameters of
// this subtitle display"; "any settings are now Swift applications, and this is the rule."
// The subtitle itself is drawn by the star (MANTRA_STAR apps/voice.lua, VOICEBUBBLE) on every screen while the voice
// speaks. This window only writes ~/.config/subtitle.json, which the subtitle reads at each sentence, and shows a
// preview on the screens after every change (hs -c VOICEBUBBLE.test).
import SwiftUI
import AppKit

let VERSION = 2

struct SubtitleSettings: Codable, Equatable {
    var size: Double = 6.0          // letter height, % of the screen's height
    var colour: String = "#E8A33D"  // the letters
    var band: Double = 62           // the grey band's opacity, %
    var grey: Double = 18           // the band's grey, % white
    var position: String = "middle" // middle, bottom, top
    var bold: Bool = false
    var word: String = "#FF3B30"    // v2: the word being said (MA Reader web's word highlight)
    var wordbg: String = ""         // v2: a block behind that word, "" for none
    var linger: Double = 30         // v2: seconds the last sentence stays after the voice ends
    var offset: Double = 0          // v2: ms, the highlight earlier (−) or later (+) than the voice

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
    @Published var s = SubtitleSettings.load() { didSet { if s != oldValue && !outside { s.save(); schedulePreview() } } }
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
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/hs")
        p.arguments = ["-t", "3", "-c", "if VOICEBUBBLE and VOICEBUBBLE.test then VOICEBUBBLE.test('Marko, this is how I will be written while I speak to you.', 4) end"]
        p.standardOutput = FileHandle.nullDevice; p.standardError = FileHandle.nullDevice
        try? p.run()
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

struct BigKey: View {
    let text: String; let action: () -> Void
    var body: some View {
        Text(text).font(.system(size: 34, weight: .regular)).foregroundColor(SAND)
            .frame(width: 54, height: 44).contentShape(Rectangle()).onTapGesture(perform: action)
    }
}

struct Settings: View {
    @ObservedObject var m: Model
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
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

            Row(name: "LETTERS", value: String(format: "%.1f %% of the screen", m.s.size)) {
                HStack {
                    BigKey(text: "−") { m.s.size = max(2, m.s.size - 0.5) }
                    Slider(value: $m.s.size, in: 2...14, step: 0.5)
                    BigKey(text: "+") { m.s.size = min(14, m.s.size + 0.5) }
                }
            }
            Row(name: "COLOUR", value: SWATCHES.first { $0.1 == m.s.colour }?.0 ?? m.s.colour) {
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
            Row(name: "THE WORD BEING SAID", value: WORD_SWATCHES.first { $0.1 == m.s.word }?.0 ?? m.s.word) {
                Swatches(list: WORD_SWATCHES, value: $m.s.word)
            }
            Row(name: "BEHIND THAT WORD", value: BG_SWATCHES.first { $0.1 == m.s.wordbg }?.0 ?? m.s.wordbg) {
                Swatches(list: BG_SWATCHES, value: $m.s.wordbg)
            }
            Row(name: "THE WORD EARLIER / LATER", value: String(format: "%+.0f ms", m.s.offset)) {
                Slider(value: $m.s.offset, in: -400...400, step: 10)
            }
            Row(name: "STAYS AFTER THE VOICE", value: m.s.linger >= 600 ? "10 MIN" : String(format: "%.0f s", m.s.linger)) {
                HStack {
                    ForEach([5.0, 30.0, 120.0, 600.0], id: \.self) { v in
                        Word(text: v >= 600 ? "10 MIN" : v >= 60 ? "\(Int(v / 60)) MIN" : "\(Int(v)) S", on: m.s.linger == v) { m.s.linger = v }
                    }
                }
            }
            Row(name: "BAND", value: String(format: "%.0f %% seen", m.s.band)) {
                Slider(value: $m.s.band, in: 0...100, step: 1)
            }
            Row(name: "BAND GREY", value: String(format: "%.0f %%", m.s.grey)) {
                Slider(value: $m.s.grey, in: 0...60, step: 1)
            }
            Row(name: "WHERE", value: m.s.position.uppercased()) {
                HStack {
                    ForEach(["top", "middle", "bottom"], id: \.self) { p in
                        Word(text: p.uppercased(), on: m.s.position == p) { m.s.position = p }
                    }
                    Spacer()
                    Word(text: "SHOW ON THE SCREENS", on: false) { Model.preview() }
                }
            }
            HStack {
                Spacer()
                Text("v\(VERSION)").font(.system(size: 11, design: .monospaced)).foregroundColor(GREY)
            }
        }
        .padding(24)
        .frame(width: 520)
        .background(INK)
        .tint(AMBER)
        .preferredColorScheme(.dark)
    }
}

@main
struct ClaudeToMarkoVoice: App {
    @StateObject var m = Model()
    var body: some Scene {
        WindowGroup("Claude to Marko voice") { Settings(m: m) }
            .windowResizability(.contentSize)
    }
}
