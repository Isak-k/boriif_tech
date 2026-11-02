# How to Build APK for Android - Quick Start Guide

## ✅ Current Status
- **Code**: Production ready (0 compilation errors)
- **Build**: Ready to generate APK
- **Features**: 100% complete

---

## Prerequisites

### Required
- Flutter SDK 3.24.0+
- Android SDK (API 21+)
- Java JDK 11+
- 4GB+ free disk space

### For Play Store
- Google Play Developer Account ($25 one-time)
- Keystore file (for signing)

---

## Step-by-Step Build Guide

### Step 1: Clean & Prepare
```bash
cd app_discovery
flutter clean
flutter pub get
```

### Step 2: Build Debug APK (Testing)
```bash
flutter build apk
```
**Output**: `build/app/outputs/apk/debug/app-debug.apk` (~50MB)

**To install on device**:
```bash
flutter install
# or
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

### Step 3: Build Release APK (Production)
```bash
flutter build apk --release
```
**Output**: `build/app/outputs/apk/release/app-release.apk` (~30MB)

### Step 4: Build App Bundle (Play Store)
```bash
flutter build appbundle --release
```
**Output**: `build/app/outputs/bundle/release/app-release.aab`

---

## APK Configuration

### Before Building - Update Package ID

**Current**: `com.example.app_discovery`  
**Change to**: Your company package (e.g., `com.yourcompany.appdiscovery`)

**File**: `android/app/build.gradle.kts`
```kotlin
namespace = "com.yourcompany.appdiscovery"
```

---

## For Play Store Submission

### Step 1: Create Keystore
```bash
keytool -genkey -v -keystore ~/app-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload-key
```
**Save the password!**

### Step 2: Configure Signing
**File**: `android/key.properties`
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload-key
storeFile=../app-release-key.jks
```

### Step 3: Configure build.gradle.kts
**File**: `android/app/build.gradle.kts`
```kotlin
// At top:
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
keystoreProperties.load(new FileInputStream(keystorePropertiesFile))

// In android block:
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile file(keystoreProperties['storeFile'])
        storePassword keystoreProperties['storePassword']
    }
}

// In buildTypes:
buildTypes {
    release {
        signingConfig signingConfigs.release
        shrinkResources true
        minifyEnabled true
    }
}
```

### Step 4: Build for Play Store
```bash
flutter build appbundle --release
```

### Step 5: Upload to Play Store
1. Go to https://play.google.com/console
2. Create new app
3. Upload `app-release.aab`
4. Fill in app details (screenshots, description)
5. Review and publish

---

## Build Troubleshooting

### Issue: "Gradle task assembleRelease failed"
**Solution**: Run on macOS/Linux or use WSL2

### Issue: "Could not close incremental caches"
**Solution**: Clear gradle cache
```bash
rm -rf ~/.gradle
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: "SDK version mismatch"
**Solution**: Update Android SDK
```bash
sdkmanager "platforms;android-34"
sdkmanager "build-tools;34.0.0"
```

### Issue: "Out of memory"
**Solution**: Increase Java heap
```bash
export _JAVA_OPTIONS="-Xmx4096m"
flutter build apk --release
```

---

## File Sizes

| Build | Size | Purpose |
|-------|------|---------|
| Debug APK | 50-60 MB | Development/Testing |
| Release APK | 25-35 MB | Direct distribution |
| App Bundle | 20-25 MB | Play Store |

---

## Testing Before Release

### On Device (Debug)
```bash
flutter run --release
```

### Check Functionality
- [ ] Login works
- [ ] Browse posts
- [ ] Admin features
- [ ] Image uploads
- [ ] Language switching
- [ ] Theme switching
- [ ] Share/Rate features
- [ ] Network errors handled
- [ ] Empty states show
- [ ] Offline gracefully handled

---

## Play Store Release Checklist

- [ ] App ID updated (`com.yourcompany.appdiscovery`)
- [ ] App name set
- [ ] App description complete
- [ ] Screenshots added (4-6 per orientation)
- [ ] Feature graphic added (1024x500)
- [ ] Icon added (512x512)
- [ ] Privacy policy URL provided
- [ ] Content rating questionnaire completed
- [ ] Target audience selected
- [ ] App signing configured
- [ ] Version code incremented (starts at 1)
- [ ] Version name set (e.g., "1.0.0")
- [ ] Minimum Android version confirmed (API 21+)
- [ ] Permissions reviewed (see AndroidManifest.xml)

---

## First Release Flow

1. **Build Release APK**
   ```bash
   flutter build apk --release
   ```

2. **Test on Device**
   ```bash
   adb install -r build/app/outputs/apk/release/app-release.apk
   ```

3. **Verify Features** (See checklist above)

4. **Build App Bundle for Play Store**
   ```bash
   flutter build appbundle --release
   ```

5. **Create Play Store Listing**
   - Add screenshots
   - Write description
   - Set pricing (free)

6. **Upload & Review**
   - Submit app bundle
   - Wait for review (24-48 hours)
   - Address any review issues

7. **Publish**
   - Go live on Play Store
   - Monitor reviews and ratings

---

## Version Management

**Before each release**, update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`

---

## Post-Launch Monitoring

Monitor these metrics:
- Crash rate (Firebase Crashlytics)
- User reviews (Play Store)
- Download count
- Active installations
- Geographic distribution
- Device/OS breakdown

---

## Quick Commands Reference

```bash
# Development
flutter run
flutter run --release

# Build
flutter build apk
flutter build apk --release
flutter build appbundle --release

# Testing
flutter analyze
flutter test

# Clean
flutter clean
flutter pub get

# Device Management
adb devices
adb install -r app.apk
adb shell am start -n package/activity
```

---

## Useful Links

- [Flutter Build Documentation](https://flutter.dev/docs/deployment/android)
- [Play Store Console](https://play.google.com/console)
- [Android Security & Privacy](https://developer.android.com/privacy-and-security)
- [App Signing Guide](https://developer.android.com/studio/publish/app-signing)

---

## Support

For specific issues:
1. Check `APK_BUILD_FIXED.md` - Build error solutions
2. Check `FINAL_PROJECT_DELIVERY.md` - Configuration details
3. See `PHASE7_COMPLETE.md` - Feature documentation

---

**Status**: ✅ Ready to build and submit to Play Store
