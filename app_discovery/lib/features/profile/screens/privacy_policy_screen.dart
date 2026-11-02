import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Full-screen professional Privacy Policy page.
/// Extends edge-to-edge with clean typography, clear section hierarchy,
/// and accurate disclosure of Firebase, Cloudinary, and device caching practices.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E17),
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Badge / Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.cyan.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'Boriif Tech • Legal & Privacy',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Last Updated: November 2026',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text(
              'Privacy Policy for Boriif Tech',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your privacy is fundamentally important to us. This Privacy Policy explains how Boriif Tech ("we", "our", or "the App") collects, uses, stores, and protects information when you use our mobile application and related services.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            _buildDivider(),

            // 1. Introduction
            _buildSection(
              number: '1',
              title: 'Introduction',
              content:
                  'Boriif Tech is a technology discovery platform created to provide users with direct access to recommended mobile applications, technological articles, software resources, and career updates. We are committed to maintaining user trust by being completely transparent about the data handled by our application. Regular users can explore content freely without mandatory user account creation.',
            ),

            // 2. Information We Collect
            _buildSection(
              number: '2',
              title: 'Information We Collect',
              content:
                  'We only collect information necessary to deliver and improve our content delivery and user experience:\n\n'
                  '• Device and Usage Information: We may process non-personal diagnostic data such as device model, Android OS version, and app version to ensure compatibility and smooth offline operation.\n'
                  '• Local Preferences: When you bookmark posts as Favorites or change your language (English, Somali, Oromo), these preferences are stored locally on your device using encrypted SharedPreferences.\n'
                  '• View and Interaction Metrics: When you open posts, aggregate view counts are calculated via Cloud Firestore using an anonymous device identifier to prevent duplicate count spam.\n'
                  '• Administrator Credentials: If you log in to the administrative portal, we use Firebase Authentication to verify your authorized email and password. General visitors are never prompted for login or personal details.',
            ),

            // 3. How We Use Information
            _buildSection(
              number: '3',
              title: 'How We Use Information',
              content:
                  'The data processed by Boriif Tech is utilized strictly for the following purposes:\n\n'
                  '• To display published tech posts, app recommendations, and articles accurately.\n'
                  '• To enable automatic offline reading by caching published posts and categories directly on your device.\n'
                  '• To calculate and display real-time engagement metrics (views and likes) across the community.\n'
                  '• To maintain the security and integrity of administrative content management features.\n'
                  '• To route users directly to the official Google Play Store listing when tapping "Get It Now".',
            ),

            // 4. Information Sharing and Disclosure
            _buildSection(
              number: '4',
              title: 'Information Sharing and Disclosure',
              content:
                  'We do not sell, rent, trade, or monetize your personal information or usage activity under any circumstances. We do not disclose data to third-party advertising networks.\n\n'
                  'Information is shared only with trusted infrastructure providers (such as Google Firebase and Cloudinary) strictly as required to store and deliver application content, or when required by applicable law.',
            ),

            // 5. Data Storage and Security
            _buildSection(
              number: '5',
              title: 'Data Storage and Security',
              content:
                  'We implement industry-standard technical measures to safeguard data:\n\n'
                  '• On-Device Caching: Content is saved to local application storage on your Android device to ensure instant loading and offline capability. You can purge this data at any time from Profile > Clear Cache.\n'
                  '• Secure Transmission: All data transferred between the application and our servers is encrypted using modern HTTPS and TLS protocols.\n'
                  '• Access Control: Firestore security rules restrict write operations exclusively to verified administrative accounts authenticated through Firebase.',
            ),

            // 6. Third-Party Services
            _buildSection(
              number: '6',
              title: 'Third-Party Services',
              content:
                  'Our application integrates with reputable third-party service providers:\n\n'
                  '• Google Firebase: Used for cloud database management (Cloud Firestore), authentication, and analytics infrastructure.\n'
                  '• Cloudinary: Used as an optimized Content Delivery Network (CDN) for fast image loading and bandwidth reduction.\n'
                  '• Google Play Store: When tapping "Get It Now", the app opens Google Play Store via the official com.android.vending package intent so you can safely install apps directly from Google.',
            ),

            // 7. Children\'s Privacy
            _buildSection(
              number: '7',
              title: 'Children\'s Privacy',
              content:
                  'Boriif Tech is designed for general audiences interested in technology and applications. We do not knowingly solicit or collect personally identifiable information from children under the age of 13. If you believe that a child has provided us with personal information, please contact us immediately so we can promptly take appropriate measures.',
            ),

            // 8. User Rights and Data Deletion
            _buildSection(
              number: '8',
              title: 'User Rights and Data Deletion',
              content:
                  'You maintain full control over your data while using Boriif Tech:\n\n'
                  '• Clearing Local Cache: You can delete all cached articles, images, and data by tapping "Clear Cache" in the Profile section.\n'
                  '• Removing Favorites: You can toggle bookmarks off at any time, which deletes the corresponding record from your local device storage.\n'
                  '• Administrative Inquiries: Platform administrators can request full account removal or credential reset by reaching out to our support channel.',
            ),

            // 9. Changes to This Privacy Policy
            _buildSection(
              number: '9',
              title: 'Changes to This Privacy Policy',
              content:
                  'We may periodically update this Privacy Policy to reflect enhancements to our application features, operational practices, or legal requirements. Any modifications will be posted directly within this page with an updated revision date. We encourage you to review this policy periodically.',
            ),

            // 10. Contact Information
            _buildSection(
              number: '10',
              title: 'Contact Information',
              content:
                  'If you have questions, feedback, or concerns regarding this Privacy Policy or our data practices, please contact us:\n\n'
                  '• Application: Boriif Tech\n'
                  '• Developer Team: Boriif Tech Support\n'
                  '• Email: support@boriiftech.com\n'
                  '• GitHub Repository: https://github.com/Isak-k/boriif_tech.git\n\n'
                  'We appreciate your trust in Boriif Tech.',
            ),

            const SizedBox(height: 30),
            Center(
              child: Text(
                '© 2026 Boriif Tech. All rights reserved.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String number,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.cyan,
                    width: 1,
                  ),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: Colors.white.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }
}
