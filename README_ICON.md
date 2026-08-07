# Keldim app icon

White graduation cap on the violet brand gradient (#7C3AED → #A855F7),
matching the login logo.

## What's here
```
master/
  app_icon_1024.png            ← main source (use with the tool below)
  adaptive_foreground_1024.png ← Android adaptive foreground (cap only)
  adaptive_background_1024.png ← Android adaptive background (gradient)
  playstore_512.png            ← Google Play listing icon
ios/
  Icon-1024.png                ← iOS App Store icon
android/res/
  mipmap-*/ic_launcher.png       ← ready-to-drop launcher icons (all densities)
  mipmap-*/ic_launcher_round.png ← round variant
  mipmap-anydpi-v26/*.xml        ← adaptive icon definitions (optional route)
flutter_launcher_icons.yaml    ← config for the automated tool
```

## Option A — automated (recommended, does Android + iOS + adaptive at once)
1. In your project create `assets/icon/` and copy into it:
   `master/app_icon_1024.png` and `master/adaptive_foreground_1024.png`.
2. Add the `flutter_launcher_icons:` block from `flutter_launcher_icons.yaml`
   into your `pubspec.yaml` (top level).
3. Run:
   ```bash
   flutter pub add dev:flutter_launcher_icons
   dart run flutter_launcher_icons
   ```
That's it — it overwrites all the mipmaps and the iOS asset catalog for you.

## Option B — fully manual (Android)
Copy each `android/res/mipmap-<density>/` PNG into your project's
`android/app/src/main/res/mipmap-<density>/`, overwriting the existing
`ic_launcher.png` (and `ic_launcher_round.png`). Densities map 1:1.
No pubspec changes needed. (The `mipmap-anydpi-v26/*.xml` files are optional —
include them only if you also add matching `ic_launcher_foreground` assets.)

## Option C — fully manual (iOS)
Open `ios/Runner/Assets.xcassets/AppIcon.appiconset` in Xcode and drop
`ios/Icon-1024.png` into the 1024 "App Store" slot (modern Xcode needs only
the single 1024 image). Or just use Option A, which fills iOS automatically.

After changing icons, do a clean rebuild:
```bash
flutter clean && flutter pub get && flutter run
```
