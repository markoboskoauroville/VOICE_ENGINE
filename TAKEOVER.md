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
