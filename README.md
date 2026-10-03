# Claude to Marko voice

The settings of the **speaking subtitle**: while the computer speaks to Marko (MANTRA_VOICE, `POST /speak`),
every sentence is written across every screen as a film subtitle, the word being said lit in another colour.
The subtitle is drawn by the star (MANTRA_STAR `apps/voice.lua`, `VOICEBUBBLE`); this Swift window sets how it looks.

- **Letters**: size as a share of the screen's height (big − and +, and a slider), colour, bold
- **The word being said**: its colour (red by default, orange letters turning red) and an optional block behind it;
  earlier / later in milliseconds
- **Band**: how much of the grey band is seen and how grey; **where**: top, middle, bottom
- **Stays after the voice**: how long the last sentence remains, so PREVIOUS still works when he comes back

Every change is written to `~/.config/subtitle.json` and shown on the screens for four seconds
(`hs -c VOICEBUBBLE.test`). The − and + on the subtitle write the same file; this window follows it.

Build: `./build.sh` (swiftc, no Xcode, signed "Mantra Apps"). Opened from the star: Claude › Claude to Marko voice.

Marko, 3.10.2026: *"In the star menu you can call it Claude to Marko voice, and then I can adjust parameters of
this subtitle display"*; *"any settings are now Swift applications, and this is the rule."*
