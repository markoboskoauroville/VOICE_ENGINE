# Claude to Marko voice

The settings of the **speaking subtitle**: while the computer speaks to Marko (MANTRA_VOICE, `POST /speak`),
every sentence is written across every screen as a film subtitle, the word being said lit in another colour.
**Since v8 (13.10.2026) this app draws the subtitle itself** (`app/Subtitle.swift`, ported from MANTRA_STAR `apps/voice.lua` VOICEBUBBLE): one band per screen while the voice reads, the word being said lit, − + and PREVIOUS NEXT REPLAY CLOSE, the linger, a click on the text opens Answer Claude. It runs as the subtitle engine for as long as the app runs (no Dock icon); its window, opened at launch and at every reopen, sets how it looks. It learns that a reading began by asking `GET :8837/speaking` once a second (five times while it shows); it never starts the voice. `--test-subtitle "text"` shows a subtitle for 8 s.

- **Letters**: size as a share of the screen's height (big − and +, and a slider), colour, bold
- **The word being said**: its colour (red by default, orange letters turning red) and an optional block behind it;
  earlier / later in milliseconds
- **Band**: how much of the grey band is seen and how grey; **where**: top, middle, bottom
- **Stays after the voice**: how long the last sentence remains, so PREVIOUS still works when he comes back

Every change is written to `~/.config/subtitle.json` and shown on the screens for four seconds
(the engine's own preview). The − and + on the subtitle write the same file; this window follows it.

Build: `./build.sh` (swiftc, no Xcode, signed "Mantra Apps"). Opened from the star: Claude › Claude to Marko voice.

Marko, 3.10.2026: *"In the star menu you can call it Claude to Marko voice, and then I can adjust parameters of
this subtitle display"*; *"any settings are now Swift applications, and this is the rule."*

## The blob (v10, v11, 19.10.2026)

While the voice reads, a small pill like Speechify's dictation blob floats above everything: ✕ cancels the reading, the
eleven bars are her voice itself (v11: MANTRA_VOICE's GET /speak/bands through Spectral Analyzer's spectrum meter, low at
the left, high at the right, rising from one line and falling fast), the speech-bubble button turns the subtitle on and
off, ⚙ opens the settings, ↻ says the reading again from the top, the blue button pauses and plays. Drag it anywhere; it comes back where you left it.
v13: THE VOICE ENGINE, the window's first row, has ON / OFF: OFF stops the reading and no answer of Claude Code is read
(`voice` in subtitle.json, obeyed by the hub's Stop hook subtitle_answer.py) until ON. The blob itself is always on.
