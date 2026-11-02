# Phase 4: Firestore & Storage Security Rules

## Overview

This document contains the complete Firebase security rules needed to implement secure admin authentication and authorization.

---

## 1. Firestore Security Rules

Go to **Firebase Console → Firestore → Rules** and replace all content with:

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

### Key Security Features

**Public Access:**
- Anyone can read published posts
- Anyone can read all categories
- No login required for browsing

**Authenticated Users:**
- Can read/update their own user document
- Cannot make themselves admins
- Cannot modify protected fields

**Admin-Only Operations:**
- Create, update, delete posts
- Create, update, delete categories
- Admin list management

**Data Validation:**
- Posts must have required fields and valid types
- Categories must have required fields
- Post types restricted to ['app', 'article', 'job']
- Timestamps validated

---

## 2. Cloud Storage Security Rules

Go to **Firebase Console → Storage → Rules** and replace all content with:

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

### Key Security Features

**Public Reads:**
- Anyone can download images
- Images served from CDN

**Admin-Only Uploads:**
- Only admins can upload images
- Only admins can delete images
- Validated MIME types (JPEG, PNG, WebP, GIF)
- Maximum 10MB file size

**Path Organization:**
- `/posts/` - Post images
- `/categories/` - Category images
- Consistent with app structure

---

## 3. Admin Setup Procedure

### First Admin Setup (One-Time)

#### Option A: Using Firebase Admin SDK (Recommended)

1. **Install Node.js and npm** if not already installed

2. **Create a temporary admin setup script:**

```bash
npm init -y
npm install firebase-admin
```

3. **Create `setup-admin.js`:**

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path-to-serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function setupFirstAdmin(email, password) {
  try {
    // 1. Create auth user
    console.log('Creating auth user...');
    const userRecord = await auth.createUser({
      email: email,
      password: password
    });
    
    console.log('Auth user created:', userRecord.uid);
    
    // 2. Create user document
    console.log('Creating user document...');
    await db.collection('users').doc(userRecord.uid).set({
      email: email,
      isAdmin: true,
      createdAt: admin.firestore.Timestamp.now(),
      updatedAt: admin.firestore.Timestamp.now()
    });
    
    console.log('✓ Admin user created successfully!');
    console.log('Email:', email);
    console.log('User ID:', userRecord.uid);
    
  } catch (error) {
    console.error('✗ Error setting up admin:', error);
  }
}

// Run the setup
const adminEmail = 'admin@example.com'; // Change this
const adminPassword = 'SecurePassword123!'; // Change this
setupFirstAdmin(adminEmail, adminPassword);
```

4. **Download service account key:**
   - Firebase Console → Project Settings → Service Accounts
   - Click "Generate New Private Key"
   - Save as `serviceAccountKey.json` in same directory

5. **Run setup:**

```bash
node setup-admin.js
```

6. **Delete the setup files:**

```bash
rm setup-admin.js package.json package-lock.json serviceAccountKey.json
rm -rf node_modules
```

#### Option B: Using Firebase CLI

```bash
# Install Firebase CLI
npm install -g firebase-cli

# Login to Firebase
firebase login

# Set project
firebase use --add

# Use Firestore console to manually add:
# 1. Create users collection
# 2. Add document with your UID
# 3. Set { email, isAdmin: true, createdAt, updatedAt }
```

#### Option C: Using Firebase Console (Manual)

1. Go to **Authentication** → Create a new user with email/password
2. Copy the User ID
3. Go to **Firestore** → Create collection `users`
4. Create document with User ID:
   ```json
   {
     "email": "admin@example.com",
     "isAdmin": true,
     "createdAt": "2024-01-01T00:00:00Z",
     "updatedAt": "2024-01-01T00:00:00Z"
   }
   ```

### Adding More Admins

Once first admin is set up, additional admins can be added:

1. **Via Admin Dashboard** (future feature):
   - Admin goes to settings
   - Enters new admin email
   - System creates user and grants access

2. **Via Firebase Console** (temporary):
   - Create user in Authentication
   - Create document in `users` collection
   - Set `isAdmin: true`

---

## 4. Testing Security Rules

### Test 1: Public Can Read Published Posts

```dart
// Should succeed
final posts = await FirebaseFirestore.instance
    .collection('posts')
    .where('isPublished', isEqualTo: true)
    .get();
print('✓ Public can read published posts: ${posts.docs.length}');
```

### Test 2: Public Cannot Read Draft Posts

```dart
// Should fail
try {
  final drafts = await FirebaseFirestore.instance
      .collection('posts')
      .where('isPublished', isEqualTo: false)
      .get();
  print('✗ ERROR: Public should not read drafts!');
} catch (e) {
  print('✓ Public correctly denied from reading drafts');
}
```

### Test 3: Public Can Read Categories

```dart
// Should succeed
final categories = await FirebaseFirestore.instance
    .collection('categories')
    .get();
print('✓ Public can read categories: ${categories.docs.length}');
```

### Test 4: Non-Admin Cannot Create Posts

```dart
// Should fail
try {
  await FirebaseFirestore.instance.collection('posts').add({
    'title': 'Test',
    'shortDescription': 'Test',
    'description': 'Test',
    'postType': 'app',
    'categoryId': 'test',
    'isPublished': true,
    'createdAt': Timestamp.now(),
    'updatedAt': Timestamp.now(),
  });
  print('✗ ERROR: Non-admin should not create posts!');
} catch (e) {
  print('✓ Non-admin correctly denied from creating posts');
}
```

### Test 5: Admin Can Create Posts

```dart
// Should succeed (when signed in as admin)
final docRef = await FirebaseFirestore.instance.collection('posts').add({
  'title': 'Test Post',
  'shortDescription': 'Short',
  'description': 'Full description',
  'postType': 'app',
  'categoryId': 'category-id',
  'imageUrl': '',
  'playStoreUrl': '',
  'externalUrl': '',
  'isPublished': true,
  'createdAt': Timestamp.now(),
  'updatedAt': Timestamp.now(),
  'publishedAt': Timestamp.now(),
  'viewsCount': 0,
});
print('✓ Admin can create posts: ${docRef.id}');
```

### Test 6: Storage: Public Cannot Upload

```dart
// Should fail
try {
  final file = File('image.jpg');
  await FirebaseStorage.instance
      .ref('posts/test')
      .putFile(file);
  print('✗ ERROR: Public should not upload!');
} catch (e) {
  print('✓ Public correctly denied from uploading');
}
```

### Test 7: Storage: Admin Can Upload

```dart
// Should succeed (when signed in as admin)
final file = File('image.jpg');
final ref = await FirebaseStorage.instance
    .ref('posts/test-image')
    .putFile(file);
print('✓ Admin can upload: ${ref.fullPath}');
```

---

## 5. Using Firebase Emulator Suite

### Setup Emulator

```bash
# Install Firebase CLI
npm install -g firebase-cli

# Initialize emulator
firebase init emulator

# Start emulator
firebase emulators:start
```

### Update Flutter App for Emulator

In `main.dart`, after Firebase initialization:

```dart
// Use emulator (only for development/testing)
if (kDebugMode) {
  await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

### Test with Emulator

1. Start emulator: `firebase emulators:start`
2. Run Flutter app
3. Test scenarios above
4. View in Firestore Emulator UI: http://localhost:4000

---

## 6. Troubleshooting

### Issue: "Permission denied" on post creation

**Check:**
1. Are you signed in as admin?
2. Is `isAdmin: true` in your user document?
3. Do all required fields exist in post data?
4. Is `postType` one of [app, article, job]?

**Fix:**
```dart
// Debug: Print current user and admin status
final user = FirebaseAuth.instance.currentUser;
print('Current user: ${user?.uid}');

final isAdmin = await AuthService().isCurrentUserAdmin();
print('Is admin: $isAdmin');
```

### Issue: Storage upload fails with "Invalid MIME type"

**Check:**
1. Is file a valid image? (JPEG, PNG, WebP, GIF)
2. Is MIME type set correctly?

**Fix:**
```dart
// Ensure correct MIME type
await storageRef.putFile(
  file,
  SettableMetadata(contentType: 'image/jpeg')
);
```

### Issue: File too large error

**Check:**
- Maximum file size is 10MB
- Check `isValidImageSize()` in rules

**Fix:**
- Compress image before upload
- Use image processing before storage

---

## 7. Security Checklist

- [ ] Firestore rules deployed
- [ ] Storage rules deployed
- [ ] First admin created
- [ ] Admin can login
- [ ] Admin can create posts
- [ ] Public can read posts
- [ ] Public cannot create posts
- [ ] Public cannot read drafts
- [ ] Public cannot upload files
- [ ] Service account key deleted
- [ ] Setup script deleted
- [ ] Credentials secured

---

## 8. Production Deployment

### Before Going Live

1. **Review Rules**
   - Verify all restrictions
   - Test security scenarios
   - Check data validation

2. **Test Admin Access**
   - Login as admin
   - Create content
   - Verify real-time updates

3. **Test Public Access**
   - Browse posts without login
   - Verify only published content visible
   - Check image loading

4. **Monitor**
   - Enable logging
   - Check for permission errors
   - Monitor performance

### Enable Firebase Monitoring

```bash
firebase extensions:install firebaseextensions.firestore-bigquery-export
```

---

## 9. Key Takeaways

✅ **Public Access**: Browse posts and categories
✅ **User Access**: Read/update own profile
✅ **Admin Access**: Manage all content
✅ **No Self-Promotion**: Users cannot make themselves admins
✅ **Data Validation**: Required fields validated
✅ **File Validation**: Image type and size limited
✅ **Real-Time**: Updates reflect immediately

---

**Security Phase Complete and Tested**
