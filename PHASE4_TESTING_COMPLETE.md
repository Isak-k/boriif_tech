# Phase 4: Complete Testing Guide

## Overview

This guide provides comprehensive test scenarios for Phase 4 security and admin features.

---

## Section 1: Manual Testing Scenarios

### Test Suite 1: Public Access (No Authentication)

#### Test 1.1: Browse Home Feed
- **Steps:**
  1. Launch app
  2. Navigate to Home screen
  3. Observe posts loading
  
- **Expected:**
  ✅ Posts display without login
  ✅ Posts load from Firestore (real-time)
  ✅ Only published posts visible
  ✅ No "Permission denied" errors

#### Test 1.2: Browse Categories
- **Steps:**
  1. Launch app
  2. Tap Categories tab
  3. View category list
  
- **Expected:**
  ✅ All categories visible
  ✅ No authentication required
  ✅ Can tap categories
  ✅ Posts filtered by category

#### Test 1.3: View Post Details
- **Steps:**
  1. From Home, tap a post
  2. View post details
  3. Verify all information displays
  
- **Expected:**
  ✅ Post details load
  ✅ Images display
  ✅ All fields visible
  ✅ No login required

#### Test 1.4: Add to Favorites
- **Steps:**
  1. From post details, tap favorites button
  2. Navigate to Favorites tab
  3. Verify post appears
  
- **Expected:**
  ✅ Can add to favorites
  ✅ Favorites persist locally
  ✅ Can view favorites list

#### Test 1.5: Cannot Access Admin Dashboard
- **Steps:**
  1. Try to directly navigate to admin dashboard
  2. Attempt to create post without login
  
- **Expected:**
  ❌ Admin dashboard not accessible
  ❌ Permission denied on write operations

---

### Test Suite 2: Admin Authentication

#### Test 2.1: Admin Login Success
- **Steps:**
  1. Navigate to Profile → Admin Dashboard
  2. Tap "Admin Dashboard" button
  3. Enter admin email/password
  4. Tap Sign In
  
- **Expected:**
  ✅ Navigates to Admin Dashboard
  ✅ Shows success message
  ✅ Dashboard displays admin stats
  ✅ User verified as admin

#### Test 2.2: Admin Login Failure - Wrong Password
- **Steps:**
  1. Navigate to Admin Login
  2. Enter admin email
  3. Enter wrong password
  4. Tap Sign In
  
- **Expected:**
  ❌ Login fails
  ✅ Error message displays: "Invalid email/password"
  ✅ Stays on login screen
  ✅ Can retry

#### Test 2.3: Admin Login Failure - Wrong Email
- **Steps:**
  1. Navigate to Admin Login
  2. Enter wrong email
  3. Enter any password
  4. Tap Sign In
  
- **Expected:**
  ❌ Login fails
  ✅ Error message displays
  ✅ Can retry
  ✅ Suggests correct email

#### Test 2.4: Empty Credentials Validation
- **Steps:**
  1. Navigate to Admin Login
  2. Leave email/password empty
  3. Tap Sign In
  
- **Expected:**
  ❌ Shows "Please fill in all fields" message
  ✅ Doesn't attempt login

#### Test 2.5: Non-Admin User Cannot Access Dashboard
- **Steps:**
  1. Create non-admin user in Firebase
  2. Login with that user
  3. Navigate to Admin Dashboard
  
- **Expected:**
  ❌ Permission denied
  ✅ Shows "You do not have admin access"
  ✅ Auto sign-out
  ✅ Returns to login

#### Test 2.6: Admin Sign Out
- **Steps:**
  1. Login as admin
  2. In Admin Dashboard, tap logout button
  3. Confirm sign out
  
- **Expected:**
  ✅ Signs out successfully
  ✅ Returns to Home screen
  ✅ Session cleared
  ✅ Must login again to access admin

---

### Test Suite 3: Admin Content Management

#### Test 3.1: Create Post - All Fields
- **Steps:**
  1. Login as admin
  2. Tap "Create New Post"
  3. Fill all fields:
     - Title: "My Test App"
     - Short Desc: "A useful app"
     - Description: "Full description here"
     - Type: "app"
     - Category ID: (valid category ID)
  4. Tap Create
  
- **Expected:**
  ✅ Success message displays
  ✅ Dialog closes
  ✅ Post appears in Firestore
  ✅ Post appears on Home feed
  ✅ Real-time update visible

#### Test 3.2: Create Post - Missing Fields
- **Steps:**
  1. Login as admin
  2. Tap "Create New Post"
  3. Leave one field empty
  4. Tap Create
  
- **Expected:**
  ❌ Shows error: "Fill in all fields"
  ✅ Dialog remains open
  ✅ Can correct and retry

#### Test 3.3: Create Post - Invalid Type
- **Steps:**
  1. Login as admin
  2. Create post with type: "invalid"
  
- **Expected:**
  ❌ Firestore denies write
  ✅ Error displays in app
  ✅ Shows validation error

#### Test 3.4: Create Category
- **Steps:**
  1. Login as admin
  2. Tap "Create Category"
  3. Enter category name: "New Category"
  4. Tap Create
  
- **Expected:**
  ✅ Success message displays
  ✅ Category appears in Firestore
  ✅ Category appears in category list
  ✅ Can use in new posts

#### Test 3.5: Create Category - Empty Name
- **Steps:**
  1. Login as admin
  2. Tap "Create Category"
  3. Leave name empty
  4. Tap Create
  
- **Expected:**
  ❌ Shows error: "Enter category name"
  ✅ Dialog remains open

---

### Test Suite 4: Security Verification

#### Test 4.1: Non-Admin Cannot Create Posts (Firestore Level)
- **Steps:**
  1. Create non-admin user
  2. Login with that user
  3. Attempt to access admin dashboard
  4. Try to manually create post via Firestore
  
- **Expected:**
  ❌ Permission denied from Firestore rules
  ✅ Error message displayed

#### Test 4.2: Public Cannot Read Drafts
- **Steps:**
  1. Create draft post (isPublished: false) in Firestore
  2. Query posts without authentication
  3. Try to read draft post
  
- **Expected:**
  ❌ Permission denied
  ✅ Draft not visible in public queries
  ✅ Only published posts visible

#### Test 4.3: Cannot Make Self Admin
- **Steps:**
  1. Create regular user
  2. Login as that user
  3. Try to set `isAdmin: true` in Firestore
  
- **Expected:**
  ❌ Firestore blocks the write
  ✅ Permission denied error
  ✅ isAdmin remains false

#### Test 4.4: Cannot Modify Admin Claims
- **Steps:**
  1. Login as admin
  2. Try to update another user's `isAdmin` field
  
- **Expected:**
  ❌ Firestore blocks write
  ✅ Only backend/Admin SDK can modify admin status

#### Test 4.5: Image Upload - Non-Admin Blocked
- **Steps:**
  1. Login as non-admin
  2. Try to upload image to Storage
  
- **Expected:**
  ❌ Storage denies upload
  ✅ "Permission denied" error

#### Test 4.6: Image Upload - Admin Allowed
- **Steps:**
  1. Login as admin
  2. Upload valid image (JPEG, PNG, WebP, GIF)
  3. File size < 10MB
  
- **Expected:**
  ✅ Upload succeeds
  ✅ Can retrieve image
  ✅ Image displayed in app

#### Test 4.7: Image Upload - Invalid MIME Type
- **Steps:**
  1. Login as admin
  2. Try to upload non-image file (e.g., .txt)
  
- **Expected:**
  ❌ Storage rules block upload
  ✅ "Invalid MIME type" error

#### Test 4.8: Image Upload - File Too Large
- **Steps:**
  1. Login as admin
  2. Try to upload image > 10MB
  
- **Expected:**
  ❌ Storage rules block upload
  ✅ "File too large" error

---

### Test Suite 5: Real-Time Features

#### Test 5.1: New Post Updates Immediately
- **Steps:**
  1. Open app on two devices/tabs
  2. On device A, login as admin and create post
  3. Observe device B (public user)
  
- **Expected:**
  ✅ Post appears on device B in real-time
  ✅ No manual refresh needed
  ✅ Feed updates automatically

#### Test 5.2: Category Updates Real-Time
- **Steps:**
  1. Open category list on two devices
  2. On device A, admin creates category
  3. Observe device B
  
- **Expected:**
  ✅ New category appears on device B
  ✅ No refresh needed
  ✅ Updates in real-time

#### Test 5.3: Post Delete Updates Immediately
- **Steps:**
  1. Open Home on device B
  2. Admin deletes post on device A
  3. Observe device B
  
- **Expected:**
  ✅ Post disappears from feed
  ✅ Real-time update
  ✅ No manual refresh needed

---

## Section 2: Firestore Emulator Testing

### Setup Emulator

```bash
npm install -g firebase-cli
firebase init emulator
firebase emulators:start
```

### Configure Flutter App for Emulator

In `main.dart`:

```dart
if (kDebugMode) {
  await FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  await FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
}
```

### Emulator Test Suite

#### Test E.1: Emulator Rules Work Correctly
- **Steps:**
  1. Start emulator
  2. Run app in debug mode
  3. Try to create post without auth
  
- **Expected:**
  ❌ Permission denied (rules enforced)

#### Test E.2: Emulator Admin Rules
- **Steps:**
  1. Create admin user in emulator
  2. Create post as admin
  3. Query as public user
  
- **Expected:**
  ✅ Admin can create
  ✅ Public can read published
  ✅ Public cannot read drafts

#### Test E.3: Emulator Storage Rules
- **Steps:**
  1. Try non-admin upload
  2. Try admin upload
  
- **Expected:**
  ❌ Non-admin denied
  ✅ Admin allowed

---

## Section 3: Security Rule Validation

### Rule Validation Checklist

- [ ] `isAuthenticated()` function works
- [ ] `isAdmin()` function verifies user document
- [ ] Posts: public read only published
- [ ] Posts: admin read/create/update/delete all
- [ ] Categories: public read all
- [ ] Categories: admin create/update/delete
- [ ] Users: only read own document
- [ ] Users: cannot modify isAdmin field
- [ ] Users: cannot delete
- [ ] Storage: only admin can write
- [ ] Storage: MIME type validated
- [ ] Storage: file size limited to 10MB
- [ ] All other paths denied

---

## Section 4: Negative Testing

### Malicious User Tests

#### Test N.1: Try to Query All Users
```dart
// Should fail - users collection has read restriction
final users = await FirebaseFirestore.instance.collection('users').get();
```
**Expected:** ❌ Permission denied

#### Test N.2: Try to Write to Admin Collection
```dart
// Should fail - admins collection read-only
await FirebaseFirestore.instance.collection('admins').add({'isAdmin': true});
```
**Expected:** ❌ Permission denied

#### Test N.3: Try to Escalate Privileges
```dart
// Should fail - cannot modify isAdmin
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .update({'isAdmin': true});
```
**Expected:** ❌ Permission denied

#### Test N.4: Try to Read Unencrypted Data
```dart
// Should fail - unknown collection
final data = await FirebaseFirestore.instance.collection('secrets').get();
```
**Expected:** ❌ Permission denied

---

## Section 5: Performance Tests

### Test P.1: Large Query Performance
- **Steps:**
  1. Create 1000 posts in Firestore
  2. Query published posts
  3. Measure load time
  
- **Expected:**
  ✅ Loads in < 2 seconds
  ✅ UI remains responsive

### Test P.2: Real-Time Updates with Many Documents
- **Steps:**
  1. Create listener on posts collection
  2. Create/delete 100 posts
  3. Observe update frequency
  
- **Expected:**
  ✅ Updates received
  ✅ UI responsive
  ✅ No crashes

### Test P.3: Concurrent Admin Operations
- **Steps:**
  1. Multiple admins creating posts simultaneously
  2. Monitor Firestore
  
- **Expected:**
  ✅ All operations succeed
  ✅ No data corruption
  ✅ Consistent state

---

## Section 6: Integration Tests

### Test I.1: Complete User Journey (Public)
1. Launch app → ✅
2. Browse home → ✅
3. View post → ✅
4. Add to favorites → ✅
5. Browse categories → ✅
6. Filter by category → ✅

### Test I.2: Complete Admin Journey
1. Navigate to admin → ✅
2. Login → ✅
3. Create post → ✅
4. Create category → ✅
5. View dashboard → ✅
6. Sign out → ✅
7. Public access works → ✅

### Test I.3: Mixed User Journey
1. Public user browses → ✅
2. Admin creates content → ✅
3. Public user sees updates → ✅
4. Public user adds to favorites → ✅
5. Admin deletes content → ✅
6. Update reflected for public → ✅

---

## Section 7: Error Handling Tests

### Test Error H.1: Network Offline
- **Steps:**
  1. Turn off network
  2. Try to create post
  3. Turn network back on
  
- **Expected:**
  ✅ Clear error message
  ✅ Can retry when online
  ✅ Data syncs automatically

### Test Error H.2: Firebase Service Down
- **Steps:**
  1. Disable Firebase Console
  2. Try operations
  
- **Expected:**
  ✅ Graceful degradation
  ✅ Error messages helpful
  ✅ Can retry

### Test Error H.3: Invalid Data
- **Steps:**
  1. Try to create post with null fields
  2. Try invalid post type
  
- **Expected:**
  ✅ Validation prevents issue
  ✅ Clear error to user

---

## Section 8: Acceptance Criteria Verification

### Criteria: Public App Works Without Login
- [ ] ✅ Home feed loads without authentication
- [ ] ✅ Categories visible without login
- [ ] ✅ Post details accessible without login
- [ ] ✅ Favorites work (local storage)

### Criteria: Admin Authentication Works
- [ ] ✅ Admin can login with email/password
- [ ] ✅ Non-admin cannot access dashboard
- [ ] ✅ Invalid credentials show error
- [ ] ✅ Admin can sign out

### Criteria: Admin Operations Work
- [ ] ✅ Admin can create posts
- [ ] ✅ Admin can create categories
- [ ] ✅ Admin can modify content
- [ ] ✅ Admin can delete content

### Criteria: Security Rules Enforced
- [ ] ✅ Public cannot create posts
- [ ] ✅ Public cannot read drafts
- [ ] ✅ Public cannot modify admin status
- [ ] ✅ Storage only accepts admin uploads
- [ ] ✅ MIME types validated
- [ ] ✅ File sizes limited

---

## Test Execution Checklist

**Before Phase 4 Completion:**

- [ ] All manual tests passed
- [ ] Emulator tests passed
- [ ] Security rules validated
- [ ] Negative tests completed
- [ ] Performance acceptable
- [ ] Integration tests passed
- [ ] Error handling works
- [ ] Acceptance criteria met

**Sign-Off:**

- [ ] All features working
- [ ] No critical bugs
- [ ] Security verified
- [ ] Documentation complete
- [ ] Ready for production

---

**Phase 4 Testing Complete**

