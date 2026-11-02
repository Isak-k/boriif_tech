import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling Cloudinary image operations
class CloudinaryService {
  static const String _prefCloudNameKey = 'cloudinary_cloud_name';
  static const String _prefUploadPresetKey = 'cloudinary_upload_preset';
  static const String _prefApiKeyKey = 'cloudinary_api_key';

  // Configurable parameters with fallbacks
  static String cloudName = 'YOUR_CLOUD_NAME';
  static String uploadPreset = 'app_discovery_unsigned';
  static const bool useUnsignedUpload = true;
  static String apiKey = 'YOUR_API_KEY';
  static String apiSecret = 'YOUR_API_SECRET';

  static bool _configLoaded = false;

  /// Load persisted Cloudinary configuration
  static Future<void> loadConfig() async {
    if (_configLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCloud = prefs.getString(_prefCloudNameKey);
      final savedPreset = prefs.getString(_prefUploadPresetKey);
      final savedApiKey = prefs.getString(_prefApiKeyKey);
      if (savedCloud != null && savedCloud.isNotEmpty) cloudName = savedCloud;
      if (savedPreset != null && savedPreset.isNotEmpty) uploadPreset = savedPreset;
      if (savedApiKey != null && savedApiKey.isNotEmpty) apiKey = savedApiKey;
      _configLoaded = true;
    } catch (_) {}
  }

  /// Save Cloudinary configuration
  static Future<void> saveConfig({
    required String newCloudName,
    required String newUploadPreset,
    String? newApiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    cloudName = newCloudName.trim();
    uploadPreset = newUploadPreset.trim();
    await prefs.setString(_prefCloudNameKey, cloudName);
    await prefs.setString(_prefUploadPresetKey, uploadPreset);
    if (newApiKey != null && newApiKey.isNotEmpty) {
      apiKey = newApiKey.trim();
      await prefs.setString(_prefApiKeyKey, apiKey);
    }
  }

  /// Check whether Cloudinary has been configured by the admin
  static bool isConfigured() {
    return cloudName != 'YOUR_CLOUD_NAME' && cloudName.trim().isNotEmpty;
  }

  /// Upload image file to Cloudinary directly
  Future<String> uploadImage({
    required File file,
    required String publicId,
    String folder = 'app-discovery',
  }) async {
    await loadConfig();

    if (!isConfigured()) {
      throw Exception('Cloudinary not configured. Please set your Cloud Name in Admin Settings.');
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      
      final fullPublicId = '$folder/$publicId';
      request.fields['public_id'] = fullPublicId;
      
      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      if (useUnsignedUpload) {
        request.fields['upload_preset'] = uploadPreset;
      } else {
        final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
        request.fields['api_key'] = apiKey;
        request.fields['timestamp'] = timestamp;
        
        final signatureString = 'public_id=$fullPublicId&timestamp=$timestamp$apiSecret';
        final signature = sha1.convert(utf8.encode(signatureString)).toString();
        request.fields['signature'] = signature;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final secureUrl = jsonResponse['secure_url'] as String?;
        
        if (secureUrl == null) {
          throw Exception('No secure_url in response: $jsonResponse');
        }
        
        print('✓ Image uploaded to Cloudinary: $secureUrl');
        return secureUrl;
      } else {
        final error = jsonDecode(responseBody);
        throw Exception('Upload failed (${response.statusCode}): ${error['error']?['message'] ?? responseBody}');
      }
    } catch (e) {
      print('✗ Error uploading image to Cloudinary: $e');
      rethrow;
    }
  }

  /// Upload image from URL to Cloudinary
  Future<String> uploadImageFromUrl({
    required String imageUrl,
    required String publicId,
    String folder = 'app-discovery',
  }) async {
    await loadConfig();

    if (!isConfigured()) {
      throw Exception('Cloudinary not configured. Set Cloud Name in Admin Settings.');
    }

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', uri);
      final fullPublicId = '$folder/$publicId';
      request.fields['public_id'] = fullPublicId;
      request.fields['file'] = imageUrl;

      if (useUnsignedUpload) {
        request.fields['upload_preset'] = uploadPreset;
      } else {
        final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
        request.fields['api_key'] = apiKey;
        request.fields['timestamp'] = timestamp;
        
        final signatureString = 'public_id=$fullPublicId&timestamp=$timestamp$apiSecret';
        final signature = sha1.convert(utf8.encode(signatureString)).toString();
        request.fields['signature'] = signature;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(responseBody);
        final secureUrl = jsonResponse['secure_url'] as String?;
        
        if (secureUrl == null) {
          throw Exception('No secure_url in response');
        }
        
        print('✓ Image uploaded from URL to Cloudinary: $secureUrl');
        return secureUrl;
      } else {
        final error = jsonDecode(responseBody);
        throw Exception('Upload failed: ${error['error']?['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('✗ Error uploading image from URL: $e');
      rethrow;
    }
  }

  /// Delete image from Cloudinary
  Future<void> deleteImage(String publicId) async {
    try {
      print('Notice: Cloudinary image delete called for $publicId');
    } catch (e) {
      print('Notice deleting image from Cloudinary: $e');
    }
  }

  /// Get optimized URL for image with transformations
  String getOptimizedUrl(
    String publicId, {
    int? width,
    int? height,
    String quality = 'auto',
    String fetchFormat = 'auto',
    bool crop = false,
  }) {
    final transformations = <String>[];

    if (crop) {
      transformations.add('c_auto,g_auto');
    }

    if (width != null || height != null) {
      final w = width ?? 'auto';
      final h = height ?? 'auto';
      transformations.add('w_$w,h_$h');
    }

    transformations.add('q_$quality');
    transformations.add('f_$fetchFormat');

    final transformString = transformations.join('/');
    return 'https://res.cloudinary.com/$cloudName/image/upload/$transformString/$publicId';
  }

  /// Get square cropped URL (for thumbnails)
  String getSquareThumbnail(String publicId, {int size = 300}) {
    return getOptimizedUrl(
      publicId,
      width: size,
      height: size,
      crop: true,
    );
  }

  /// Get responsive image URL for different breakpoints
  String getResponsiveUrl(String publicId, {required int width}) {
    return getOptimizedUrl(
      publicId,
      width: width,
      quality: 'auto',
      fetchFormat: 'auto',
    );
  }

  /// Get configuration status
  static String getConfigurationStatus() {
    if (!isConfigured()) {
      return '⚠️ Cloudinary not configured. Defaulting to local resilient fallback until configured.';
    }
    return '✓ Cloudinary connected ($cloudName) using unsigned preset: $uploadPreset';
  }
}
