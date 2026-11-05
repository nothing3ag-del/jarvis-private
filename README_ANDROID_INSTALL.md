# 🚀 JARVIS PRO (हिंदी + इंग्लिश) — Android App Package for Topg

This archive contains the complete **JARVIS PRO** Android project plus an **Instant Android Web-App** you can launch on your phone immediately.

---

## ⚡ OPTION 1: Run Immediately on Your Android Phone (Zero Compiling)
1. Extract this `.zip` file on your Android phone.
2. Open `instant_android_webapp/index.html` in **Chrome on Android**.
3. Tap the Chrome menu (`⋮`) -> **"Add to Home screen"**.
4. Launch **JARVIS PRO** from your home screen! It features the 3D holographic head, lip-sync, particle burst animations, Hindi + English voice recognition, and Android `intent://` deep links to launch Spotify directly.

---

## ☁️ OPTION 2: Build the Native `.APK` for Free in the Cloud (No PC Setup Needed)
We included `.github/workflows/build_apk.yml` so GitHub's servers will build the native Flutter + Kotlin `.apk` for you automatically:
1. Create a free repository on [GitHub](https://github.com/new) and upload the contents of this zip.
2. Click the **Actions** tab in your GitHub repository -> Select **Build JARVIS PRO Android APK** -> Click **Run workflow**.
3. In ~3 minutes, download **`JarvisPro-Topg-Release-APK.zip`** from the Artifacts section and install `app-release.apk` on your Android phone!

---

## 💻 OPTION 3: Build Locally on Windows / Mac / Linux
If you have Flutter & Android SDK installed on your computer:
- **Windows:** Double-click `build_android_apk.bat`
- **Mac / Linux:** Run `chmod +x build_android_apk.sh && ./build_android_apk.sh`
- Install the generated APK from `build/app/outputs/flutter-apk/app-release.apk`.

### Enabling API-Free Music Control on Android:
Once installed, go to **Android Settings -> Accessibility -> Installed Services -> JARVIS PRO Music Controller** and toggle it **ON** so Jarvis can control Spotify, Gaana, JioSaavn, and YouTube Music offline without API keys.
