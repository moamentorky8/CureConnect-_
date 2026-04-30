# CureConnect APK Build Setup Guide

## Important: This guide helps you set up your signing credentials locally

### Step 1: Generate Android Keystore

Run this command **on your machine** (not in this repo):

```bash
keytool -genkey -v -keystore cureconnect-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias cureconnect_key
```

When prompted, enter:
- **Keystore Password**: Choose a strong password (e.g., `MyStrongPass2024!`)
- **Key Password**: Can be the same as keystore password
- **First and Last Name**: Your name or company
- **Organizational Unit**: Mobile Team
- **Organization**: CureConnect
- **City/Locality**: Your city
- **State/Province**: Your state
- **Country Code**: Your country code (e.g., US, EG)

This creates: `cureconnect-release.jks`

---

### Step 2: Encode Keystore to Base64

```bash
base64 cureconnect-release.jks > keystore_base64.txt
```

Copy the entire contents of `keystore_base64.txt`

---

### Step 3: Add GitHub Secrets

Go to: https://github.com/moamentorky8/application/settings/secrets/actions

Click **"New repository secret"** for each:

| Secret Name | Value |
|-------------|-------|
| `ANDROID_KEYSTORE_BASE64` | Contents of `keystore_base64.txt` |
| `ANDROID_STORE_PASSWORD` | Your keystore password |
| `ANDROID_KEY_PASSWORD` | Your key password |
| `ANDROID_KEY_ALIAS` | `cureconnect_key` |
| `GOOGLE_SERVICES_JSON_BASE64` | Base64 of your `google-services.json` |

---

### Step 4: Get Google Services JSON

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** → **General** tab
4. Scroll down and download `google-services.json` for Android
5. Encode it:
   ```bash
   base64 google-services.json > google_services_base64.txt
   ```
6. Add as secret: `GOOGLE_SERVICES_JSON_BASE64` with the contents

---

### Step 5: Trigger Build

Once all secrets are added:
1. Go to https://github.com/moamentorky8/application/actions
2. Click **"Build Release APK"** workflow
3. Click **Run workflow** → **Run workflow**
4. Wait for the build to complete
5. Download APK from the Release page

---

## Security Best Practices

⚠️ **NEVER commit these files to git:**
- `cureconnect-release.jks` (already in `.gitignore`)
- `google-services.json` (already in `.gitignore`)
- `key.properties` (already in `.gitignore`)

⚠️ **NEVER share these secrets:**
- Keep your keystore password private
- Store credentials in a secure password manager
- Only add secrets to GitHub, never commit them

✅ **Backup your keystore:**
- Keep `cureconnect-release.jks` and passwords safe
- If lost, you cannot update your app on Google Play Store
- Recommended: Store in encrypted cloud storage or 1Password

---

## Troubleshooting

### "Manifest merger failed"
- Ensure `GOOGLE_SERVICES_JSON_BASE64` secret is set correctly
- Verify it's properly base64 encoded

### "Build failed with exit code 1"
- Check all 5 secrets are added
- Verify none of the secrets are truncated
- Check build logs in Actions tab

### "Keystore was tampered"
- Regenerate the keystore
- Re-encode to base64
- Update the secret

