# Phase 4: Complete Deployment Guide

## Overview

This guide provides step-by-step instructions to deploy Phase 4 security and admin features to production.

---

## Part 1: Deploy Firebase Security Rules

### Step 1.1: Deploy Firestore Security Rules

1. **Open Firebase Console**
   - Navigate to: https://console.firebase.google.com
   - Select your project

2. **Go to Firestore Database**
   - Left menu → Firestore Database
   - Click the **Rules** tab

3. **Copy and paste the Firestore rules:**

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() &&
             exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    function isPostValid(postData) {
      return postData.size() > 0 &&
             postData.title is string && postData.title.size() > 0 &&
             postData.shortDescription is string && postData.shortDescription.size() > 0 &&
             postData.description is string &&
             postData.postType is string && postData.postType in ['app', 'article', 'job'] &&
             postData.categoryId is string &&
             postData.isPublished is bool &&
             postData.createdAt is timestamp &&
             postData.updatedAt is timestamp;
    }
    
    function isCategoryValid(categoryData) {
      return categoryData.size() > 0 &&
             categoryData.name is string && categoryData.name.size() > 0 &&
             categoryData.createdAt is timestamp &&
             categoryData.updatedAt is timestamp;
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated() && request.auth.uid == userId;
      allow create: if false; // Created by backend only
      allow update: if isAuthenticated() && request.auth.uid == userId &&
                       !("isAdmin" in request.resource.data);
      allow delete: if false; // Never allow deletion
    }
    
    // Posts collection - public reads, admin writes
    match /posts/{postId} {
      // Public: Read only published posts
      allow read: if resource.data.isPublished == true;
      
      // Admin: Read all posts (including drafts)
      allow read: if isAdmin();
      
      // Admin only: Create posts
      allow create: if isAdmin() &&
                       isPostValid(request.resource.data) &&
                       request.resource.data.isPublished == true;
      
      // Admin only: Update posts
      allow update: if isAdmin() &&
                       isPostValid(request.resource.data);
      
      // Admin only: Delete posts
      allow delete: if isAdmin();
    }
    
    // Categories collection - public reads, admin writes
    match /categories/{categoryId} {
      // Public: Read all categories
      allow read: if true;
      
      // Admin only: Create categories
      allow create: if isAdmin() &&
                       isCategoryValid(request.resource.data);
      
      // Admin only: Update categories
      allow update: if isAdmin() &&
                       isCategoryValid(request.resource.data);
      
      // Admin only: Delete categories
      allow delete: if isAdmin();
    }
    
    // Admins collection - admin list
    match /admins/{userId} {
      allow read: if isAdmin();
      allow write: if false; // Managed by backend/CLI only
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

4. **Click Publish** (top right button)
   - Rules will deploy immediately
   - Should show "Modified" next to Rules tab
   - Green checkmark indicates success

### Step 1.2: Deploy Storage Security Rules

1. **Go to Firebase Storage**
   - Left menu → Storage
   - Click the **Rules** tab

2. **Copy and paste the Storage rules:**

```firestore
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() &&
             exists(/databases/(default)/documents/users/$(request.auth.uid)) &&
             get(/databases/(default)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }
    
    function isValidImageMimeType() {
      return request.resource.contentType in [
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/gif'
      ];
    }
    
    function isValidImageSize() {
      // Maximum 10MB for images
      return request.resource.size <= 10 * 1024 * 1024;
    }
    
    // Admin uploads for posts and categories
    match /posts/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin() &&
                      isValidImageMimeType() &&
                      isValidImageSize();
    }
    
    match /categories/{allPaths=**} {
      allow read: if true;
      allow write: if isAdmin() &&
                      isValidImageMimeType() &&
                      isValidImageSize();
    }
    
    // Deny all other uploads
    match /{allPaths=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

3. **Click Publish** (top right button)
   - Confirm deployment
   - Should show "Modified" status

---

## Part 2: Create First Admin User

Choose **ONE** of the three options below:

### Option A: Using Firebase Admin SDK (RECOMMENDED)

This is the most secure method. Credentials stay on your machine.

#### Prerequisites
- Node.js installed
- npm installed

#### Steps

1. **Create admin setup directory:**

```bash
mkdir firebase-admin-setup
cd firebase-admin-setup
npm init -y
npm install firebase-admin
```

2. **Download service account key:**
   - Firebase Console → Project Settings (⚙️ icon)
   - Service Accounts tab
   - Click **Generate New Private Key**
   - Save as `serviceAccountKey.json`
   - **Important**: Never commit this file to git

3. **Create `setup-admin.js` file:**

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setupFirstAdmin() {
  try {
    // CHANGE THESE VALUES
    const adminEmail = 'admin@example.com';
    const adminPassword = 'SecurePassword123!';
    
    console.log('\n🔐 Creating first admin...\n');
    
    // Create auth user
    console.log('📝 Creating authentication user...');
    const userRecord = await auth.createUser({
      email: adminEmail,
      password: adminPassword
    });
    
    console.log(`✓ Auth user created: ${userRecord.uid}\n`);
    
    // Create Firestore user document
    console.log('📝 Creating Firestore user document...');
    await db.collection('users').doc(userRecord.uid).set({
      email: adminEmail,
      isAdmin: true,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    });
    
    console.log('✓ User document created\n');
    
    console.log('✅ ADMIN SETUP COMPLETE!\n');
    console.log('📋 Save this information:');
    console.log(`   Email: ${adminEmail}`);
    console.log(`   User ID: ${userRecord.uid}`);
    console.log(`\n🚀 Next: Run flutter run, then sign in with admin credentials`);
    
  } catch (error) {
    console.error('\n❌ Error:', error.message);
    process.exit(1);
  }
}

setupFirstAdmin().then(() => process.exit(0));
```

4. **Run setup:**

```bash
node setup-admin.js
```

Expected output:
```
🔐 Creating first admin...

📝 Creating authentication user...
✓ Auth user created: abc123xyz

📝 Creating Firestore user document...
✓ User document created

✅ ADMIN SETUP COMPLETE!

📋 Save this information:
   Email: admin@example.com
   User ID: abc123xyz

🚀 Next: Run flutter run, then sign in with admin credentials
```

5. **Clean up (CRITICAL):**

```bash
# Delete sensitive files
rm serviceAccountKey.json setup-admin.js

# Delete node files
rm -rf node_modules package.json package-lock.json

# Go back to project
cd ..
rm -rf firebase-admin-setup
```

**✅ Admin created and ready!**

---

### Option B: Using Firebase Console (Manual)

If you don't have Node.js installed:

1. **Go to Authentication**
   - Firebase Console → Authentication
   - Click **Create user**
   - Email: admin@example.com
   - Password: (your secure password)
   - Click **Create**
   - Copy the **User ID**

2. **Go to Firestore Database**
   - Click **Create collection**
   - Name: `users`
   - Click **Next**
   - Document ID: (paste User ID from step 1)
   - Add fields:
     - `email` (string): admin@example.com
     - `isAdmin` (boolean): true
     - `createdAt` (timestamp): now
     - `updatedAt` (timestamp): now
   - Click **Save**

**✅ Admin created!**

---

### Option C: Using Firebase CLI

```bash
firebase login
firebase use --add
# Then use Firebase Console to manually create user and document as in Option B
```

---

## Part 3: Test Admin Features in App

### Test Setup

1. **Run the app:**

```bash
cd app_discovery
flutter pub get
flutter run
```

2. **Verify public access works:**
   - Home screen should show posts
   - Categories should load
   - Favorites should work
   - NO login required
   - ✅ Public access working

### Test Admin Login

1. **Navigate to Profile**
   - Tap **Profile** (bottom right)

2. **Tap "Admin Dashboard"**
   - Should navigate to Admin Login screen

3. **Enter admin credentials:**
   - Email: admin@example.com
   - Password: (your admin password)
   - Tap **Sign In**

4. **Expected result:**
   - ✅ Should show Admin Dashboard
   - ✅ Should show content management options
   - ✅ No "Permission denied" errors

### Test Admin Operations

1. **Create a new post:**
   - Tap **Create New Post**
   - Fill in fields:
     - Title: "Test Post"
     - Short Description: "A test post"
     - Description: "Full description"
     - Type: "app"
     - Category ID: (copy a category ID from Firestore)
   - Tap **Create**
   - Should see success message

2. **Verify in Firebase:**
   - Firebase Console → Firestore → posts collection
   - New post should appear

3. **Verify on app:**
   - Go back to Home screen
   - New post should appear in feed
   - Updates in real-time

### Test Admin Sign Out

1. **In Admin Dashboard:**
   - Tap logout button (top right)
   - Confirm sign out

2. **Expected result:**
   - ✅ Returns to public app
   - ✅ Can browse as normal user
   - ✅ No login state persists

---

## Part 4: Verify Security

### Test 1: Public Cannot Create Posts

1. **Without signing in:**
   - Try to access Firestore directly or via developer tools
   - Try to create a post document
   - **Expected**: ❌ Permission denied error

### Test 2: Public Can Read Published Posts

1. **Without signing in:**
   - Browse Home screen
   - **Expected**: ✅ Posts visible

### Test 3: Non-Admin Cannot Create Posts

1. **Create non-admin user:**
   - Use Firebase Console
   - Create new user (NOT marked as admin)

2. **Sign in with non-admin user**

3. **Try to create post:**
   - **Expected**: ❌ Permission denied

### Test 4: Cannot Make Yourself Admin

1. **As regular user:**
   - Try to update own document with `isAdmin: true`
   - **Expected**: ❌ Permission denied

### Test 5: Image Upload Restrictions

1. **As non-admin:**
   - Try to upload image to Storage
   - **Expected**: ❌ Permission denied

2. **As admin:**
   - Upload image to Storage
   - **Expected**: ✅ Upload succeeds

---

## Part 5: Troubleshooting

### Issue: "Permission denied" when creating posts

**Check:**
1. Are rules published? (Firestore Rules tab)
2. Is user marked as admin? (Check users collection in Firestore)
3. Are all required fields filled?

**Fix:**
```bash
# Verify user document
Firebase Console → Firestore → users collection
Find your user document → Check isAdmin: true
```

### Issue: App won't load published posts

**Check:**
1. Are Firestore rules published?
2. Are there published posts?
3. Is `isPublished: true` on posts?

**Fix:**
```bash
# Check rules are deployed
Firebase Console → Firestore → Rules → Verify "Modified" status

# Check posts have isPublished: true
Firebase Console → Firestore → posts collection
```

### Issue: Admin login fails

**Check:**
1. Correct email/password?
2. User marked as admin in Firestore?
3. Email verified?

**Fix:**
```bash
# Check in Firebase Console
Authentication → Users → Find your user
Firestore → users collection → Find document → Check isAdmin: true
```

### Issue: Cannot upload images

**Check:**
1. Are Storage rules published?
2. File under 10MB?
3. Valid image format (JPEG, PNG, WebP, GIF)?

**Fix:**
- Verify Storage rules deployed
- Compress images to under 10MB
- Use supported image formats

---

## Part 6: Production Checklist

Before deploying to production:

### Security
- [ ] Firestore rules published
- [ ] Storage rules published
- [ ] First admin created
- [ ] Service account key deleted
- [ ] Setup scripts deleted
- [ ] No credentials in git

### Functionality
- [ ] Admin can login
- [ ] Admin can create posts
- [ ] Admin can create categories
- [ ] Public can read published posts
- [ ] Public cannot create posts
- [ ] Image uploads work for admin

### Testing
- [ ] Tested with real admin
- [ ] Tested public access
- [ ] Tested non-admin access
- [ ] Verified all security rules

### Documentation
- [ ] Admin credentials saved securely
- [ ] Admin setup procedure documented
- [ ] Team notified of admin access

---

## Part 7: Add More Admins

Once first admin is set up:

### Via Firebase Console

1. Create new user in Authentication
2. Go to Firestore → users collection
3. Create document with new user's UID
4. Set `isAdmin: true`

### Grant Admin Programmatically (Future)

You can create an admin panel feature later to allow existing admins to grant admin access to others.

---

## Summary

**Deployment Complete When:**

✅ Firestore rules deployed
✅ Storage rules deployed
✅ First admin created
✅ Admin can login
✅ Admin can create content
✅ Public can browse
✅ Security verified

**Next Steps:**

1. Thoroughly test all features
2. Monitor Firebase logs for errors
3. Get user feedback
4. Plan Phase 5 enhancements

---

**Phase 4 Deployment Complete**

