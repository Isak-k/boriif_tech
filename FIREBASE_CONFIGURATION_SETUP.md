# Firebase Configuration for borif-tech Project

## Your Firebase Project Details

**Project ID**: `borif-tech`
**Auth Domain**: `borif-tech.firebaseapp.com`
**Database URL**: `https://borif-tech-default-rtdb.firebaseio.com`
**Storage Bucket**: `borif-tech.firebasestorage.app`
**Messaging Sender ID**: `224058604407`
**App ID (Web)**: `1:224058604407:web:8110dd505f2da044267f72`

---

## Next Steps: Complete Android Registration

Your Firebase credentials have been added to `lib/services/firebase_options.dart`. However, to complete Android integration, you need to:

### Step 1: Download google-services.json

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **borif-tech**
3. Click the settings icon (⚙️) → **Project Settings**
4. Go to **Service Accounts** tab
5. Click **Google Services** button at bottom
6. Select **Android** platform
7. Enter Android package name: `com.example.app_discovery`
8. Enter SHA-1 certificate fingerprint (see below)
9. Click **Register app**
10. Download `google-services.json`
11. Save to: `app_discovery/android/app/google-services.json`

### Step 2: Get Your SHA-1 Certificate Fingerprint

Run this command to get your debug certificate fingerprint:

**Windows (PowerShell):**
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Mac/Linux:**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line starting with `SHA1:` - copy the fingerprint value.

### Step 3: Enable Required Firebase Services

In Firebase Console for **borif-tech** project:

1. **Authentication**
   - Go: Authentication → Get Started
   - Enable: Email/Password
   - Save

2. **Firestore Database**
   - Go: Firestore Database → Create Database
   - Start in: Test mode
   - Region: us-central1
   - Create

3. **Cloud Storage**
   - Go: Storage → Get Started
   - Region: us-central1
   - Done

### Step 4: Apply Security Rules

#### Firestore Rules
Go: **Firestore Database** → **Rules** tab

Replace with:
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

Replace with:
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

## Verify Configuration

Once you've downloaded `google-services.json` and placed it in `android/app/`:

```bash
cd app_discovery

# Verify file exists
ls android/app/google-services.json

# Get dependencies
flutter pub get

# Check diagnostics
flutter analyze

# Build and test
flutter run
```

Expected output:
```
✓ Firebase initialized successfully
```

---

## File Locations

| File | Location | Source |
|------|----------|--------|
| google-services.json | `app_discovery/android/app/` | Firebase Console |
| firebase_options.dart | `app_discovery/lib/services/` | ✅ Already updated |
| pubspec.yaml | `app_discovery/` | ✅ Already updated |

---

## Troubleshooting

### google-services.json Not Found
- Verify download from Firebase Console
- Verify file is in correct location: `android/app/google-services.json`
- File should be ~2KB JSON file

### SHA-1 Certificate Error
- Run keytool command above to get your SHA-1
- Make sure you use debug.keystore (not release)
- Add to Firebase Console before downloading google-services.json

### Firebase Initialization Error
- Verify internet connection
- Check google-services.json is valid JSON
- Verify project ID matches: `borif-tech`
- Check that Firebase services are enabled in console

### Firestore Permission Denied
- Verify security rules are applied (published)
- Check that Firestore database is created
- For reads: posts must have `isPublished: true`

---

## Next: Create Sample Data

Once Firebase is connected and working:

### Create Categories
In Firebase Console → **Firestore Database**:
1. Create Collection: `categories`
2. Add documents:
   - Development
   - Design
   - Technology
   - Business
   - Marketing
   - Education

### Create Sample Post
1. Create Collection: `posts`
2. Add document with:
   ```
   title: "Getting Started"
   shortDescription: "Learn the basics"
   description: "Full guide..."
   isPublished: true
   postType: "article"
   categoryId: "development-doc-id"
   createdAt: (today)
   updatedAt: (today)
   publishedAt: (today)
   viewsCount: 0
   ```

---

## Ready to Test

Once `google-services.json` is in place and rules are applied:

```bash
flutter clean
flutter pub get
flutter run
```

The app should:
- Initialize Firebase successfully
- Connect to your Firestore database
- Read published posts
- Upload images to Cloud Storage

---

## Quick Checklist

- [ ] Firebase Console project: **borif-tech** ✅ (identified)
- [ ] SHA-1 fingerprint obtained (keytool command above)
- [ ] Android app registered in Firebase Console
- [ ] `google-services.json` downloaded and placed in `android/app/`
- [ ] Authentication enabled
- [ ] Firestore Database created (test mode)
- [ ] Cloud Storage enabled
- [ ] Firestore security rules applied
- [ ] Storage security rules applied
- [ ] `flutter run` launches without Firebase errors
- [ ] Console shows: `✓ Firebase initialized successfully`

---

## Project Information

**Firebase Project**: borif-tech
**Flutter App Package**: com.example.app_discovery
**Status**: Ready for Android registration and google-services.json download

Once you download `google-services.json` and complete the Firebase Console setup, your app will be fully connected to Firebase.

---

**Proceed with downloading `google-services.json` and applying security rules, then run `flutter run` to test the connection.**
