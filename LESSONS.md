# LESSONS

1. **The highlight is MA Reader web's** (`~/.maread-web/static/index.html`, `clockSample`, `highlightWordAt`):
   a predicted clock on wall time, eased halfway to each real position, snapped when 0.35 s off; the lit word
   is the last started at clock + 50 ms; the last word lets go 0.12 s after its end. Copied, not reinvented.
2. **Character offsets vs bytes**: the server's word offsets count characters; `hs.styledtext` counts bytes like
   `string.sub`. `utf8.offset` converts; without it a "−" or an accented letter shifts every later highlight.

- (13.10.2026, v8) A SwiftUI App scene cannot run with no window: the engine needs an AppKit life (NSApplication + delegate, accessory policy) and the settings window made in NSHostingController at launch and at reopen.

## The wave was a drawing, not a meter (19.10.2026)

v10's bars were two sines, moving whatever she said, and Marko saw it at once. A meter must read the sound at the
moment it is heard: the engine measures each buffer as it is handed to the speaker and keeps it with its DAC time,
and the blob asks for the one sounding now. The ballistics were taken from SPECTRAL_ANALYZER rather than invented,
and the held peaks taken out again because he did not want them on so small a thing.

## 1.11.2026

- A dragged subtitle (`ypos` ≥ 0) silently beat the WHERE choice: the window said BOTTOM while the subtitle sat near the
  top. A setting that another gesture can override must show that ("WHERE YOU DRAGGED IT") and a click must win back.
- Two apps for one engine confused Marko ("I have two voice engines"): one switch and its settings belong in one window.

## 4.11.2026
- A status-bar image that is not a template is NOT tinted by the system: a black "on" box vanished on the dark menu bar,
  and contentTintColor did not colour the ▶ either. Draw real colours (orange fill, palette-coloured symbol) or use templates.
- Check menu-bar items by CGWindowList (layer 25, IsOnscreen) and a screenshot crop; System Events sees no menu bar 2.
- `pkill -f 'MANTRA_VOICE/voiced.py'` killed my own test shell (its command line contained the text): anchor process
  patterns on the interpreter path. The same loose pattern made `alive()` report a server that was not running.
- A quitting app that stops its server first takes ~10 s; a start during that time must wait for the old app to go.

- (4.11.2026) A key named STOP that only stops the reading leaves the engine's menu-bar items behind; Marko meant "exits
the engine". Read the request's own words (momentaryupdates) for what a key must end. The subtitle keys' AX labels are
capitalised ("Stop"): match case-insensitively in tests. Two sessions both numbered their change v30 the same morning;
pull and read the latest VERSION before choosing a number.

## 5.11.2026
- Accessibility granted while the app runs: AXIsProcessTrusted can stay false until the app restarts. Check TCC
  (/Library/Application Support/com.apple.TCC/TCC.db, auth_value 2) and restart the app before calling it broken.
- Macro Recorder `Send "s"` types the character with key code 0, so it cannot test a key-code hotkey. Post the real code
  with Quartz (CGEventCreateKeyboardEvent, HID tap) from the pyenv python.
- GitHub's macOS runners can queue 15 min and fail without building ("capacity constraints"): `gh run rerun`.

## 6.11.2026 (v35)
- A CGEvent tap callback that returns nil swallows the key; returning `Unmanaged.passUnretained(ev)` after acting lets the
  app in front receive it too. Space is pass-through since v35 (Marko: "It's not swallowed by the voice engine. It is
  pass-through"); Esc and S are still taken. Re-signing with "Mantra Apps" + the same bundle id kept Accessibility.
