# Complete Firebase Setup - 3 Steps

Your Firebase project **borif-tech** has been identified. Complete these final steps:

---

## ✅ Step 1: Download google-services.json (5 minutes)

### From Firebase Console:

1. Go: https://console.firebase.google.com/
2. Select: **borif-tech** project
3. Click settings icon (⚙️) → **Project Settings**
4. Tab: **Service Accounts**
5. Button: **Google Services** (at bottom)
6. Platform: Select **Android**
7. Package name: `com.example.app_discovery`
8. SHA-1: Get from below ⬇️

### Get Your SHA-1 (Windows PowerShell):

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**Find the line**: `SHA1: XX:XX:XX:...`  
Copy the fingerprint value (without "SHA1: " prefix)

### Complete Registration:

8. Enter SHA-1 in Firebase Console
9. Click **Register app**
10. Click **Download google-services.json**
11. Save file to: `app_discovery/android/app/google-services.json`

✅ **Check**: File exists at `app_discovery/android/app/google-services.json`

---

## ✅ Step 2: Enable Firebase Services (5 minutes)

### In Firebase Console (borif-tech project):

#### Authentication
- Go: **Authentication** → Get Started
- Provider: Email/Password → Enable → Save

#### Firestore Database
- Go: **Firestore Database** → Create Database
- Start mode: **Test mode**
- Region: **us-central1**
- Create

#### Cloud Storage
- Go: **Storage** → Get Started
- Region: **us-central1**
- Done

✅ **Check**: All three are enabled/created in Firebase Console

---

## ✅ Step 3: Apply Security Rules (5 minutes)

### Firestore Rules

Go: **Firestore Database** → **Rules** tab

Replace entire content with:
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

Click: **Publish**

### Storage Rules

Go: **Storage** → **Rules** tab

Replace entire content with:
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

Click: **Publish**

✅ **Check**: Both rule sets published (check timestamps updated)

---

## ✅ Test Connection (10 minutes)

### Build and Run:

```bash
cd app_discovery
flutter clean
flutter pub get
flutter run
```

### Expected Output:

Console should show:
```
✓ Firebase initialized successfully
```

### No Errors:
- No "Firebase initialization failed" errors
- No "Permission denied" errors
- App launches successfully

✅ **Success**: Firebase is connected!

---

## 📋 Quick Checklist

- [ ] SHA-1 fingerprint obtained (keytool command)
- [ ] Android app registered in Firebase
- [ ] `google-services.json` downloaded
- [ ] File placed at: `app_discovery/android/app/google-services.json`
- [ ] Authentication enabled
- [ ] Firestore Database created (test mode)
- [ ] Cloud Storage enabled
- [ ] Firestore rules published
- [ ] Storage rules published
- [ ] `flutter run` succeeds
- [ ] Console shows Firebase initialized ✓

---

## 🎯 After Successful Connection

Once Firebase is working:

### Create Sample Data (Optional)

**Categories** in Firestore:
1. Go: Firestore Database → Start Collection
2. Collection ID: `categories`
3. Add documents: Development, Design, Technology, Business, Marketing, Education

**Sample Post**:
1. Go: Firestore Database → posts collection
2. Add document with:
   - `title`: "Getting Started"
   - `shortDescription`: "Learn Flutter"
   - `description`: "Complete guide"
   - `postType`: "article"
   - `categoryId`: "(one of your category IDs)"
   - `isPublished`: true
   - `createdAt`: today
   - `updatedAt`: today
   - `publishedAt`: today
   - `viewsCount`: 0

---

## ⚠️ If Issues Occur

### Firebase Initialization Failed
1. Check internet connection
2. Verify `google-services.json` is valid JSON (not corrupted)
3. Verify file location: `android/app/google-services.json`
4. Check project ID in file matches: `borif-tech`

### SHA-1 Certificate Error
1. Make sure you used the **debug** keystore
2. Make sure you copied the **SHA1** value (without "SHA1: " prefix)
3. Delete and re-register the Android app in Firebase

### Firestore Permission Denied
1. Verify security rules are published
2. Verify `isPublished: true` on posts
3. Verify user is authenticated (for write operations)

### File Not Found Errors
1. Run: `flutter clean`
2. Run: `flutter pub get`
3. Verify `google-services.json` exists at correct location
4. Verify pubspec.yaml has Firebase packages

---

## 🎊 Timeline

| Task | Time |
|------|------|
| Download google-services.json | 5 min |
| Enable Firebase services | 5 min |
| Apply security rules | 5 min |
| Test (`flutter run`) | 10 min |
| **Total** | **25 minutes** |

---

## Next: Phase 3

Once Firebase is successfully connected (console shows `✓ Firebase initialized successfully`):

**Phase 3** will add:
- State Management (Provider)
- UI ↔ Services integration
- Loading states
- Real-time updates
- Pagination

**Timeline**: 2-3 days

---

## Summary

**3 steps remaining:**
1. Download `google-services.json` (5 min)
2. Enable Firebase services (5 min)
3. Apply security rules (5 min)
4. Test with `flutter run` (10 min)

**Total: 25 minutes to Firebase connection**

Once connected, your app can:
✅ Read/write to Firestore
✅ Authenticate users
✅ Upload images
✅ Stream real-time updates

---

**Ready? Start with Step 1 above.**
