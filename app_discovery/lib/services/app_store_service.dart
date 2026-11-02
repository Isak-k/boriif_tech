import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class AppStoreService {
  // This is a placeholder package ID - replace with actual app ID when deploying
  static const String _appPackageId = 'com.example.app_discovery';

  // Google Play Store URL for this app
  static String get playStoreUrl =>
      'https://play.google.com/store/apps/details?id=$_appPackageId';

  // Open this app's Play Store page
  static Future<void> openPlayStore() async {
    try {
      final Uri uri = Uri.parse(playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      throw Exception('Could not open Play Store');
    }
  }

  // Share app with friends
  static Future<void> shareApp() async {
    try {
      await Share.share(
        'Check out App Discovery! Discover amazing apps and opportunities. Download now: $playStoreUrl',
        subject: 'App Discovery',
      );
    } catch (e) {
      throw Exception('Could not share app');
    }
  }

  // Get app version
  static const String appVersion = '1.0.0';

  // Get developer more apps URL (placeholder)
  static const String moreAppsUrl =
      'https://play.google.com/store/apps/developer?id=AppDiscoveryDeveloper';

  // Open developer's more apps page
  static Future<void> openMoreApps() async {
    try {
      final Uri uri = Uri.parse(moreAppsUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      throw Exception('Could not open more apps page');
    }
  }
}
