# Cloudinary Integration Guide

## Overview

Your app now supports Cloudinary for image uploads and optimization. You can switch between Firebase Storage and Cloudinary with a single boolean flag.

## Setup Steps

### 1. Create Cloudinary Account

1. Go to [cloudinary.com](https://cloudinary.com)
2. Sign up for a free account
3. Go to Dashboard → Account Details
4. Copy your credentials:
   - **Cloud Name**
   - **API Key**
   - **API Secret** (keep this secret!)

### 2. Update Credentials

Edit `app_discovery/lib/services/cloudinary_service.dart` and replace:

```dart
static const String cloudName = 'YOUR_CLOUD_NAME';
static const String apiKey = 'YOUR_API_KEY';
static const String apiSecret = 'YOUR_API_SECRET';
```

With your actual Cloudinary credentials.

### 3. Switch to Cloudinary

In `app_discovery/lib/services/storage_service.dart`, change:

```dart
static const bool useCloudinary = false;  // Change to true
```

To:

```dart
static const bool useCloudinary = true;
```

### 4. Run the App

```bash
cd app_discovery
flutter pub get
flutter run
```

## Features

### Image Upload
- Upload from file
- Upload from URL
- Automatic public ID generation

### Image Optimization
- Auto format conversion (WebP, AVIF)
- Auto quality adjustment
- Responsive sizing
- Square cropping for thumbnails

### URL Generation
- Optimized URLs with transformations
- Responsive images for different breakpoints
- Square thumbnails (300x300 default)

## Usage Examples

### Upload Image
```dart
final url = await storageService.uploadImage(
  file: imageFile,
  folder: 'posts',
  fileName: 'my-post',
);
```

### Get Optimized URL
```dart
final optimizedUrl = storageService.getOptimizedUrl(
  'posts/my-post-1234567890',
  width: 800,
  height: 600,
);
```

### Get Square Thumbnail
```dart
final thumbnail = storageService.getSquareThumbnail(
  'posts/my-post-1234567890',
  size: 400,
);
```

## Transformation Examples

Cloudinary URLs support powerful transformations:

### Auto Quality & Format
```
https://res.cloudinary.com/[cloud]/image/upload/q_auto,f_auto/image-id
```

### Responsive Image
```
https://res.cloudinary.com/[cloud]/image/upload/w_600,q_auto,f_auto/image-id
```

### Square Crop
```
https://res.cloudinary.com/[cloud]/image/upload/w_300,h_300,c_auto,g_auto/image-id
```

## Security Notes

### Never Hardcode Secrets in Production
- Store API secret securely (not in code)
- Use backend signature generation for production
- Consider proxy uploads through your backend

### Production Implementation
For production, don't hardcode API credentials:

1. Create backend endpoint for upload signatures
2. Frontend requests signature from backend
3. Frontend uploads with signature
4. Backend never exposes API secret

Example backend endpoint:
```javascript
// Node.js example
const cloudinary = require('cloudinary').v2;

app.post('/api/upload-signature', (req, res) => {
  const signature = cloudinary.utils.api_sign_request(
    { folder: 'app-discovery' },
    process.env.CLOUDINARY_API_SECRET
  );
  res.json({ signature });
});
```

## Switching Back to Firebase

To use Firebase Storage again:

1. In `storage_service.dart`:
```dart
static const bool useCloudinary = false;
```

2. Run app - automatically uses Firebase

## Advantages of Cloudinary

✅ **Better Performance**
- CDN delivery
- Auto format/quality
- Global edge servers

✅ **Built-in Optimization**
- No separate resizing needed
- Responsive images automatic
- Bandwidth savings

✅ **Easy Transformations**
- URL-based transformations
- No server-side processing
- Real-time adjustments

✅ **Free Tier**
- 25GB storage
- 25GB bandwidth
- Perfect for testing

## Advantages of Firebase

✅ **Simpler Setup**
- No external credentials
- Already integrated
- Firebase Console management

✅ **Keep Data In Ecosystem**
- Single Firebase project
- Unified authentication
- Consistent backups

## Troubleshooting

### Upload Fails
- Check Cloud Name is correct
- Verify API Key is valid
- Ensure folder exists in Cloudinary

### Images Not Loading
- Check URL format is correct
- Verify public ID exists
- Test URL in browser

### Performance Issues
- Use appropriate image sizes
- Enable quality auto
- Use web format (f_auto)

## Next Steps

1. Test upload in admin dashboard
2. Monitor Cloudinary usage
3. Set up backend signatures for production
4. Configure security rules
5. Plan image optimization strategy

## Support

- [Cloudinary Docs](https://cloudinary.com/documentation)
- [Flutter HTTP Package](https://pub.dev/packages/http)
- [Image Optimization Guide](https://cloudinary.com/guides/optimization)
