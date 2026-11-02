import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';

/// Service for handling URL launching with direct Google Play Store navigation
class UrlLauncherService {
  /// Regular expression for validating Play Store package names
  static final RegExp _packageNameRegex = RegExp(
    r'^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z][a-zA-Z0-9_]*)+$',
  );

  /// Open app directly in Google Play Store app with 0 confirmation dialogs
  /// Priority:
  /// 1. Direct Play Store app launch via market:// with LaunchMode.externalNonBrowserApplication
  /// 2. External app launch via market://
  /// 3. Fallback to https://play.google.com/store/apps/details?id=...
  /// 4. Direct web URL launch
  static Future<bool> launchPlayStoreUrl(String url, BuildContext context) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) {
      _showError(context, 'No application download URL provided.');
      return false;
    }

    try {
      final packageId = _extractPackageId(cleanUrl);

      if (packageId.isNotEmpty) {
        final marketUri = Uri.parse('market://details?id=$packageId');
        
        // 1. Direct Play Store application intent (skips browser selection dialog)
        try {
          final launched = await launchUrl(
            marketUri,
            mode: LaunchMode.externalNonBrowserApplication,
          );
          if (launched) return true;
        } catch (_) {}

        // 2. Fallback to externalApplication mode
        try {
          final launched = await launchUrl(
            marketUri,
            mode: LaunchMode.externalApplication,
          );
          if (launched) return true;
        } catch (_) {}

        // 3. Fallback to Play Store web page
        final webPlayStoreUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageId');
        return await launchUrl(
          webPlayStoreUri,
          mode: LaunchMode.externalApplication,
        );
      }

      // If it is another web link or direct APK link
      final directUri = Uri.parse(cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl');
      return await launchUrl(
        directUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Could not open application link. Please check your internet connection.');
      }
      return false;
    }
  }

  /// Launch external web URL directly
  static Future<bool> launchExternalUrl(String url, BuildContext context) async {
    final cleanUrl = url.trim();
    if (cleanUrl.isEmpty) return false;

    try {
      final uri = Uri.parse(cleanUrl.startsWith('http') ? cleanUrl : 'https://$cleanUrl');
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (context.mounted) {
        _showError(context, 'Could not open the link. Please check your internet connection.');
      }
      return false;
    }
  }

  /// Extract package ID from URL or return raw package name
  static String _extractPackageId(String url) {
    try {
      final clean = url.trim();
      if (_packageNameRegex.hasMatch(clean)) {
        return clean;
      }
      final uri = Uri.parse(clean);
      if (uri.queryParameters.containsKey('id')) {
        final id = uri.queryParameters['id'] ?? '';
        if (_packageNameRegex.hasMatch(id)) return id;
      }
      if (uri.scheme == 'market' && uri.host == 'details') {
        final id = uri.queryParameters['id'] ?? '';
        if (_packageNameRegex.hasMatch(id)) return id;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Check if URL is valid Play Store URL or package name
  static bool isValidPlayStoreUrl(String url) {
    if (url.trim().isEmpty) return false;
    final packageId = _extractPackageId(url);
    return packageId.isNotEmpty || url.contains('play.google.com') || url.startsWith('market://');
  }

  /// Check if URL is valid HTTPS URL
  static bool isValidHttpsUrl(String url) {
    if (url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url.trim());
      return uri.scheme == 'https' || uri.scheme == 'http';
    } catch (_) {
      return false;
    }
  }

  /// Show clean error message
  static void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Open Play Store URL (wrapper method for compatibility)
  static Future<bool> openPlayStoreUrl(String url, BuildContext context) {
    return launchPlayStoreUrl(url, context);
  }

  /// Open external URL (wrapper method for compatibility)
  static Future<bool> openExternalUrl(String url, BuildContext context) {
    return launchExternalUrl(url, context);
  }

  /// Validate URL format without launching
  static bool validateUrl(String url, String postType) {
    return url.trim().isNotEmpty;
  }

  /// Get user-friendly error message for URL validation failure
  static String getUrlErrorMessage(String postType) {
    return 'Please enter a valid link';
  }
}
