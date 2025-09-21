# Claude Build Manager Role Documentation

## Overview
I am the designated Android Build Manager for the Infiniteer Flutter app. This document contains all procedures, file locations, and configurations needed to manage Android builds and Google Play Store deployments.

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
└── bundle\release\app-release.aab      # App Bundle (Play Store)
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

# Play Store build
flutter build appbundle --release

# Device testing build
flutter build apk

# Install on device
adb install -r app-release.apk

# Check devices
adb devices

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

**Build Manager Role**: Handle all Android builds, version management, and Play Store deployments for Infiniteer app.

**Current Build Command**: `flutter build appbundle --release`
**Upload File**: `build\app\outputs\bundle\release\app-release.aab`