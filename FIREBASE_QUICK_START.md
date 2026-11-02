# Firebase Quick Start - Copy & Paste Commands

## Prerequisites Check
```bash
# Verify Flutter
flutter --version

# Verify Dart
dart --version

# Verify Android SDK
echo %ANDROID_SDK_ROOT%
```

---

## Step 1: Install CLI Tools

### Firebase CLI
```bash
npm install -g firebase-tools
firebase --version
```

### FlutterFire CLI
```bash
dart pub global activate flutterfire_cli
flutterfire --version
```

If `flutterfire` not found in PATH, use:
```bash
dart pub global run flutterfire_cli:flutterfire --version
```

---

## Step 2: Get Your Firebase Project ID

Visit [Firebase Console](https://console.firebase.google.com/) and get your Project ID.

Example: `app-discovery-abc123`

---

## Step 3: FlutterFire Configuration

Navigate to your Flutter project:
```bash
cd app_discovery
```

Run FlutterFire configure (replace with your Project ID):
```bash
flutterfire configure --project=YOUR_PROJECT_ID
```

Example:
```bash
flutterfire configure --project=app-discovery-abc123
```

**This will:**
1. Open browser for Google login
2. Register your Android app
3. Download `google-services.json`
4. Auto-generate `lib/services/firebase_options.dart`
5. Update Android build files

**Expected output:**
```
✓ Firebase configured successfully!
✓ google-services.json downloaded
✓ firebase_options.dart created
```

---

## Step 4: Verify Configuration

Check that these files exist:
```bash
# Google Services config
ls app_discovery/android/app/google-services.json

# Firebase options (auto-generated)
ls app_discovery/lib/services/firebase_options.dart
```

---

## Step 5: Update Flutter Dependencies

```bash
cd app_discovery
flutter clean
flutter pub get
```

---

## Step 6: Build and Test

### Debug Build
```bash
flutter build apk --debug
```

### Run on Emulator/Device
```bash
flutter run
```

**Expected console output:**
```
✓ Firebase initialized successfully
```

---

## Firebase Console Setup (Required)

After `flutterfire configure`, complete these in Firebase Console:

### 1. Enable Authentication
- Go: Firebase Console → Your Project → **Authentication**
- Click **Get Started**
- Enable **Email/Password**
- Save

### 2. Create Firestore Database
- Go: Firebase Console → **Firestore Database**
- Click **Create Database**
- Select **Start in test mode**
- Choose region: `us-central1` (or nearest)
- Click **Create**

### 3. Enable Cloud Storage
- Go: Firebase Console → **Storage**
- Click **Get Started**
- Choose region: `us-central1`
- Click **Done**

### 4. Apply Security Rules

#### Firestore Rules
Go: **Firestore Database** → **Rules** tab
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /posts/{postId} {
      allow read: if resource.data.isPublished == true;
      allow write: if request.auth != null;
    }
    match /categories/{categoryId} {
      allow read;
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /users/{userId}/favorites/{favoriteId} {
      allow read, write: if request.auth.uid == userId;
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```
Click **Publish**

#### Storage Rules
Go: **Storage** → **Rules** tab
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read;
    }
    match /{allPaths=**} {
      allow write: if request.auth != null;
    }
  }
}
```
Click **Publish**

---

## Troubleshooting One-Liners

```bash
# Check Flutter setup
flutter doctor

# Verify project structure
ls app_discovery/

# Check Android config
ls app_discovery/android/app/google-services.json

# Clean and reinstall
flutter clean && flutter pub get

# Analyze code
flutter analyze

# Test emulator connection
adb devices

# Watch logs while running
flutter run -v

# Kill stuck Gradle processes
taskkill /F /IM java.exe

# View Firebase options
type app_discovery\lib\services\firebase_options.dart
```

---

## Verify Firestore Access

Once app is running, create a test post in Firestore Console:

1. Go: **Firestore Database** → Start Collection
2. Collection ID: `posts`
3. Document ID: Auto (leave blank)
4. Add fields:
   ```
   title: "Test Post"
   shortDescription: "A test"
   description: "Full description"
   postType: "article"
   categoryId: "test"
   isPublished: true
   viewsCount: 0
   createdAt: (set to today)
   updatedAt: (set to today)
   publishedAt: (set to today)
   ```
5. Save

The app should be able to read this post if rules are correct.

---

## Environment Variables (Optional)

Create `.env` file for different Firebase projects:

```bash
# .env.development
FIREBASE_PROJECT_ID=app-discovery-dev

# .env.production
FIREBASE_PROJECT_ID=app-discovery-prod
```

Then run:
```bash
flutterfire configure --project=$FIREBASE_PROJECT_ID
```

---

## Next Command: Phase 3

Once Phase 2 is verified working:
```bash
flutter pub add provider
# Then proceed to Phase 3 setup
```

---

## Support

- Flutter Docs: https://flutter.dev
- Firebase Docs: https://firebase.google.com/docs
- FlutterFire: https://firebase.flutter.dev
- Community: https://stackoverflow.com (tag: flutter, firebase)
