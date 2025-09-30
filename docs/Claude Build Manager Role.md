# Claude Build Manager Role Documentation

## Overview
I am the designated Build Manager for the Infiniteer Flutter app. This document contains all procedures, file locations, and configurations needed to manage Android builds, web deployments, and app store submissions.

## Project Structure & Key Files

### Main Project Location
```
E:\projects\IFE\FlutterApp\
```

### Critical Build Files
- **pubspec.yaml** - App version management (`version: 1.0.0+X`)
- **android/app/build.gradle** - Android build configuration
- **android/local.properties** - Local SDK paths and version codes
- **android/key.properties** - Release signing configuration (contains keystore path)

### Security & Signing Files
```
E:\projects\IFE\Google_Keys\
├── infiniteer-release-key.jks          # Release keystore (CRITICAL - BACKUP!)
├── keystore_info.txt                   # Keystore details reference
└── generate_keystore.bat               # Keystore generation script
```

### Build Outputs
```
build\app\outputs\
├── flutter-apk\app-release.apk         # APK builds (testing)
├── bundle\release\app-release.aab      # App Bundle (Play Store)
└── web\                                # Web build output (production web app)
```

## Current Configuration

### App Identity
- **Package ID**: `com.infiniteer`
- **App Name**: Infiniteer
- **Current Version**: 1.0.0+7 (increment +1 for each build)

### Android Targets
- **Min SDK**: 26 (Android 8.0+)
- **Target SDK**: 35 (Android 15) - **LATEST GOOGLE REQUIREMENT**
- **Compile SDK**: 35
- **NDK Version**: 27.3.13750724

### NDK Configuration
```
# Custom NDK location (not default Android SDK)
E:\NDK\android-ndk-r27d-windows\android-ndk-r27d\
```

## Build Commands

### Standard Development Builds
```bash
# APK for device testing
flutter build apk

# Debug APK
flutter build apk --debug

# Clean before building (if issues)
flutter clean && flutter build apk
```

### Play Store Release Builds
```bash
# App Bundle (REQUIRED for Play Store)
flutter build appbundle --release

# Always increment version first in pubspec.yaml!
```

### Device Deployment
```bash
# Install via ADB (device must be connected)
"C:\Users\Lou\AppData\Local\Android\Sdk\platform-tools\adb.exe" install -r "build\app\outputs\flutter-apk\app-release.apk"

# Check connected devices
"C:\Users\Lou\AppData\Local\Android\Sdk\platform-tools\adb.exe" devices
```

## Web Production Builds

### Web Build Configuration
- **App Name**: Infiniteer Now (web version)
- **Deployment URL**: `https://infiniteer.com/app/`
- **Base HREF**: `/app/` (required for subdirectory hosting)
- **Web Mode Flag**: `WEB_APP_MODE=true` (enables web-specific features)

### Web Production Build Command
```bash
# Full production web build with all flags
flutter build web --release --web-renderer html --base-href "/app/" --dart-define=WEB_APP_MODE=true

# Output location
build\web\
```

### What WEB_APP_MODE Does
The `--dart-define=WEB_APP_MODE=true` flag enables:
- **Different catalog endpoint**: Uses `catalog_web` instead of `catalog` API endpoint
- **App title change**: Shows "Infiniteer Now" instead of "Infiniteer"
- **Web-specific optimizations**: Future web-only features and configurations

Defined in: `lib/services/secure_api_service.dart:10`

### Web Deployment Process
1. **Build production web app**:
   ```bash
   flutter build web --release --web-renderer html --base-href "/app/" --dart-define=WEB_APP_MODE=true
   ```

2. **Copy to web server**:
   ```bash
   xcopy build\web\* [server-path]\app\ /E /I /Y
   ```
   - `/E` - Copy all subdirectories including empty ones
   - `/I` - Assume destination is a directory
   - `/Y` - Suppress overwrite confirmation

3. **Verify deployment**:
   - Navigate to `https://infiniteer.com/app/`
   - App should load with "Infiniteer Now" title
   - Check browser console for any errors

### Web Build Output Contents
```
build\web\
├── index.html              # Main entry point (auto-served from /app/)
├── manifest.json           # PWA configuration
├── favicon.png             # Browser favicon
├── flutter.js              # Flutter bootstrap
├── main.dart.js            # Compiled app (~4MB)
├── icons\                  # App icons (192x192, 512x512)
├── splash\                 # Splash screens
├── assets\                 # All app assets
│   ├── animations\         # Lottie animations
│   ├── catalog\            # Story catalog JSON
│   ├── dictionaries\       # Spell check dictionary (181KB)
│   ├── fonts\              # Michroma font
│   ├── icons\              # IcoMoon icon font
│   └── images\             # App images
└── canvaskit\              # Flutter rendering engine
```

### Web Platform Differences
**Features NOT Available on Web:**
- In-app purchases (IAP disabled via `kIsWeb` checks)
- Native spell check visual feedback (engine works, no underlines)
- Native file system access
- Platform-specific plugins

**Web-Specific Behavior:**
- Image caching uses browser-native caching (not CachedNetworkImage)
- API calls to `catalog_web` endpoint when WEB_APP_MODE=true
- Title shows "Infiniteer Now" to differentiate from mobile apps

### Web Server Requirements
- **HTTPS required**: Flutter secure storage and PWA features need SSL
- **CORS configured**: Azure API must allow requests from `infiniteer.com`
- **Base path**: App must be accessible at `/app/` subdirectory
- **Index serving**: Web server must serve `index.html` for directory requests

### Testing Web Builds Locally
```bash
# Development build (localhost:7161 backend)
flutter build web --profile --web-renderer html

# Test with local server
cd build\web
python -m http.server 8000

# Access at: http://localhost:8000
```

## Version Management Procedure

### Before Every Build:
1. **Increment version** in `pubspec.yaml`: `version: 1.0.0+X` (X = X+1)
2. **Verify target SDK** = 35 (Google keeps changing requirements)
3. **Clean if needed**: `flutter clean` (for major changes)

### Build Sequence:
1. `flutter build appbundle --release`
2. Check output: `build\app\outputs\bundle\release\app-release.aab`
3. Upload to Google Play Console

## Release Signing Setup

### Keystore Configuration
- **Location**: `E:\projects\IFE\Google_Keys\infiniteer-release-key.jks`
- **Alias**: `infiniteer`
- **Password**: [STORED SECURELY - NOT IN THIS DOCUMENT]
- **Validity**: 10,000 days

### Gradle Configuration Files
```
android/key.properties:
storePassword=[PASSWORD]
keyPassword=[PASSWORD]
keyAlias=infiniteer
storeFile=E:\\projects\\IFE\\Google_Keys\\infiniteer-release-key.jks
```

## Google Play Store Requirements

### Latest Google Requirements (as of build 7):
- ✅ **Target SDK 35** (Android 15) - CRITICAL
- ✅ **App Bundle format** (.aab, not .apk)
- ✅ **Release signing** (not debug)
- ✅ **Package name**: `com.infiniteer`

### Upload Process:
1. Build: `flutter build appbundle --release`
2. Upload: `build\app\outputs\bundle\release\app-release.aab`
3. Google Play will handle final signing via Play App Signing

## Dependencies & Plugins

### Key Flutter Dependencies:
- `auto_size_text: ^3.0.0`
- `flutter_secure_storage: ^9.2.2`
- `lottie: ^3.1.2`
- `in_app_purchase: ^3.1.13`
- `flutter_launcher_icons: ^0.13.1`
- `flutter_native_splash: ^2.4.1`

### Custom Assets:
- **Icons**: `assets/icons/icomoon.ttf`
- **Fonts**: `assets/fonts/Michroma-Regular.ttf`
- **Images**: `assets/images/infiniteer_app_logo.png`
- **Animations**: `assets/animations/`

## Common Issues & Solutions

### Build Failures:
1. **NDK missing**: Set `ndk.dir` in `android/local.properties`
2. **Version downgrade**: Increment version in `pubspec.yaml`
3. **API level errors**: Update target SDK to latest (currently 35)
4. **Plugin errors**: Run `flutter clean && flutter pub get`

### Play Store Upload Rejections:
1. **Debug mode error**: Ensure release signing is configured
2. **API level too low**: Update to target SDK 35+
3. **Wrong format**: Use `.aab` not `.apk`

### Gradle Issues:
1. **Heap size**: Configured to 2G in `gradle.properties`
2. **Daemon problems**: Run `./gradlew --stop` then rebuild
3. **Cache corruption**: Delete `~/.gradle/caches/` or `flutter clean`

## Quick Command Reference

```bash
# Version increment (manual edit)
# pubspec.yaml: version: 1.0.0+X → version: 1.0.0+X+1

# ===== ANDROID BUILDS =====
# Play Store build
flutter build appbundle --release

# Device testing build
flutter build apk

# Install on device
adb install -r app-release.apk

# Check devices
adb devices

# ===== WEB BUILDS =====
# Production web build (infiniteer.com/app/)
flutter build web --release --web-renderer html --base-href "/app/" --dart-define=WEB_APP_MODE=true

# Development web build
flutter build web --profile --web-renderer html

# ===== MAINTENANCE =====
# Clean everything
flutter clean

# Stop Gradle daemons
cd android && ./gradlew --stop
```

## File Backup Checklist

### CRITICAL Files to Backup:
- ✅ `E:\projects\IFE\Google_Keys\infiniteer-release-key.jks`
- ✅ `E:\projects\IFE\Google_Keys\keystore_info.txt`
- ✅ `android/key.properties`
- ✅ Entire project: `E:\projects\IFE\FlutterApp\`

### Nice to Have Backups:
- `android/local.properties` (for NDK path)
- Build artifacts (for rollback if needed)

## Current Status
- **Last Build**: Version 1.0.0+7
- **Target SDK**: 35 (Android 15) ✅
- **Play Store Status**: Ready for upload
- **Signing**: Fully configured with release keys
- **Build Pipeline**: Streamlined and functional

## Notes for Next Instance
- Google frequently changes API requirements - always check latest
- Keep keystore safe - losing it means new app identity required
- Version must always increment - never reuse build numbers
- Test on device before Play Store upload
- Monitor Google Play Console for new requirement changes

---

**Build Manager Role**: Handle all builds (Android, iOS, Web), version management, and deployment for Infiniteer app.

**Android Build Command**: `flutter build appbundle --release`
**Android Upload File**: `build\app\outputs\bundle\release\app-release.aab`

**Web Build Command**: `flutter build web --release --web-renderer html --base-href "/app/" --dart-define=WEB_APP_MODE=true`
**Web Upload Location**: `build\web\` → Copy to `infiniteer.com/app/`