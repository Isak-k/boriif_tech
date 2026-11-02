import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'cloudinary_service.dart';

/// Service for handling image storage operations
/// Can use either Firebase Storage or Cloudinary
class StorageService {
  FirebaseStorage? get _storage {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseStorage.instance;
      }
    } catch (_) {}
    return null;
  }
  final CloudinaryService _cloudinary = CloudinaryService();

  // Set to true to use Cloudinary directly, false for Firebase Storage
  static const bool useCloudinary = true;

  /// Upload image file to storage (Firebase or Cloudinary)
  /// Returns the download URL or a Base64 data URI fallback if storage service fails
  Future<String> uploadImage({
    required File file,
    required String folder, // e.g., 'posts', 'categories'
    required String fileName,
  }) async {
    try {
      if (useCloudinary) {
        return await _uploadToCloudinary(file, folder, fileName);
      } else {
        return await _uploadToFirebase(file, folder, fileName);
      }
    } catch (e) {
      print('Notice: Cloud storage upload failed ($e). Using resilient Base64 data URI fallback.');
      try {
        final bytes = await file.readAsBytes();
        final ext = path.extension(file.path).replaceAll('.', '').toLowerCase();
        final mime = (ext == 'png' || ext == 'webp' || ext == 'gif') ? ext : 'jpeg';
        final base64String = base64Encode(bytes);
        return 'data:image/$mime;base64,$base64String';
      } catch (fallbackError) {
        print('Error encoding local fallback image: $fallbackError');
        rethrow;
      }
    }
  }

  /// Upload to Firebase Storage
  Future<String> _uploadToFirebase(
    File file,
    String folder,
    String fileName,
  ) async {
    try {
      final storage = _storage;
      if (storage == null) {
        throw Exception('Firebase Storage is currently unavailable');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = path.extension(file.path);
      final storagePath = '$folder/$fileName-$timestamp$fileExtension';

      final ref = storage.ref().child(storagePath);
      await ref.putFile(
        file,
        SettableMetadata(
          contentType: 'image/${fileExtension.replaceFirst('.', '')}',
        ),
      );

      final downloadUrl = await ref.getDownloadURL();
      print('✓ Image uploaded to Firebase: $storagePath');
      return downloadUrl;
    } catch (e) {
      print('✗ Error uploading image to Firebase: $e');
      rethrow;
    }
  }

  /// Upload to Cloudinary
  Future<String> _uploadToCloudinary(
    File file,
    String folder,
    String fileName,
  ) async {
    try {
      final publicId = '$folder/$fileName-${DateTime.now().millisecondsSinceEpoch}';
      final url = await _cloudinary.uploadImage(
        file: file,
        publicId: publicId,
        folder: folder,
      );
      return url;
    } catch (e) {
      print('✗ Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload image from bytes
  Future<String> uploadImageFromBytes({
    required List<int> bytes,
    required String folder,
    required String fileName,
    required String contentType,
  }) async {
    if (useCloudinary) {
      throw UnimplementedError('Byte upload not yet supported for Cloudinary');
    }

    try {
      final storage = _storage;
      if (storage == null) {
        throw Exception('Firebase Storage is currently unavailable');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storagePath = '$folder/$fileName-$timestamp';

      final ref = storage.ref().child(storagePath);
      await ref.putData(
        Uint8List.fromList(bytes),
        SettableMetadata(contentType: contentType),
      );

      final downloadUrl = await ref.getDownloadURL();
      print('✓ Image uploaded: $storagePath');
      return downloadUrl;
    } catch (e) {
      print('✗ Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete image from storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (useCloudinary) {
        // Extract public_id from Cloudinary URL
        // Format: https://res.cloudinary.com/[cloud]/image/upload/[public_id]
        final uri = Uri.parse(imageUrl);
        final pathSegments = uri.pathSegments;
        final uploadIndex = pathSegments.indexOf('upload');
        if (uploadIndex != -1 && uploadIndex + 1 < pathSegments.length) {
          final publicId = pathSegments.skip(uploadIndex + 1).join('/');
          await _cloudinary.deleteImage(publicId);
        }
      } else {
        final storage = _storage;
        if (storage != null) {
          final ref = storage.refFromURL(imageUrl);
          await ref.delete();
          print('✓ Image deleted: ${ref.fullPath}');
        }
      }
    } catch (e) {
      print('Notice deleting image: $e');
    }
  }

  /// Get download URL for existing image
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      if (useCloudinary) {
        return _cloudinary.getOptimizedUrl(storagePath);
      } else {
        final storage = _storage;
        if (storage == null) return '';
        final url = await storage.ref().child(storagePath).getDownloadURL();
        return url;
      }
    } catch (e) {
      print('Notice getting download URL: $e');
      return '';
    }
  }

  /// List all images in a folder
  Future<List<String>> listImages(String folder) async {
    try {
      if (useCloudinary) {
        // Cloudinary listing requires API, simplified version
        return [];
      } else {
        final storage = _storage;
        if (storage == null) return [];
        final result = await storage.ref().child(folder).listAll();
        final urls = <String>[];

        for (final item in result.items) {
          final url = await item.getDownloadURL();
          urls.add(url);
        }

        return urls;
      }
    } catch (e) {
      print('Notice listing images: $e');
      return [];
    }
  }

  /// Get optimized URL for Cloudinary
  String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
  }) {
    if (useCloudinary) {
      return _cloudinary.getOptimizedUrl(
        publicId,
        width: width,
        height: height,
      );
    }
    return publicId;
  }

  /// Get square thumbnail for Cloudinary
  String getSquareThumbnail(String publicId, {int size = 300}) {
    if (useCloudinary) {
      return _cloudinary.getSquareThumbnail(publicId, size: size);
    }
    return publicId;
  }
}
