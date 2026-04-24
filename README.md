# CureConnect Smart Organizer

CureConnect is a production-oriented smart medication organizer system composed of:

- `flutter_app/`: a branded Flutter mobile application with clean architecture layers
- `firmware/`: MicroPython firmware for the ESP32 DevKit V4
- `firebase/`: Firestore and Realtime Database security rules
- `docs/`: backend schema and deployment notes
- `.github/workflows/`: release APK automation

## Brand Analysis

The uploaded CureConnect logo combines three strong visual signals that drive the UI:

- rounded hexagonal framing, which suggests safety, enclosure, and hardware
- dual curved `C` forms with thick softened geometry
- a cyan-to-mint medical gradient with a pulse line and network mesh

To stay faithful to the mark while honoring the requested black/blue/white direction, the app uses:

- base black: `#000000`
- bright medical blue: `#007BFF`
- pure white: `#FFFFFF`
- logo cyan accent: `#20C4D8`
- logo teal accent: `#0D8AA8`
- logo mint accent: `#7AD97A`

The splash, login, and dashboard reuse rounded-hex curves, gradient arcs, frosted glass cards, and high-contrast white typography so the product feels like an extension of the logo rather than a generic dashboard.

## System Overview

### Embedded Firmware

The ESP32 firmware:

- mounts the SD card
- loads `schedule.json`
- syncs time from DS1307 RTC and NTP
- monitors battery continuously
- triggers the continuous servo for drawer dispensing
- flashes blue LEDs and sounds the buzzer
- waits for IR confirmation
- posts dose telemetry to Firebase-compatible endpoints
- supports cloud remote-trigger commands
- keeps local fail-safe behavior even when Wi-Fi is unavailable

### Firebase

The backend uses a split model:

- Firestore for durable app data such as schedules and dose history
- Realtime Database for low-latency device state and remote commands

### Flutter App

The mobile app includes:

- branded splash and login flows
- schedule CRUD
- realtime activity logs
- live battery gauge and connectivity state
- remote drawer trigger
- clean architecture-inspired layout using `core`, `features`, `domain`, `data`, and `presentation`

## Project Structure

```text
CureConnect/
|- flutter_app/
|  |- lib/
|  |- assets/
|  `- pubspec.yaml
|- firmware/
|  |- main.py
|  `- schedule.json
|- firebase/
|  |- firestore.rules
|  `- database.rules.json
|- docs/
|  `- firebase_schema.md
`- .github/
   `- workflows/
      `- build-release-apk.yml
```

## Flutter Setup

1. Install Flutter stable and Android SDK.
2. If the Android wrapper has not been generated yet on your machine, run this first inside `flutter_app/`:

```bash
flutter create . --platforms=android
```

3. Install dependencies:

```bash
cd flutter_app
flutter pub get
```

4. Configure Firebase for Android with FlutterFire:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

5. Replace the placeholder values in `lib/firebase_options.dart` if you are not using FlutterFire generation.

## Build Signed Release APK

### Local Release Build

Create a keystore:

```bash
keytool -genkey -v -keystore android/app/cureconnect-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cureconnect
```

Create `flutter_app/android/key.properties`:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=cureconnect
storeFile=cureconnect-release.jks
```

Then build the signed release APK:

```bash
cd flutter_app
flutter build apk --release
```

Generated artifact:

- `flutter_app/build/app/outputs/flutter-apk/app-release.apk`

### GitHub Actions Release Build

The workflow at `.github/workflows/build-release-apk.yml` expects these repository secrets:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`

It bootstraps the Android wrapper if needed, decodes the keystore, writes `key.properties`, runs `flutter build apk --release`, and uploads the signed APK as an artifact.

## Firebase Security Deployment

Deploy the rules with:

```bash
firebase deploy --only firestore:rules,database
```

Schema details are documented in [firebase_schema.md](/C:/Users/moamen%20Amigo/Documents/Codex/2026-04-24/github-plugin-github-openai-curated-inspect/docs/firebase_schema.md).

## Firmware Deployment

1. Flash MicroPython to the ESP32 DevKit V4.
2. Copy required support libraries to the board:
- `ssd1306.py`
- `sdcard.py`
- `urequests.py` if missing
3. Upload [main.py](/C:/Users/moamen%20Amigo/Documents/Codex/2026-04-24/github-plugin-github-openai-curated-inspect/firmware/main.py) and [schedule.json](/C:/Users/moamen%20Amigo/Documents/Codex/2026-04-24/github-plugin-github-openai-curated-inspect/firmware/schedule.json).
4. Update Wi-Fi and Firebase credentials in `main.py`.

## Notes

- The Flutter app contains placeholder Firebase values and must be connected to a real Firebase project before release.
- The native Android wrapper was not generated in this workspace because Flutter is not installed here. Run `flutter create . --platforms=android` once on a Flutter-enabled machine before building.
- The firmware is written for MicroPython and tuned for fail-safe local execution first, cloud sync second.
- In production, firmware-originated writes should be authenticated through a device token or a trusted ingest endpoint such as a Firebase Cloud Function.
- I did not build the APK in this workspace because Flutter, Android signing assets, and Firebase project credentials are not present here.
