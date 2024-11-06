#!/bin/sh
test -f webpng.dmg && rm webpng.dmg
create-dmg \
  --volname "WebPng Installer" \
  --volicon "./assets/logo.icns" \
  --window-pos 200 120 \
  --window-size 800 530 \
  --icon-size 130 \
  --text-size 14 \
  --icon "webpng.app" 260 250 \
  --hide-extension "webpng.app" \
  --app-drop-link 540 250 \
  --hdiutil-quiet \
  "build/macos/Build/Products/Release/webpng.dmg" \
  "build/macos/Build/Products/Release/webpng.app"