# TAKEOVER

**State 8.11.2026 (night): v39** built by GitHub run 42530449181 green, installed (pid 79041); PauseSync now from the public repo VOICE_ENGINE_UNIVERSAL (submodule universal/).
**State 8.11.2026 (night): v38**: PAUSE / CONTINUE on the subtitle (AX id subtitle-pause), GitHub run 42528731599 green, installed, signed, running.
**State 8.11.2026: v37**: hard black shadow under every subtitle word (no blur, 7 % of the letter size, down-right; NSShadow offsets are in screen space, so the height is negative). Built by GitHub (run 42492245143, green), installed, signed Mantra Apps, running; seen in a screenshot on the MacBook screen.
**State 6.11.2026: v36**: no shortcut keys (HotKeys, PERMISSIONS removed), mouse only; STOP square on the subtitle. Installed and running. (v35: Space passes through): Space passes through (the voice pauses / plays on and the app in front gets the key; Esc, S still taken). Installed and running.

**State 5.11.2026: v32** (first GitHub Actions build): SUB comes and goes with ▶ ■ (Marko: "The play and stop buttons
should be gone at the same time"); measured: 3 menu-bar items while reading, 0 after. Install = download release
app.zip, replace /Applications/Voice Engine (Mantra).app, sign "Mantra Apps", `voicectl stop` / `voicectl start`.


**State (3.10.2026):** v3 (linger 0 = forever, the default: the subtitle stays until a click on its text). The window writes `~/.config/subtitle.json`
(`size colour bold word wordbg offset band grey position linger`); the subtitle in MANTRA_STAR `apps/voice.lua`
reads it at each reading and at each preview. The word timings come from MANTRA_VOICE `GET /speaking`
(`pos`, seconds into the sentence; `words`, `[{s, e, t, d}]`).

**To continue:** edit `app/App.swift`, raise `VERSION` (whole numbers), `./build.sh`, quit and reopen the app.
A key added here must be read in `readConf()` in `apps/voice.lua` (it has the defaults too).

**State (19.10.2026):** v11. The blob (`app/Blob.swift`) asks `GET /speak/bands` 24 times a second while shown and draws
`db` through `WaveView.take`: tilt 4.5 dB/oct about 1 kHz, attack at once, release 120 dB/s, height from -60 to -6 dB.
These constants are at the top of `WaveView`; Marko may still want the height changed after a long reading.

## v16, 31.10.2026

The engine name moved under the pill (it lay on the subtitle words); the band on the big screen (bandmain) switched back on, so the BenQ and the MacBook show the same grey band. Installed and relaunched (pid 97645 -> 36369, the first `open` after the copy failed with -600 and the second worked). Checked with a reading on both screens.

## v19, 31.10.2026

TOP on the settings window ON / OFF row (`TopWord` in app/App.swift, `onTop`), AX ids `top`, `close`. Answer Claude (reply/main.swift) has the first row ON OFF · ANSWER CLAUDE · TOP ✕ (rowWord, offPressed, topPressed/paintTop; `onTop` registered true so the box stays above everything by default). Relaunched with --login (pid 68778 -> 94423).

## 1.11.2026, v20: Voice Engine (Mantra)

- The app is `/Applications/Voice Engine (Mantra).app`, bundle `community.auroville.voiceengine`, executable `VoiceEngine`
  (was Claude to Marko Voice, `community.auroville.claudetomarkovoice`); Answer Claude (Mantra) unchanged.
- App.swift: `Switch` + `SwitchRow` (Voice of Claude v6's launchd start/stop and the three parts), `EngineRow` only picks
  the voice, `Settings` renamed throughout; `--on/--off/--status` in `Main.main`. The `voice` key of subtitle.json is no
  longer shown (it fed only subtitle_answer.py, out since 31.10.2026). A click on TOP / MIDDLE / BOTTOM sets `ypos` -1.
- The old two apps are in the Trash; the star row `claudevoice` opens Voice Engine (STAR_SWIFT c138a55), the row
  `voiceofclaude` is gone; MANTRA_VOICE voiced.py BLOB_APP points at Voice Engine (takes effect at voiced's next start).

## 1.11.2026, v21–v22: the held reading says why

- Blob.swift `showHeld(why)` / `hideHeld()`: a second panel under the blob (NoteView, NoteButton "READ ANYWAY", AX id
  `read-anyway`), as wide as its words (v22); fed by `/speaking`'s new `held` (Subtitle.swift `Speaking.held`).
- MANTRA_VOICE: MicGuard.LISTENERS = voice to text, speechify (substring of the app name from micbusy's third column);
  `why()`, `skip()` (READER.gen), POST /micguard/skip.
- Test without his voice: write a live pid into ~/Library/Application Support/Voice to Text (Mantra)/take-open, POST a
  short /speak, look, POST /micguard/skip, remove the file.
- Found on the way: a second voiced.py (nohup, not launchd) held :8837, so a kickstart -k left the new code unused.
  Check `pgrep -fl MANTRA_VOICE/voiced.py` shows ONE after any restart.

## 1.11.2026, evening: the old app was still running

The old Claude to Marko Voice (pid 54605, in the Trash) ran from 13:04 beside Voice Engine (13:13): two subtitles and
two blobs. It ignored `quit app id` (its bundle was gone) and was ended with kill. Voice Engine is now the only drawer:
MANTRA_STAR's Lua subtitle is removed and voiced.py no longer calls Hammerspoon. After a rebuild or a rename check
`pgrep -fl "ClaudeToMarkoVoice|VoiceEngine"` shows one.

## 4.11.2026 (v27–v29)
- v27: no Hammerspoon call in Answer Claude. v28: SUB is made at launch (`MenuControls.startSub`) and never removed;
  ▶ ■ only while she reads. v29: the subtitle's keys are two SF Symbols on the right, HIDE (captions.bubble.fill,
  /speak/close) and STOP (stop.fill, /speak/stop), Accessibility buttons; LW 24, KW 150; − + and PREVIOUS/NEXT/REPLAY gone.
- Voice paths outside :8837 (no subtitle, no ▶ ■ SUB): Elevate Media Monitor pop-up reader, Ableton Teacher (afplay),
  DaVinci Grading Tutorial, CQ MixPad Tutorial, Speechify Voice AI, the Nothing session. Marko's wish: one common way;
  his decision pending (SESSIONS/2026-11-04.md in the hub).
- v30 (session claude-code, built 4.11.2026 just before the toggle and numbered v30 too): the subtitle's STOP is
  `stopAndExit()` (Subtitle.swift): POST /speak/stop with a 1.5 s ceiling, `MenuControls.removeAll()` (▶ ■ SUB), then
  NSApp.terminate; applicationWillTerminate removes the items as well. Tested by AXPress on the subtitle's Stop (label
  "Stop", capitalised): process and SUB gone. Since v31 the quit also stops the voice server.
- v30: the play button is a toggle (pause.fill white while playing, play.fill orange while paused/held).
- v31 ONE APP: class Owner (App.swift) starts com.mantra.voiced at launch, stops it in applicationWillTerminate (Switch.stopNow),
  quits the app 8 s after the server is gone. LSUIElement. voicectl start/stop open/quit the app. PARTS patterns and
  pkill are anchored `^/[^ ]*python3[.0-9]* /[^ ]*/MANTRA_VOICE/...` (never a shell that mentions the file).
  Test clicks: a CGEvent click tool (Macro Recorder's `macro do Click` hung on the menu bar); window checks by CGWindowList.

## 5.11.2026: v33–v34, keys while she reads
app/HotKeys.swift: a session CGEventTap, live only while ▶ ■ SUB stand (MenuControls make/remove; re-tried every poll).
Esc 53 → stop, Space 49 → pause/play, S 1 → SUB; taken only bare (no ⌘⌥⌃⇧, no repeats). Needs Accessibility:
PERMISSIONS (amber, first row) calls AXIsProcessTrustedWithOptions(prompt) and opens the Settings page (v34). Granted by
Marko 5.11.2026 17:02; the app needed one restart before AXIsProcessTrusted turned true. Tested with real key codes.


## From the former README (9.11.2026)

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

**No keys (v36, 6.11.2026):** Marko: *"remove any shortcut keys ... It doesn't use Keyboard to be controlled, only the mouse."* Esc / Space / S (v33–v35) and the PERMISSIONS word are gone; the voice is controlled only by the mouse: ▶ ■ SUB in the menu bar, and HIDE and STOP (square) on the right of the subtitle.

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
