#!/bin/sh
# build.sh: Voice Engine (Mantra).app (until v19 Claude to Marko Voice; v20 took in Voice of Claude), swiftc straight, no Xcode, signed "Mantra Apps" (MANTRA_MANIFEST mac-app-signing.md).
set -e
cd "$(dirname "$0")"
V=$(sed -n 's/^let VERSION = \([0-9]*\)/\1/p' app/App.swift)
APP="build/Voice Engine (Mantra).app"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
swiftc -O -swift-version 5 -parse-as-library -o "$APP/Contents/MacOS/VoiceEngine" app/*.swift 2>&1 | grep -v "warning:" || true
[ -x "$APP/Contents/MacOS/VoiceEngine" ] || { echo "the app did not build"; exit 1; }
cat > "$APP/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Voice Engine (Mantra)</string>
<key>CFBundleDisplayName</key><string>Voice Engine (Mantra)</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIdentifier</key><string>community.auroville.voiceengine</string>
<key>LSUIElement</key><true/>
<key>CFBundleExecutable</key><string>VoiceEngine</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>$V</string>
<key>CFBundleVersion</key><string>$V</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PL
mkdir -p "$APP/Contents/Resources"; cp icon/subtitle.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force -s "Mantra Apps" "$APP"
# the answer box, its own small AppKit app (the SwiftUI scene never opened a window when launched by a click)
A="build/Answer Claude (Mantra).app"; rm -rf "$A"; mkdir -p "$A/Contents/MacOS"
swiftc -O reply/main.swift -o "$A/Contents/MacOS/AnswerClaude" 2>&1 | grep -v "warning:" || true
cat > "$A/Contents/Info.plist" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Answer Claude (Mantra)</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundleIdentifier</key><string>community.auroville.answerclaude</string>
<key>CFBundleExecutable</key><string>AnswerClaude</string>
<key>CFBundleShortVersionString</key><string>$V</string>
<key>CFBundleVersion</key><string>$V</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSUIElement</key><true/>
</dict></plist>
PL
mkdir -p "$A/Contents/Resources"; cp icon/answer.icns "$A/Contents/Resources/AppIcon.icns"
codesign --force -s "Mantra Apps" "$A"
# MANTRA_MANIFEST swift-apps.md: both live in /Applications, their names ending in "(Mantra)"
for x in "$APP" "$A"; do rm -rf "/Applications/$(basename "$x")"; cp -R "$x" /Applications/; done
echo "built $APP (v$V) and $A, installed in /Applications"
