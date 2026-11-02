# Phase 2: Firebase Integration Setup Guide

## Overview
This guide walks through connecting your Flutter Android app to Firebase, including authentication, Firestore database, and Cloud Storage. The project includes complete service layers ready for integration.

## Prerequisites
- Flutter SDK 3.12.1+
- Android SDK 21+
- A Google account
- Command-line tools (Git, Java 17+)

## Step 1: Create or Identify Your Firebase Project

### Option A: Create a New Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Create a project**
3. Enter project name: `app-discovery`
4. Click **Continue**
5. Accept the terms and click **Continue**
6. When asked about Analytics, you can enable or disable it
7. Click **Create project**
8. Wait for initialization (2-3 minutes)
9. You'll be redirected to the project dashboard

### Option B: Use an Existing Firebase Project
- If you already have a Firebase project, navigate to it from the console dashboard
- You'll need the **Project ID** from Project Settings

**Save your Project ID** - you'll need it in the next steps.

---

## Step 2: Install Firebase CLI and FlutterFire CLI

### Install Firebase CLI
```bash
# Using npm (requires Node.js)
npm install -g firebase-tools

# Verify installation
firebase --version
```

### Install FlutterFire CLI
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Verify installation
flutterfire --version
```

If `flutterfire` command not found after installation:
- Add Dart bin to PATH, or
- Use: `dart pub global run flutterfire_cli:flutterfire --version`

---

## Step 3: Configure Firebase for Android Using FlutterFire

Navigate to your Flutter project and run the FlutterFire configuration:

```bash
cd app_discovery
flutterfire configure --project=<YOUR_PROJECT_ID>
```

Replace `<YOUR_PROJECT_ID>` with your Firebase project ID (e.g., `app-discovery-12345`).

**What this does:**
1. Prompts you to sign in with Google (opens browser)
2. Registers your Android app with Firebase
3. Downloads `google-services.json`
4. Auto-generates `lib/services/firebase_options.dart`
5. Updates Android Gradle files

**Expected output:**
```
✓ Firebase configured successfully!
✓ Generated google-services.json
✓ firebase_options.dart created
```

### If you're using Firebase Emulator

Run instead with emulator flag:
```bash
flutterfire configure --project=<YOUR_PROJECT_ID> --emulator
```

---

## Step 4: Manual Firebase Console Configuration

After FlutterFire setup, complete these steps in Firebase Console:

### 4.1: Enable Authentication
1. In [Firebase Console](https://console.firebase.google.com/) → Your Project → **Authentication**
2. Click **Get Started**
3. Click **Email/Password** provider
4. Enable **Email/Password**
5. Optionally enable **Anonymous** authentication
6. Click **Save**

### 4.2: Create Firestore Database
1. In Firebase Console → **Firestore Database**
2. Click **Create Database**
3. Choose **Start in test mode** (for development)
4. Choose region (e.g., `us-central1`)
5. Click **Create**

**Important:** Test mode allows all reads/writes. Before production, update security rules.

### 4.3: Enable Cloud Storage
1. In Firebase Console → **Storage**
2. Click **Get Started**
3. Choose region (same as Firestore, e.g., `us-central1`)
4. Click **Done**

### 4.4: Update Firestore Security Rules (Important!)

1. In Firebase Console → **Firestore Database** → **Rules** tab
2. Replace with these development rules:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Public read access for published posts
    match /posts/{postId} {
      allow read: if resource.data.isPublished == true;
      allow write: if request.auth != null;
    }
    
    // Public read for categories
    match /categories/{categoryId} {
      allow read;
      allow write: if request.auth != null;
    }
    
    // User documents - only accessible to themselves
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Favorites collection
    match /users/{userId}/favorites/{favoriteId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Catch-all deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **Publish**

**Before Production:** Update to restrict admin operations to verified admin users.

### 4.5: Update Cloud Storage Security Rules

1. In Firebase Console → **Storage** → **Rules** tab
2. Replace with:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Public read access
    match /{allPaths=**} {
      allow read;
    }
    
    // Write only with authentication
    match /{allPaths=**} {
      allow write: if request.auth != null;
    }
  }
}
```

3. Click **Publish**

---

## Step 5: Create Sample Data (Optional)

### Create Categories

In Firebase Console → Firestore Database → **Firestore Database** tab:

1. Click **Start Collection**
2. Collection ID: `categories`
3. First document: Auto ID
4. Add fields:
   - `name` (string): "Development"
   - `createdAt` (timestamp): today
   - `updatedAt` (timestamp): today
5. Click **Save**

Repeat for: Design, Technology, Business, Marketing, Education

### Create Sample Post

1. Start Collection: `posts`
2. Auto ID
3. Add fields:
   ```
   title: "Getting Started with Flutter"
   shortDescription: "Learn Flutter basics"
   description: "Complete guide to Flutter development"
   postType: "article"
   categoryId: "development-doc-id"
   isPublished: true
   viewsCount: 0
   createdAt: (today)
   updatedAt: (today)
   publishedAt: (today)
   ```
4. Save

---

## Step 6: Test Firebase Connection

### Build and Run the App

```bash
cd app_discovery
flutter run
```

**Expected behavior:**
- App launches without Firebase errors
- Console shows: `✓ Firebase initialized successfully`
- No "Firebase initialization failed" messages

### Test Connectivity

Once the app runs, check console logs. You should see:
```
✓ Firebase initialized successfully
```

If you see errors:
- Check `google-services.json` exists in `android/app/`
- Verify Firebase project ID matches
- Check internet connectivity
- Check Firebase Console → Project Settings → Service Accounts

---

## File Structure Changes

```
app_discovery/
├── lib/
│   ├── services/
│   │   ├── firebase_service.dart          # Firebase initialization
│   │   ├── firebase_options.dart          # Auto-generated by FlutterFire
│   │   ├── auth_service.dart              # Authentication
│   │   ├── post_service.dart              # Firestore posts
│   │   ├── category_service.dart          # Firestore categories
│   │   └── storage_service.dart           # Cloud Storage
│   ├── models/
│   │   ├── post_model.dart                # Updated with Firestore support
│   │   ├── category_model.dart            # Updated with Firestore support
│   │   └── user_model.dart                # New: User model
│   └── main.dart                           # Updated with Firebase init
├── android/
│   └── app/
│       └── google-services.json           # Generated by FlutterFire
└── pubspec.yaml                           # Updated with Firebase packages
```

---

## Services Overview

### FirebaseService
Initializes Firebase Core on app startup.

### AuthService
- `signInWithEmail(email, password)` - Sign in admin
- `createAdminUser(email, password)` - Create admin account
- `isCurrentUserAdmin()` - Check admin status
- `signOut()` - Sign out
- `authStateChanges` - Stream of auth state

### PostService
- `fetchPublishedPosts()` - Get recent posts (paginated)
- `streamPublishedPosts()` - Listen to posts in real time
- `fetchPostsByCategory(categoryId)` - Filter by category
- `fetchPostById(postId)` - Get single post
- `fetchPostsByType(postType)` - Filter by app/article/job
- `incrementViewCount(postId)` - Track views
- `createPost()` - Create new post (admin)
- `updatePost()` - Update post (admin)
- `deletePost()` - Delete post (admin)
- `searchPosts(query)` - Basic search

### CategoryService
- `fetchCategories()` - Get all categories
- `streamCategories()` - Listen to categories
- `fetchCategoryById(id)` - Get single category
- `createCategory()` - Create category (admin)
- `updateCategory()` - Update category (admin)
- `deleteCategory()` - Delete category (admin)
- `getPostCountForCategory(id)` - Count posts

### StorageService
- `uploadImage(file, folder, fileName)` - Upload image
- `uploadImageFromBytes(bytes, ...)` - Upload from bytes
- `deleteImage(imageUrl)` - Delete image
- `getDownloadUrl(path)` - Get image URL
- `listImages(folder)` - List folder images

---

## Security Considerations

### Current State
- Development security rules allow broad access
- No real admin authorization yet

### Before Production
1. Implement server-side admin verification (Phase 4)
2. Update Firestore rules to verify admin custom claims
3. Add rate limiting
4. Enable App Check for Android
5. Audit all security rules

### What NOT to Do
- Don't expose service account keys in app code
- Don't create custom admin flags in client data
- Don't bypass security rules by removing them entirely
- Don't store sensitive credentials in app

---

## Environment Configuration

### Development (Current)
- Firebase Emulator: Optional
- Security Rules: Open (test mode)
- Data: Sample data only

### Staging (Phase 3)
- Real Firestore
- Restricted rules
- Real authentication

### Production (Phase 4)
- Strict security rules
- Server-verified admin roles
- Monitoring enabled
- Backups configured

---

## Troubleshooting

### "firebase_options.dart not found"
- Run: `flutterfire configure --project=<YOUR_PROJECT_ID>`
- Ensure you completed Firebase CLI login

### "google-services.json not found"
- Verify FlutterFire ran successfully
- Check: `android/app/google-services.json` exists
- If not, re-run: `flutterfire configure`

### "Firebase initialization failed"
- Check internet connectivity
- Verify `google-services.json` is valid
- Check Firebase Console → Project Settings
- Ensure Android app is registered in Firebase

### "Firestore permission denied"
- Verify Firestore Database is created
- Check security rules (should be in test mode)
- Ensure user is authenticated (for write operations)
- Check `isPublished: true` for public post reads

### "StorageException: authentication-required"
- Enable Cloud Storage in Firebase Console
- Update storage security rules
- Ensure user is authenticated

### "FlutterFire CLI not found"
Add to PATH or use full command:
```bash
dart pub global run flutterfire_cli:flutterfire configure --project=<YOUR_PROJECT_ID>
```

---

## Next Steps

1. **Immediate**: Run `flutterfire configure` with your Firebase project
2. **Then**: Create Firestore collections and security rules
3. **Test**: Run `flutter run` and check console logs
4. **Phase 3**: Integrate state management and connect UI to services
5. **Phase 4**: Implement admin authorization

---

## Required Firebase Console Actions

**Before proceeding to Phase 3, you MUST complete:**

- [ ] Create/identify Firebase project
- [ ] Run `flutterfire configure` successfully
- [ ] Enable Authentication (Email/Password)
- [ ] Create Firestore Database (test mode)
- [ ] Enable Cloud Storage
- [ ] Update Firestore security rules (test rules provided above)
- [ ] Update Storage security rules (test rules provided above)
- [ ] Create sample categories in Firestore (optional but recommended)
- [ ] Verify `flutter run` launches without Firebase errors

---

## Billing & Storage Info

### Firestore Pricing (US regions, 2024)
- **Read**: $0.06 per 100K
- **Write**: $0.18 per 100K
- **Delete**: $0.02 per 100K
- **Storage**: $0.18 per GB/month
- **Free tier**: 50K reads, 20K writes, 20K deletes, 1GB storage/month

### Cloud Storage Pricing
- **Download**: $0.12/GB
- **Upload**: Free
- **Storage**: $0.020/GB/month
- **Free tier**: 5GB storage, 5GB/month egress

### Tips
- Use test mode during development
- Enable auto-scaling to manage costs
- Delete old test data regularly
- Monitor usage in Firebase Console → Usage dashboard
