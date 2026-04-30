# CureConnect – Build Setup Guide

## GitHub Actions: Required Secrets

Go to your repository → **Settings → Secrets and variables → Actions** and add:

### Firebase (required for the app to connect to Firebase at runtime)

| Secret | Description |
|---|---|
| `GOOGLE_SERVICES_JSON` | Full contents of your `google-services.json` from Firebase Console |

To get `google-services.json`:
1. Open [Firebase Console](https://console.firebase.google.com)
2. Select your project → Project Settings → Your apps → Android app (`com.cureconnect.app`)
3. Download `google-services.json` and paste its full text as the secret value

### APK Signing (optional — needed for signed release APK)

| Secret | Description |
|---|---|
| `KEYSTORE_BASE64` | Base64-encoded `.jks` keystore file: `base64 -w 0 release.jks` |
| `KEY_ALIAS` | Alias used when creating the keystore |
| `KEY_PASSWORD` | Password for the key |
| `STORE_PASSWORD` | Password for the keystore |

If these are not set, the CI will still build an **unsigned** release APK (suitable for testing).

---

## Local Development Setup

1. Copy your real `google-services.json` into `flutter_app/android/app/google-services.json`
2. Run `flutter pub get` inside `flutter_app/`
3. Run `flutter build apk --debug` or `flutter build apk --release`

> **Note:** `flutter_app/lib/firebase_options.dart` contains placeholder values.  
> Replace them with your actual Firebase project values from the Firebase Console.

---

## CI/CD

The workflow at `.github/workflows/build_apk.yml` will:
- Trigger on every push to `main`/`master` and on pull requests
- Build both **debug** and **release** APKs
- Upload them as downloadable GitHub Actions artifacts (retained 14 days)
