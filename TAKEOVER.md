# TAKEOVER

**State (3.10.2026):** v2. The window writes `~/.config/subtitle.json`
(`size colour bold word wordbg offset band grey position linger`); the subtitle in MANTRA_STAR `apps/voice.lua`
reads it at each reading and at each preview. The word timings come from MANTRA_VOICE `GET /speaking`
(`pos`, seconds into the sentence; `words`, `[{s, e, t, d}]`).

**To continue:** edit `app/App.swift`, raise `VERSION` (whole numbers), `./build.sh`, quit and reopen the app.
A key added here must be read in `readConf()` in `apps/voice.lua` (it has the defaults too).
