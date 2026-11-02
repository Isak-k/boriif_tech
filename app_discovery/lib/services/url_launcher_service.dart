import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Service for handling URL launching with validation and error handling
/// Handles Play Store URLs, web links, and provides user feedback
class UrlLauncherService {
  /// Regular expression for validating Play Store package names
  /// Format: com.company.app or com.company.app.subapp
  static final RegExp _packageNameRegex = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  );

  /// Validate and launch Play Store URL
  /// Supports:
  /// - https://play.google.com/store/apps/details?id=com.example.app
  /// - market://details?id=com.example.app
  static Future<bool> launchPlayStoreUrl(String url, BuildContext context) async {
    try {
      if (!_isValidPlayStoreUrl(url)) {
        _showError(context, 'Invalid Play Store URL format');
        return false;
      }

      final Uri uri = Uri.parse(url);
      
      // Try to open with market:// first (opens native Play Store app directly)
      String marketUrl = url;
      if (url.startsWith('https://play.google.com/store/apps/details?id=')) {
        final packageId = _extractPackageId(url);
        marketUrl = 'market://details?id=$packageId';
      }

      final Uri playStoreUri = Uri.parse(marketUrl);
      
      if (await canLaunchUrl(playStoreUri)) {
        print('✓ Opening Play Store app for: $url');
        return await launchUrl(playStoreUri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback to browser
        print('✓ Opening Play Store in browser for: $url');
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('✗ Error launching Play Store URL: $e');
      if (context.mounted) {
        _showError(context, 'Could not open Play Store. Please check your internet connection.');
      }
      return false;
    }
  }

  /// Validate and launch external URL for article/job posts
  /// Only accepts HTTPS URLs for security
  static Future<bool> launchExternalUrl(String url, BuildContext context) async {
    try {
      if (!_isValidExternalUrl(url)) {
        if (context.mounted) {
          _showError(context, 'Invalid URL format. Only HTTPS URLs are supported.');
        }
        return false;
      }

      final Uri uri = Uri.parse(url);
      
      if (await canLaunchUrl(uri)) {
        print('✓ Opening external URL: $url');
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showError(context, 'Could not open the link. Please check your internet connection.');
        }
        return false;
      }
    } catch (e) {
      print('✗ Error launching external URL: $e');
      if (context.mounted) {
        _showError(context, 'Could not open the link. Please try again.');
      }
      return false;
    }
  }

  /// Check if URL is a valid Play Store URL
  static bool _isValidPlayStoreUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);

      // Check scheme
      if (uri.scheme != 'https' && uri.scheme != 'market') {
        return false;
      }

      // If market:// scheme, validate host and query
      if (uri.scheme == 'market') {
        if (uri.host != 'details') return false;
        final packageId = uri.queryParameters['id'];
        return packageId != null && _packageNameRegex.hasMatch(packageId);
      }

      // If https:// scheme, validate domain and path
      if (uri.scheme == 'https') {
        if (uri.host != 'play.google.com') return false;
        if (uri.path != '/store/apps/details') return false;
        final packageId = uri.queryParameters['id'];
        return packageId != null && _packageNameRegex.hasMatch(packageId);
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Check if URL is a valid external HTTPS URL
  static bool _isValidExternalUrl(String url) {
    if (url.isEmpty) return false;

    try {
      final uri = Uri.parse(url);
      
      // Must be HTTPS for security
      if (uri.scheme != 'https') return false;
      
      // Must have a valid host with at least one dot
      if (uri.host.isEmpty || !uri.host.contains('.')) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Extract package ID from Play Store URL
  static String _extractPackageId(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.queryParameters['id'] ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Show error message to user
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Validate URL format without launching
  /// Returns true if URL is valid for the given post type
  static bool validateUrl(String url, String postType) {
    switch (postType) {
      case 'app':
        return _isValidPlayStoreUrl(url);
      case 'article':
      case 'job':
        return _isValidExternalUrl(url);
      default:
        return false;
    }
  }

  /// Get user-friendly error message for URL validation failure
  static String getUrlErrorMessage(String postType) {
    switch (postType) {
      case 'app':
        return 'Please enter a valid Google Play Store URL (e.g., https://play.google.com/store/apps/details?id=com.example.app)';
      case 'article':
      case 'job':
        return 'Please enter a valid HTTPS URL (e.g., https://example.com)';
      default:
        return 'Invalid URL format';
    }
  }

  /// Check if URL is valid Play Store URL (public method for tests/validation)
  static bool isValidPlayStoreUrl(String url) {
    return _isValidPlayStoreUrl(url);
  }

  /// Check if URL is valid HTTPS URL (public method for tests/validation)
  static bool isValidHttpsUrl(String url) {
    return _isValidExternalUrl(url);
  }

  /// Open Play Store URL (wrapper method for compatibility)
  static Future<bool> openPlayStoreUrl(String url, BuildContext context) {
    return launchPlayStoreUrl(url, context);
  }

  /// Open external URL (wrapper method for compatibility)
  static Future<bool> openExternalUrl(String url, BuildContext context) {
    return launchExternalUrl(url, context);
  }
}
