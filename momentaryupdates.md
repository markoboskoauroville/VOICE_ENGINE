# Momentary updates

## 13.10.2026: the subtitle closes 2 s after the voice
> "Speechify was working nice voice have to close subtitles on the screen after 2 s and it's done this default action for now can be changed in the Swift app"

Status: done the same day: STAYS AFTER THE VOICE defaults to 2 S (subtitle.json, the Swift app's default and its
choices 2 S / 30 S / 2 MIN / 10 MIN / FOREVER, voice.lua's default).

## 13.10.2026: choose the engine in the app
> "in the AppCloud to Mantra Voice, there must also be options for which engine to use. Now we can add the original Speechify engine to talk with me and another session live session on this computer is doing Swift-Lua to Swift conversion. Ask it to upgrade that app"

Status: built 13.10.2026 as v6 by "mantra: Lua to Swift". THE VOICE ENGINE is the first row of the window: CLONE or
SPEECHIFY (Beatrice), under CLONE every cloned voice from GET /voices, HEAR IT says one sentence through /speak.
A tap is POST /current (API.md); the row reads the live choice every 3 s, and says "VOICE IS OFF" when :8837 does
not answer (it never starts the voice). Checked: the row shows CLONE · GWYNETH and the 7 voices, as /voices says.
Marko to try: SPEECHIFY, HEAR IT, then back.
