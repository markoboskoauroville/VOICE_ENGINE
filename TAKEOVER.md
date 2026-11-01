# TAKEOVER

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
