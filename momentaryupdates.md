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

## 19.10.2026: the blob's wave is the voice's own FFT bands

> Please fix the Visualization on the reader. What's going on is that um It's just animation, it should react to the voice itself. So make uh Like divided by bands. Like visualization of the FFT, FFT analyzation. In these vertical lines.

> please, I have a professional meter. We together we develop it, and you can just take the code from that audio tools. Spectral analyzes mantra same as flux and find a suitable meter from there and just attach it to this blob. Please

**Status:** built 19.10.2026 (v11): the 11 bars are MANTRA_VOICE's GET /speak/bands through SPECTRAL_ANALYZER's
SPECTRUM ballistics (4.5 dB/oct tilt, attack at once, 30 dB/s release), asked 24 times a second; seen moving in screenshots.

## 19.10.2026: a setup gear on the blob

> please also add to the blob setup gear icon

**Status:** built 19.10.2026 (v11): ⚙ between CC and ↻ opens the settings window; the blob is 248 wide.

## 19.10.2026: no held peaks on the blob

> looking good, but don't hold the peaks, please

**Status:** built 19.10.2026 (v11): the peak dots are gone, the bars keep the analyzer's attack and release

## 19.10.2026: only the upper half

> this is good, but I want to bring it a step forward. Only upper half you need to show me

**Status:** built 19.10.2026 (v11): the bars stand on one line 9 points up and rise, as a spectrum does; seen in screenshots.

## 19.10.2026: fall off much faster

> this is almost good, but make it fall off much faster

**Status:** built 19.10.2026 (v11): the release is the analyzer's VERY FAST, 120 dB/s (was MEDIUM, 30)

## 19.10.2026: the blob can be turned off in the settings
> please in the voice reader for Claude in the settings add a setting to turn it off so it doesn't reappear again

Status: built v12 19.10.2026: THE BLOB WHILE SHE READS, ON / OFF, second row of the settings window (subtitle.json `blob`,
ON by default); OFF hides it at once and it does not come back with the next reading. Seen in a screenshot: the row and
v12 (old pid 64349 → new 10240). Marko to tap OFF.

## 19.10.2026: no off switch for the blob; the voice engine ON / OFF instead
> I don't want to off switch to the blob. Blob always needs to be on. I want at the top of settings when the blob appears there is a setting icon, and then in that window at the top voice engine off on off so I can turn it off

Status: built v13 19.10.2026: the v12 blob row is gone (the blob is always on). THE VOICE ENGINE, the first row, has ON / OFF:
OFF stops the reading now (/speak/stop) and writes `voice: false` to subtitle.json; the Stop hook subtitle_answer.py (hub)
reads nothing then. Checked: the row in a screenshot (v13, old pid 10240 → 10865); the hook's switch read False after OFF,
True after ON. Marko to tap OFF and see that the next answer is not read.

## 19.10.2026: ✕ at the far upper-right of every window
> please unify the position of the close button on every application. It's far upper right corner. There is X to close the dialog in every dialog, same

Status: built v14 19.10.2026: ✕ at the right end of THE VOICE ENGINE's ON / OFF line in the settings window (closes the
window, the app stays on), and ✕ at the upper-right of the Answer Claude box (closes it, nothing sent). Checked: the
settings window captured by itself, v14 and the ✕ (the app was not running at the time, started: pid 22039). The
answer box's ✕ is not seen yet (it opens only from a click on the subtitle).

## 28.10.2026

"please, when you read anything from this chat or anything using this local voice engine, you need to give me Blob to control this voice. Blob has a simple user interface: one arrow, a round arrow going backwards. It means repeat, repeat from the top. It has pause, and it has X to stop talking, and that's it. It's similar to this Blob from Speechify, which I'm using, and you can see the screenshot on the desktop from it right now. That's it"

"please read me the workflow aloud and with the blob for controlling the voice on voice engine, please"

"and you need to discretely display it on the bottom of the screen every time the voice is read"

"please include the voice engine just at the top of the user interface. I want to be aware of what kind of engine is used for voice. We have API to Speechify. Then you need to put Speechify API. I have a local voice engine. Then you put Local Voice Engine. If you have something more, let me know"

"it's at the top of this cloud in the marko voice user interface. Put all the engines, and the ones which are not active are grayed out. The ones which are active are in the green color"

"between two voice engines, put one pipe so I know where one ends and the other begins"

"Pipe should not be grey. Should be yellow"

## 31.10.2026: the label over the subtitle, the BenQ without its band

> First, please fix my voice blob. Whatever is written atop of the voice blob, now it's written Speechify API batteries. It's written over subtitles. And on the BenQ screen under subtitles I don't have grey background. What's going on? Why left and right screen are different? I don't understand this. Please make them look the same. And that's it. Fix my... How we call this application? Voice application.

- The engine label is drawn over the subtitle: never overlap. **Status:** done v16: the name under the pill
- The BenQ without its band: both the same. **Status:** done: "BAND ON THE BIG SCREEN" (bandmain, off since 13.10.2026) switched ON in ~/.config/subtitle.json; seen on both screens
