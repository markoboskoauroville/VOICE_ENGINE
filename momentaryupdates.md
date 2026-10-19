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

## 13.10.2026: no band behind the subtitle on the first screen
> "please remove background for subtitle from the first screen"

Asked which: "Big screen (2560 wide)", the main display with the menu bar. Status: built v7 13.10.2026: BAND ON THE
BIG SCREEN ON / OFF in the window (subtitle.json `bandmain`), set OFF; MANTRA_STAR voice.lua draws no band on the
main screen then (Hammerspoon restarted, pid 14192 → 18649). Marko to look: the overlay does not show in screencapture.

## 13.10.2026: the subtitle itself into Swift (v8)
> "We are quitting the Lua, no more Lua, only Swift" (Marko, 13.10.2026)

The speaking subtitle (MANTRA_STAR apps/voice.lua, VOICEBUBBLE) becomes the engine inside this app. **Status:** built v8
13.10.2026 (app/Subtitle.swift; AppKit life, the window on demand, no Dock icon). Checked by screenshot with
--test-subtitle: the MacBook's band with − + and PREVIOUS NEXT REPLAY CLOSE, the big screen letters only (bandmain off);
the settings window reopens. Not checked: a real reading with the word highlight (the voice server was down).
voice.lua steps aside while this app runs (MANTRA_STAR 3310386, at the next Hammerspoon restart). Marko to try.

## 19.10.2026: the voice blob (pause, cancel, start from the top, subtitles on/off), like Speechify's

> we need to improve interaction with the voice. After you finish your prompts and your processes in cloud code, there is battery speaking to me what happened, which is nice. But sometimes I want to stop her. So please open the blob which looks like speechify blob, and I can pause, I can cancel, and I can start from the top. Start from the top is circular arrow, cancel is x. Let's build that. So while she's speaking, I have the same blob as speechify. If you don't know how it looks, look at the desktop. I just took a screenshot of the blob itself, so you can copy the looks. Of course, blob can be moved by mouse, and then you need to remember the last position

> For some reason lately I don't see subtitles. But this blob can enable disable subtitles as well. Put this also as a feature.

**Status:** built 19.10.2026 (v10, app/Blob.swift). The blob, from his Speechify screenshot: a dark pill, grey round ✕ (cancel: /speak/stop, the subtitle goes too), the white dotted wave (moving while she speaks, flat dots while paused), CC (the subtitle on/off, kept in ~/.config/subtitle.json as `subtitles`), ↻ (from the top: /speak/top), the blue round pause/play (/speak/pause). Shown while the voice reads, gone a moment after; dragged by its body, its place kept (UserDefaults blobOrigin). Seen in screenshots: speaking (wave, ⏸), paused (dots, ▶; the voice's clock held), from the top (sentence 1, played on), subtitles off (no letters, CC dimmed), gone after the end. Why he did not see subtitles: the app was running (v9 since 06:00) and they showed, at the TOP, 3 % letters, no band on the big screen (his settings), easy to miss over an app. Marko to try the clicks and the drag.
