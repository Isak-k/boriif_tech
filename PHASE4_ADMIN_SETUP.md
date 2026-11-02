# Phase 4: Complete Admin Setup Guide

## Overview

This guide walks you through:
1. Setting up Firebase security rules
2. Creating your first admin account
3. Testing admin features
4. Adding more admins

---

## Step 1: Deploy Firestore Security Rules

### In Firebase Console

1. Go to **Firebase Console** → Your Project
2. Click **Firestore Database** in left menu
3. Click **Rules** tab at top
4. Replace all content with rules from `PHASE4_SECURITY_RULES.md`
5. Click **Publish**

### Verify Rules Deployed

- Rules should show as "Modified" after publish
- No errors in rule syntax
- Green checkmark visible

---

## Step 2: Deploy Storage Security Rules

### In Firebase Console

1. Go to **Firebase Console** → Your Project
2. Click **Storage** in left menu
3. Click **Rules** tab at top
4. Replace all content with rules from `PHASE4_SECURITY_RULES.md`
5. Click **Publish**

### Verify Rules Deployed

- Rules should show as "Modified" after publish
- No errors in rule syntax
- Green checkmark visible

---

## Step 3: Create First Admin User

You have 3 options. **Option A (Admin SDK)** is recommended.

### Option A: Using Admin SDK Script (Recommended)

This is the most secure method. Run this one-time on your local machine.

#### Prerequisites

- Node.js installed
- Firebase CLI installed: `npm install -g firebase-cli`

#### Steps

1. **Create a temporary directory:**

```bash
mkdir firebase-admin-setup
cd firebase-admin-setup
```

2. **Initialize npm:**

```bash
npm init -y
npm install firebase-admin
```

3. **Download service account key:**
   - Go to **Firebase Console** → **Project Settings** (gear icon)
   - Click **Service Accounts** tab
   - Click **Generate New Private Key**
   - Save file as `serviceAccountKey.json`

4. **Create setup script** - Save as `setup-admin.js`:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Initialize Firebase
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setupFirstAdmin() {
  try {
    // Change these values
    const email = 'admin@example.com';
    const password = 'SecurePassword123!';
    
    console.log('\n🔐 Setting up first admin...');
    console.log(`Email: ${email}`);
    
    // Step 1: Create authentication user
    console.log('\n1️⃣  Creating authentication user...');
    const userRecord = await auth.createUser({
      email: email,
      password: password
    });
    
    console.log(`✓ Auth user created with UID: ${userRecord.uid}`);
    
    // Step 2: Create Firestore user document
    console.log('\n2️⃣  Creating Firestore user document...');
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      isAdmin: true,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    });
    
    console.log(`✓ User document created in Firestore`);
    
    // Step 3: Summary
    console.log('\n✅ ADMIN SETUP COMPLETE!\n');
    console.log('📋 Save this information:');
    console.log(`   Email: ${email}`);
    console.log(`   User ID: ${userRecord.uid}`);
    console.log('\n🚀 Next steps:');
    console.log('   1. Run: flutter run');
    console.log('   2. Tap Profile → Admin Dashboard');
    console.log(`   3. Sign in with: ${email} / ${password}`);
    console.log('\n⚠️  IMPORTANT:');
    console.log('   - Delete serviceAccountKey.json immediately');
    console.log('   - Delete this setup script (setup-admin.js)');
    console.log('   - Never commit credentials to git');
    
  } catch (error) {
    console.error('\n❌ Error setting up admin:', error.message);
    process.exit(1);
  }
}

setupFirstAdmin().then(() => process.exit(0));
```

5. **Run the script:**

```bash
node setup-admin.js
```

Expected output:
```
🔐 Setting up first admin...
Email: admin@example.com

1️⃣  Creating authentication user...
✓ Auth user created with UID: abc123xyz

2️⃣  Creating Firestore user document...
✓ User document created in Firestore

✅ ADMIN SETUP COMPLETE!

📋 Save this information:
   Email: admin@example.com
   User ID: abc123xyz

🚀 Next steps:
   1. Run: flutter run
   2. Tap Profile → Admin Dashboard
   3. Sign in with: admin@example.com / SecurePassword123!

⚠️  IMPORTANT:
   - Delete serviceAccountKey.json immediately
   - Delete this setup script (setup-admin.js)
   - Never commit credentials to git
```

6. **Clean up:**

```bash
# Delete sensitive files
rm serviceAccountKey.json setup-admin.js

# Delete node modules
rm -rf node_modules

# Delete package files
rm package.json package-lock.json

# Go back to project
cd ..
rm -rf firebase-admin-setup
```

**✅ Admin is now created and ready to use!**

---

### Option B: Using Firebase Console (Manual)

If you don't have Node.js:

1. **Create authentication user:**
   - Go to **Firebase Console** → **Authentication**
   - Click **Create User**
   - Email: admin@example.com
   - Password: (your secure password)
   - Click **Create**
   - Copy the **User ID** shown

2. **Create Firestore user document:**
   - Go to **Firestore Database**
   - Click **+ Start Collection**
   - Collection name: `users`
   - Click **Next**
   - Document ID: (paste the User ID from step 1)
   - Add fields:
     - `email` (string): admin@example.com
     - `isAdmin` (boolean): true
     - `createdAt` (timestamp): now
     - `updatedAt` (timestamp): now
   - Click **Save**

**✅ Admin is now created!**

---

### Option C: Using Firebase CLI

1. **Login to Firebase CLI:**

```bash
firebase login
```

2. **Go to Firebase Console** and manually create:
   - Auth user (Authentication tab)
   - Firestore document (Firestore tab)

---

## Step 4: Test Admin Features

### Run the App

```bash
cd app_discovery
flutter pub get
flutter run
```

### Test Login

1. **Navigate to Admin:**
   - Tap **Profile** (bottom right)
   - Scroll down and tap **Admin Dashboard**

2. **Sign In:**
   - Email: (your admin email)
   - Password: (your admin password)
   - Tap **Sign In**

3. **Expected Result:**
   - Should navigate to Admin Dashboard
   - Should show admin stats
   - Should show "Create New Post" button

### Test Operations

1. **Create a post:**
   - Tap **Create New Post**
   - Fill in form:
     - Title: "Test Post"
     - Short Description: "A test post"
     - Description: "Full description here"
     - Type: "app"
     - Category: (select one)
   - Tap **Create Post**
   - Should see success message

2. **Verify in Firestore:**
   - Go to **Firebase Console** → **Firestore**
   - Check `posts` collection
   - New post should appear

3. **Verify on app:**
   - Go to Home screen
   - New post should appear in feed
   - Should update in real-time

### Test Security

1. **Sign out admin:**
   - Go to Admin Dashboard
   - Tap **Sign Out**
   - Should return to public app

2. **Try creating post as public:**
   - Go to Home screen
   - Try to manually create post (use browser console or direct call)
   - Should get "Permission denied" error

---

## Step 5: Add More Admins (Optional)

### Add Admin via Firebase Console

1. Go to **Authentication**
2. Click **Create User**
3. Enter email and password
4. Copy User ID
5. Go to **Firestore** → `users` collection
6. Create new document with User ID
7. Add same fields as first admin

### Add Admin Programmatically

Once you have multiple admins, you can create a backend function to add admins. For now, use Firebase Console.

---

## Step 6: Security Verification Checklist

Test these to verify security is working:

### ✅ Public Can Read Published Posts

1. Sign out (clear app)
2. Check Home screen
3. Posts should load without login
4. **Expected:** ✓ Posts visible

### ✅ Public Cannot Read Drafts

1. Try to fetch unpublished posts via Firestore query
2. **Expected:** ✗ Permission denied error

### ✅ Public Cannot Create Posts

1. Try to create post without login
2. **Expected:** ✗ Permission denied error

### ✅ Non-Admin Cannot Create Posts

1. Create regular user account (non-admin)
2. Sign in
3. Try to access admin dashboard
4. **Expected:** ✗ Denied access

### ✅ Admin Can Create Posts

1. Sign in as admin
2. Go to Admin Dashboard
3. Create post
4. **Expected:** ✓ Post created successfully

### ✅ Cannot Make Yourself Admin

1. Sign in as regular user
2. Try to set `isAdmin: true` in Firestore
3. **Expected:** ✗ Permission denied error

---

## Troubleshooting

### Issue: "Permission denied" on admin login

**Check:**
1. Are rules published? (check Firestore Rules tab)
2. Is user document marked as admin? (check Firestore data)
3. Are you using correct email/password?

**Fix:**
```bash
# Verify in Firestore:
# 1. Go to Database
# 2. Check users collection
# 3. Find your user document
# 4. Verify isAdmin: true
```

### Issue: Cannot create post as admin

**Check:**
1. Are Storage rules published?
2. Is user marked as admin in Firestore?
3. Are all post fields filled?

**Fix:**
```dart
// Check admin status
final isAdmin = await AuthService().isCurrentUserAdmin();
print('Is admin: $isAdmin');
```

### Issue: Public still can't access app

**Check:**
1. Did you publish Firestore rules?
2. Rules should allow anonymous reads of published posts

**Fix:**
- Go to Firestore Rules
- Verify `allow read: if resource.data.isPublished == true;`
- Click Publish

### Issue: Storage uploads fail

**Check:**
1. Are Storage rules published?
2. Is file size under 10MB?
3. Is file a valid image (JPEG, PNG, WebP, GIF)?

**Fix:**
- Check Storage Rules tab
- Verify MIME type validation
- Compress image if too large

---

## Environment Variables (Optional)

For production, store credentials in environment variables:

```dart
// In main.dart or constants
const String FIREBASE_PROJECT_ID = 'your-project-id';

// Never hardcode passwords or keys
```

---

## Production Deployment

### Before Going Live

1. **Review Security Rules**
   - [ ] Firestore rules published
   - [ ] Storage rules published
   - [ ] All scenarios tested

2. **Test Admin Access**
   - [ ] Admin can login
   - [ ] Admin can create posts
   - [ ] Admin can create categories

3. **Test Public Access**
   - [ ] Public can browse posts
   - [ ] Public can browse categories
   - [ ] Public cannot create content

4. **Secure Credentials**
   - [ ] Service account key deleted
   - [ ] Setup scripts deleted
   - [ ] No credentials in git

5. **Monitor Performance**
   - [ ] Watch for permission errors
   - [ ] Check query efficiency
   - [ ] Monitor storage usage

---

## Next Steps

1. ✅ Deploy security rules
2. ✅ Create first admin
3. ✅ Test admin features
4. ✅ Add more admins (optional)
5. ✅ Review security checklist
6. → Deploy to production

---

## Key Security Principles

- ✅ Admins created via backend only
- ✅ Client cannot set admin status
- ✅ Rules enforced server-side
- ✅ No credentials in app code
- ✅ Public access for read-only
- ✅ Admin-only write operations
- ✅ Data validation on rules

---

**Phase 4 Security Setup Complete**
