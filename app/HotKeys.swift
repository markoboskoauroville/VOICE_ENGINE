import AppKit
import SwiftUI

// v35 (6.11.2026): Space is no longer taken: it pauses / plays on the voice AND reaches the app in front (Resolve plays
// while the voice pauses, the next Space stops Resolve and the voice goes on). Esc and S are still taken.
// v33 (Marko, 5.11.2026: "activate the shortcut while the voice engine is running. I can simply press Escape at that
// moment to stop it, and I can press the spacebar to pause it, and I can press the S key on the keyboard to show or hide
// subtitles. Simple as that"): while a reading plays (▶ ■ SUB in the menu bar), three bare keys, in any app:
//   Esc   = ■ stop the reading        Space = ⏯ pause / play on        S = SUB, subtitles on / off
// They are taken (not passed to the app in front) only while the reading is on; with ⌘ ⌥ ⌃ ⇧ held, or a held key's
// repeats, they pass. The tap lives only as long as ▶ ■ SUB stand (MenuControls make / remove). It needs Accessibility
// for this app: missing, PERMISSIONS stands amber in the window's first row and opens that Settings page.
final class HotKeys {
    static let shared = HotKeys()
    private var tap: CFMachPort?
    private var source: CFRunLoopSource?

    static var allowed: Bool { AXIsProcessTrusted() }

    func on() {
        if tap != nil { return }
        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        guard let t = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                                        eventsOfInterest: mask, callback: { _, type, ev, _ in
            HotKeys.shared.handle(type, ev)
        }, userInfo: nil) else { return }           // no Accessibility yet: PERMISSIONS shows it
        tap = t
        source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, t, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: t, enable: true)
    }

    func off() {
        if let s = source { CFRunLoopRemoveSource(CFRunLoopGetMain(), s, .commonModes) }
        if let t = tap { CGEvent.tapEnable(tap: t, enable: false); CFMachPortInvalidate(t) }
        tap = nil; source = nil
    }

    private func handle(_ type: CGEventType, _ ev: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let t = tap { CGEvent.tapEnable(tap: t, enable: true) }
            return Unmanaged.passUnretained(ev)
        }
        guard type == .keyDown, ev.getIntegerValueField(.keyboardEventAutorepeat) == 0 else { return Unmanaged.passUnretained(ev) }
        let mods: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
        if !ev.flags.intersection(mods).isEmpty { return Unmanaged.passUnretained(ev) }
        let mc = MenuControls.shared
        switch ev.getIntegerValueField(.keyboardEventKeycode) {
        case 53: DispatchQueue.main.async { mc.stop() }      // Esc
        case 49:                                             // Space: v35 pass-through (Marko 6.11.2026: "It's not
            DispatchQueue.main.async { mc.play() }           // swallowed by the voice engine. It is pass-through"):
            return Unmanaged.passUnretained(ev)              // the voice pauses / plays on AND the app in front gets it
        case 1:  DispatchQueue.main.async { mc.sub() }       // S
        default: return Unmanaged.passUnretained(ev)
        }
        return nil                                           // Esc, S: taken, the app in front does not get them
    }
}

// PERMISSIONS, amber, top right of the first row while Accessibility is missing (MANTRA_MANIFEST rule); a click opens
// System Settings → Privacy & Security → Accessibility. It goes by itself once the switch is on.
struct PermissionsWord: View {
    @State private var ok = HotKeys.allowed
    private let tick = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    var body: some View {
        Group {
            if !ok {
                Text("PERMISSIONS").font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black).padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.orange).cornerRadius(4).padding(.trailing, 10)
                    .onTapGesture { PermissionsWord.open() }
                    .help("Accessibility is needed for Esc / Space / S while the voice reads. Click: open the Settings page")
                    .accessibilityElement().accessibilityLabel("PERMISSIONS").accessibilityAddTraits(.isButton)
                    .accessibilityAction { PermissionsWord.open() }
            }
        }
        .onReceive(tick) { _ in ok = HotKeys.allowed }
    }
    static func open() {
        // v34: ask macOS once, so Voice Engine (Mantra) is already in the Accessibility list; Marko only switches it on
        _ = AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary)
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
}
