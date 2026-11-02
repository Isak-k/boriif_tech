# Cloudinary Integration Guide

## Overview

The App Discovery app includes full Cloudinary integration for image upload and optimization. However, by default, it uses Firebase Storage for security reasons. This guide explains how to set up and use Cloudinary.

---

## Current Configuration

### Default Setup
- **Current Provider**: Firebase Storage
- **Cloudinary Status**: Integrated but disabled
- **Toggle**: `StorageService.useCloudinary = false`

### Why Firebase by Default?
1. **Security**: Credentials not exposed in app
2. **Cost**: Firebase includes storage quota
3. **Simplicity**: No additional setup required
4. **Reliability**: Well-established service

---

## Setting Up Cloudinary (Optional)

### Step 1: Create Cloudinary Account

1. Go to [cloudinary.com](https://cloudinary.com)
2. Sign up for free account
3. Verify email
4. Dashboard opens with your **Cloud Name**

### Step 2: Find Your Credentials

From Cloudinary Dashboard:
1. Click **Settings** (gear icon)
2. Under **Account**, find:
   - **Cloud Name** - Your unique identifier
   - **API Key** - Public key for API access
   - **API Secret** - Secret key (NEVER share!)

### Step 3: Configure Upload Presets (RECOMMENDED)

For **unsigned uploads** (safe for client apps):

1. Go to **Settings** → **Upload**
2. Click **Add upload preset**
3. Create preset named: `app_discovery_unsigned`
4. Set:
   - **Unsigned**: Toggle ON
   - **Folder**: `app-discovery`
   - **Quality**: `auto`
   - **Fetch Format**: `auto`
5. Save

### Step 4: Update Flutter App

In `lib/services/cloudinary_service.dart`:

```dart
static const String cloudName = 'your_cloud_name_here';  // Replace with your cloud name
static const bool useUnsignedUpload = true;               // Use unsigned for security
```

In `lib/services/storage_service.dart`:

```dart
static const bool useCloudinary = true;  // Enable Cloudinary
```

### Step 5: Verify Setup

The app will log configuration status on startup:

```
✓ Cloudinary configured for unsigned uploads (safe for client app)
```

---

## Unsigned vs. Signed Uploads

### Unsigned Uploads (RECOMMENDED) ✓

**Pros:**
- ✅ Safe for client apps
- ✅ No secrets needed in app
- ✅ Easy to configure
- ✅ Production-ready

**Cons:**
- Need to set up upload preset in Cloudinary dashboard

**How it works:**
```
1. App uploads file to Cloudinary
2. Cloudinary validates against preset rules
3. Upload succeeds if rules match
4. No secrets needed
```

**Setup:** See Step 3 above

### Signed Uploads (NOT RECOMMENDED) ✗

**Pros:**
- ❌ Can upload without preset

**Cons:**
- ❌ Requires API secret in app
- ❌ Secret exposed in client code
- ❌ Security risk
- ❌ Should never be used in production

**⚠️ WARNING:** Never put `apiSecret` in production client app!

---

## How to Enable Cloudinary

### Option 1: Use Unsigned Uploads (Recommended)

1. Complete setup steps 1-4 above
2. In `cloudinary_service.dart`:
   ```dart
   static const bool useUnsignedUpload = true;
   static const String cloudName = 'your_cloud_name';
   ```

3. In `storage_service.dart`:
   ```dart
   static const bool useCloudinary = true;
   ```

4. Run app and verify upload works

### Option 2: Keep Firebase Storage (Default)

No changes needed. App works as-is with Firebase Storage.

---

## Image Upload Flow

### With Cloudinary (If Enabled)

```
Admin selects image
    ↓
AdminProvider.uploadImage()
    ↓
StorageService.uploadImage() [useCloudinary = true]
    ↓
CloudinaryService.uploadImage()
    ↓
POST to https://api.cloudinary.com/v1_1/{cloud}/image/upload
    ↓
Cloudinary validates preset & file
    ↓
Image stored in Cloudinary
    ↓
Returns secure_url
    ↓
Stored in Firestore post document
```

### With Firebase Storage (Current)

```
Admin selects image
    ↓
AdminProvider.uploadImage()
    ↓
StorageService.uploadImage() [useCloudinary = false]
    ↓
Firebase Storage upload
    ↓
Returns download URL
    ↓
Stored in Firestore post document
```

---

## Image Optimization Features

Cloudinary provides automatic image optimization:

### Automatic Quality
```dart
// Images automatically optimized for device
String url = cloudinaryService.getOptimizedUrl(publicId);
// Result: Auto quality, auto format, auto size
```

### Responsive Images
```dart
// Different sizes for different screens
String mobile = cloudinaryService.getResponsiveUrl(publicId, width: 400);
String tablet = cloudinaryService.getResponsiveUrl(publicId, width: 800);
String desktop = cloudinaryService.getResponsiveUrl(publicId, width: 1200);
```

### Thumbnails
```dart
// Square thumbnail for grid displays
String thumb = cloudinaryService.getSquareThumbnail(publicId, size: 300);
```

### Custom Transformations
```dart
// Custom width, height, quality, format
String url = cloudinaryService.getOptimizedUrl(
  publicId,
  width: 500,
  height: 500,
  quality: 'good',
  crop: true,
);
```

---

## Security Considerations

### ✓ Safe Practices

1. **Use Unsigned Uploads**
   - Set up upload preset in dashboard
   - Only app uploads to preset
   - No secrets in app code

2. **Use Firebase Storage** (Current default)
   - No changes needed
   - Firebase handles security
   - Well-tested and reliable

3. **Backend Signing** (Enterprise)
   - Backend generates signatures
   - App never sees secrets
   - Most secure option

### ✗ Unsafe Practices

1. **Signed Uploads from Client**
   - ❌ Puts API secret in app
   - ❌ Anyone can decompile app
   - ❌ Secret is compromised
   - ❌ Never do this in production

2. **Hardcoded Credentials**
   - ❌ Easy to find in code
   - ❌ Hard to rotate
   - ❌ Git history exposes secret
   - ❌ Never do this

---

## Troubleshooting

### Upload Fails: "Unsigned upload not allowed"

**Cause:** Upload preset not created or name doesn't match

**Fix:**
1. Go to Cloudinary Settings → Upload
2. Create preset named exactly: `app_discovery_unsigned`
3. Set to Unsigned
4. Verify name matches in code

### Upload Fails: "Cloud name not found"

**Cause:** Cloud name not set or incorrect

**Fix:**
```dart
// In cloudinary_service.dart
static const String cloudName = 'your_actual_cloud_name';  // NOT 'YOUR_CLOUD_NAME'
```

### Upload Works but URL Returns Broken Image

**Cause:** Cloud name in URL wrong or image not uploaded

**Fix:**
1. Check CloudinaryService.cloudName matches dashboard
2. Verify upload succeeded (check Cloudinary Media Library)
3. Test URL in browser

### Configuration Status Shows Warning

**Current:**
```
⚠️  WARNING: Using signed uploads with secrets in app (not recommended)
```

**Fix:**
1. Set `useUnsignedUpload = true`
2. Create upload preset in dashboard
3. Restart app

---

## Switching Between Providers

### Switch from Firebase to Cloudinary

In `storage_service.dart`:
```dart
static const bool useCloudinary = true;  // Change from false
```

New uploads will use Cloudinary. Old Firebase URLs still work.

### Switch from Cloudinary back to Firebase

In `storage_service.dart`:
```dart
static const bool useCloudinary = false;  // Change from true
```

All future uploads use Firebase. Cloudinary URLs still accessible.

---

## Costs

### Firebase Storage
- **Free**: 5 GB per month
- **After**: $0.18 per GB
- **Included** in Firebase project

### Cloudinary
- **Free**: 25 credits/month (≈1GB)
- **Paid**: Starting at $29/month
- **Separate** service

### Recommendation
- **Development**: Use Firebase (included)
- **Production (small)**: Use Firebase or Cloudinary free tier
- **Production (large)**: Compare costs, both options viable

---

## Advanced: Backend Signing

For enterprise security, implement backend signing:

### Backend Setup
1. Create endpoint: `/api/cloudinary/sign`
2. Endpoint receives: `public_id`, `timestamp`
3. Endpoint generates: `signature` using `apiSecret`
4. Returns: `signature` to app

### App Changes
```dart
// Request signature from backend
final signature = await backendService.getCloudinarySignature(publicId);

// Use signature in upload
request.fields['signature'] = signature;
```

### Benefits
- ✓ API secret never exposed
- ✓ Secure even if app is decompiled
- ✓ Can revoke access immediately
- ✓ Logging and audit trail

---

## Testing Upload

### Test Firebase Storage (Default)
```bash
flutter run
# Upload image from Admin Dashboard
# Image should appear in Firebase Storage console
```

### Test Cloudinary (After Setup)
```bash
# Ensure useCloudinary = true in storage_service.dart
flutter run
# Upload image from Admin Dashboard
# Check Cloudinary Media Library in dashboard
# Image should appear there
```

### Verify Upload
1. Admin Dashboard → Create Post
2. Select image from device
3. Fill other fields
4. Tap "Save Post"
5. Check upload destination:
   - **Firebase**: Firebase Storage console
   - **Cloudinary**: Cloudinary Media Library

---

## Image Delivery

### Firebase Storage URLs
```
https://firebasestorage.googleapis.com/v0/b/...
```
- Direct download URLs
- Standard image hosting
- No transformation options

### Cloudinary URLs
```
https://res.cloudinary.com/{cloud}/image/upload/{transformations}/{public_id}
```
- Optimized delivery via CDN
- Transformation support
- Better performance
- Advanced features

---

## Production Checklist

### Before Going Live

- [ ] Choose storage provider (Firebase or Cloudinary)
- [ ] If Cloudinary: Create account and upload preset
- [ ] Update `cloudinary_service.dart` with cloud name
- [ ] Update `storage_service.dart` with provider choice
- [ ] Test image upload on device
- [ ] Test image display on app
- [ ] Verify old images still load
- [ ] Monitor first uploads
- [ ] Set up error logging

### Security Review

- [ ] No hardcoded API secrets in app code
- [ ] Using unsigned uploads (if Cloudinary)
- [ ] Firebase Storage access controlled
- [ ] Firestore security rules reviewed
- [ ] Admin authorization working

---

## Additional Resources

- **Cloudinary Docs**: https://cloudinary.com/documentation
- **Upload API**: https://cloudinary.com/documentation/image_upload_api_reference
- **Transformations**: https://cloudinary.com/documentation/image_transformation_reference
- **Upload Presets**: https://cloudinary.com/documentation/upload_presets

---

## Support

### Firebase Storage Issues
- Check Firebase Console
- Verify storage rules
- Check authentication

### Cloudinary Issues
- Check Cloudinary dashboard
- Verify upload preset exists
- Check cloud name
- Review transformation URLs

### App Issues
- Check logs for upload errors
- Verify storage_service.dart toggle
- Test on emulator first
- Check network connectivity

---

## Summary

**Current Default:**
- ✓ Using Firebase Storage
- ✓ No additional setup needed
- ✓ Works out-of-the-box

**Optional: Enable Cloudinary**
1. Create free Cloudinary account
2. Set up unsigned upload preset
3. Update cloud name in code
4. Toggle `useCloudinary = true`
5. Test and deploy

**Both methods work. Choose based on your needs.**

