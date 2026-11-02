# Phase 4: Security Testing Guide

## Overview

This document provides step-by-step tests to verify that:
- Security rules are working
- Admin features are secure
- Public access is restricted appropriately
- Authorization is enforced

---

## Pre-Test Checklist

Before running tests, verify:

- [ ] Firestore security rules deployed (PHASE4_SECURITY_RULES.md)
- [ ] Storage security rules deployed
- [ ] First admin created (PHASE4_ADMIN_SETUP.md)
- [ ] Flutter app built and running
- [ ] You have admin credentials
- [ ] You can access Firebase Console

---

## Test Set 1: Authentication & Authorization

### Test 1.1: Admin Can Sign In

**Test:** Admin user can authenticate with correct credentials

**Steps:**
1. Run app: `flutter run`
2. Go to Profile tab → Admin Dashboard
3. Enter admin email and password
4. Tap "Sign In"

**Expected Result:**
- ✅ Successfully navigates to Admin Dashboard
- ✅ No error messages
- ✅ Dashboard shows admin statistics

**If Failed:**
- Verify email/password are correct
- Check admin document exists in Firestore with `isAdmin: true`
- Check Firestore rules are published

---

### Test 1.2: Admin Cannot Sign In With Wrong Password

**Test:** Incorrect password is rejected

**Steps:**
1. Go to Profile tab → Admin Dashboard
2. Enter admin email
3. Enter incorrect password
4. Tap "Sign In"

**Expected Result:**
- ❌ Sign-in fails
- ✅ Error message: "Invalid password" or similar
- ✅ Remains on login screen

**If Failed:**
- Firebase auth should validate password
- Check Firebase Authentication is enabled

---

### Test 1.3: Non-Existent User Cannot Sign In

**Test:** Non-existent email is rejected

**Steps:**
1. Go to Profile tab → Admin Dashboard
2. Enter non-existent email: `notreal@example.com`
3. Enter any password
4. Tap "Sign In"

**Expected Result:**
- ❌ Sign-in fails
- ✅ Error message: "User not found" or similar
- ✅ Remains on login screen

**If Failed:**
- Firebase auth should validate user exists
- Check Firebase Authentication settings

---

### Test 1.4: Regular User Cannot Access Admin Features

**Test:** Non-admin authenticated user is denied

**Steps:**
1. Create regular (non-admin) user in Firebase Authentication
2. Sign in with regular user credentials
3. Go to Admin Dashboard
4. Try to access any admin function

**Expected Result:**
- ❌ Access denied
- ✅ Error: "You do not have admin access"
- ✅ Cannot access dashboard

**If Failed:**
- Check user document in Firestore
- Verify `isAdmin: false` for regular user
- Check Firestore rules are published

---

### Test 1.5: Sign Out Removes Admin Access

**Test:** Signing out revokes admin access

**Steps:**
1. Sign in as admin
2. Verify in Admin Dashboard
3. Tap "Sign Out"
4. Try to access admin functions

**Expected Result:**
- ✅ Successfully signed out
- ✅ Cannot access admin features anymore
- ✅ Returned to public app

**If Failed:**
- Check sign-out implementation in AuthService
- Verify auth state listeners are updated

---

## Test Set 2: Firestore Write Restrictions

### Test 2.1: Admin Can Create Posts

**Test:** Admin user can create new posts

**Steps:**
1. Sign in as admin
2. Go to Admin Dashboard
3. Tap "Create New Post"
4. Fill form:
   - Title: "Test Post"
   - Short Description: "Testing admin post creation"
   - Description: "Full description for test"
   - Type: "app"
   - Category: (select any)
5. Tap "Create Post"

**Expected Result:**
- ✅ Post created successfully
- ✅ Success message appears
- ✅ Post appears in Firestore

**Verification:**
```
Firebase Console → Firestore → posts collection
Look for new document with title "Test Post"
```

**If Failed:**
- Check Firestore rules allow admin writes
- Verify storage rules are correct
- Check network connectivity

---

### Test 2.2: Public Cannot Create Posts
