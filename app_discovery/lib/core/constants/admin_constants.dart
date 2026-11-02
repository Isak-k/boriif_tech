import 'package:shared_preferences/shared_preferences.dart';

/// Centralized constants and security configuration for administrator privileges
class AdminConstants {
  /// The primary super-administrator email
  static const String superAdminEmail = 'hisakkedi@gmail.com';

  /// Initial default password for the super-administrator
  static const String defaultSuperAdminPassword = r'1!2@3#4$5%';

  /// Default pre-authorized admin emails
  static const List<String> defaultAdminEmails = [
    'hisakkedi@gmail.com',
  ];

  static List<String> _dynamicAdminEmails = [];
  static String? _customSuperAdminPassword;

  /// Check whether an email is the Super Administrator (hisakkedi@gmail.com)
  static bool isSuperAdmin(String? email) {
    if (email == null) return false;
    return email.trim().toLowerCase() == superAdminEmail.toLowerCase();
  }

  /// Check whether an email belongs to an administrator
  static bool isAdminEmail(String? email) {
    if (email == null) return false;
    final normalized = email.trim().toLowerCase();
    if (normalized == superAdminEmail.toLowerCase()) return true;
    if (defaultAdminEmails.any((e) => e.toLowerCase() == normalized)) return true;
    return _dynamicAdminEmails.any((e) => e.toLowerCase() == normalized);
  }

  /// Load dynamically added admins and custom password from persistent storage
  static Future<void> loadPersistedAdmins() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _dynamicAdminEmails = prefs.getStringList('dynamic_admin_emails') ?? [];
      _customSuperAdminPassword = prefs.getString('super_admin_password');
    } catch (_) {}
  }

  /// Add a new admin (ONLY the Super Administrator hisakkedi@gmail.com can call this)
  static Future<bool> addAdmin(String email, {required String requestedBy}) async {
    if (!isSuperAdmin(requestedBy)) {
      print('✗ Unauthorized: Only $superAdminEmail can add new admins');
      return false;
    }
    final normalized = email.trim().toLowerCase();
    if (!_dynamicAdminEmails.contains(normalized)) {
      _dynamicAdminEmails.add(normalized);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('dynamic_admin_emails', _dynamicAdminEmails);
      print('✓ New admin registered: $normalized by $requestedBy');
    }
    return true;
  }

  /// Revoke an admin's privileges (cannot revoke super admin)
  static Future<bool> removeAdmin(String email, {required String requestedBy}) async {
    if (!isSuperAdmin(requestedBy)) {
      print('✗ Unauthorized: Only $superAdminEmail can remove admins');
      return false;
    }
    final normalized = email.trim().toLowerCase();
    if (normalized == superAdminEmail.toLowerCase()) {
      print('✗ Cannot remove the Super Administrator');
      return false;
    }
    _dynamicAdminEmails.remove(normalized);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dynamic_admin_emails', _dynamicAdminEmails);
    print('✓ Admin removed: $normalized');
    return true;
  }

  /// Get all active administrator emails
  static List<String> getAllAdminEmails() {
    final list = <String>{superAdminEmail, ...defaultAdminEmails, ..._dynamicAdminEmails}.toList();
    return list;
  }

  /// Verify super administrator password
  static bool verifySuperAdminPassword(String password) {
    if (_customSuperAdminPassword != null && _customSuperAdminPassword!.isNotEmpty) {
      return password == _customSuperAdminPassword;
    }
    return password == defaultSuperAdminPassword;
  }

  /// Update super administrator password
  static Future<void> updateSuperAdminPassword(String newPassword) async {
    _customSuperAdminPassword = newPassword;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('super_admin_password', newPassword);
    print('✓ Super admin password updated');
  }
}
