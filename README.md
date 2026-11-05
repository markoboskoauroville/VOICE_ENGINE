# Voice Engine (Mantra)

**The voice of the whole Mac in one app** (since v20, 1.11.2026). Marko: *"Please unite both applications into one.
Voice of Claude Mantra and Claude to Marko Voice Mantra should be one app ... we need to call it voice engine ... We need
to call what's appearing on the screen subtitles."* Until v19 this repository was CLAUDE_TO_MARKO_VOICE (the subtitles);
Voice of Claude (the engine's switch, repo VOICE_OF_CLAUDE, v6) is now its first row.

The window, top to bottom:

- **ON OFF · VOICE ENGINE · TOP ✕**: ON and OFF start and stop the engine (MANTRA_VOICE: its LaunchAgent
  `com.mantra.voiced`), remembered for the next login; under it SPEAKING SERVER (the API at 127.0.0.1:8837),
  LISTENING (Whisper) and CLONED VOICE, each RUNNING or STOPPED. The same from a terminal:
  `"/Applications/Voice Engine (Mantra).app/Contents/MacOS/VoiceEngine" --on | --off | --status`.
- **WHICH VOICE SPEAKS**: SPEECHIFY | CLONED VOICE ON THE MAC, HEAR IT, and the cloned voices.
- **SUBTITLES** (the words written on the screens while the voice speaks): ON / OFF, SHOW A TEST SUBTITLE, a preview,
  LETTER SIZE, LETTER COLOUR, COLOUR OF THE WORD BEING SPOKEN, MARKER BEHIND THE SPOKEN WORD, SPOKEN WORD LIT EARLIER /
  LATER, SUBTITLE STAYS AFTER THE VOICE STOPS, BACKGROUND BEHIND THE SUBTITLE (clear ↔ solid), BACKGROUND SHADE
  (dark ↔ light), BACKGROUND ON THE MAIN SCREEN, WHERE ON THE SCREEN (TOP / MIDDLE / BOTTOM, or WHERE YOU DRAGGED IT).
  The old words: "band" is the background, "big screen" the main screen.

**Keys while the voice reads** (v33, 5.11.2026): Esc stops the reading, Space pauses / plays on, S shows / hides the
subtitles, in any app, only while ▶ ■ SUB stand in the menu bar (Accessibility; PERMISSIONS in the first row while missing).

**When the voice waits** (v21–v22): only while Voice to Text (Mantra) records a take or Speechify listens to Marko; a notice
under the blob says why ("WAITING: VOICE TO TEXT (MANTRA) IS RECORDING YOU") with READ ANYWAY, which plays this reading at once.

The app also draws the subtitles and the blob while the voice reads (below); the star brings it back at login with
`--login`, and MANTRA_VOICE's voiced.py opens it if a reading starts without it. Build: `./build.sh`.

---

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
v14: ✕ at the far upper-right of the settings window and the Answer Claude box, as in every Mantra app (closes the window only).

**v18 (31.10.2026): the subtitle is dragged, never lost.** Marko: *"I clicked on the subtitle itself and it disappeared. Then I clicked on the blob to bring back the subtitle and it didn't bring it back ... add a feature that I can click on the subtitle and pull it vertically only on the screen, wherever I want to, with my mouse while it's reading."* A drag on the band moves it up or down only (every screen follows, the cursor shows ↕), kept in `~/.config/subtitle.json` as `ypos` (fraction of the screen height, −1 = `position`). A click never hides it; a **double-click** opens the answer box (was a single click, which also hid the band). A click on the blob's body brings the subtitle back while she reads; CC brings it back when it was on but hidden.

## The menu bar instead of the blob (v24–v26, 2.11.2026)
Marko: *"Let's forget the blob. Make a triangle when you are playing at the menu bar ... one is square to stop completely
and the triangle to pause"*, *"a third button ... 'Sub' ... by default, you are not showing me subtitles"*, *"The order is
triangle, square, and then sub."* While the voice reads, the menu bar shows **▶ ■ SUB** (MenuControls.swift): ▶ pauses
and plays on (orange while paused; while a reading is held by the microphone guard it is orange and reads anyway), ■ stops
completely, SUB turns the subtitles on and off (filled orange while on; `subtitles` in ~/.config/subtitle.json, off by
default since 2.11.2026). They go a moment after the reading ends. The blob no longer shows. v23: a GET /speaking poll that
never answered is dropped after 3 s (the copy running since login had stopped showing anything).
