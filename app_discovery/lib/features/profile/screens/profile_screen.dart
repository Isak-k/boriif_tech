import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../widgets/app_bar_widget.dart';
import '../../../widgets/bottom_navigation_widget.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../../../core/localization/app_strings.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/cache_service.dart';
import '../../../services/app_store_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBottomNav;
  final ValueChanged<int>? onTabSelect;

  const ProfileScreen({
    super.key,
    this.showBottomNav = true,
    this.onTabSelect,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _cacheSize;
  bool _loadingCache = false;

  @override
  void initState() {
    super.initState();
    _loadCacheSize();
  }

  Future<void> _loadCacheSize() async {
    setState(() => _loadingCache = true);
    try {
      final size = await CacheService.getCacheSize();
      if (mounted) {
        setState(() => _cacheSize = size);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCache = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBarWidget(
            title: AppStrings.get('profile', 'profile', lang),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                // Account section
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.cyan, width: 3),
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(
                              color: AppColors.cyan,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.get('common', 'appName', lang),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.get('profile', 'aboutMessage', lang),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final email = auth.activeEmail;
                          if (email != null && auth.isAdmin) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.cyan),
                                ),
                                child: Text(
                                  'Admin Active: $email',
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: AppColors.border),

                // Settings section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.get('profile', 'settings', lang),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageTile(context, lang),
                      _buildSwitchSettingsTile(
                        context,
                        icon: Icons.dark_mode,
                        title: AppStrings.get('profile', 'darkMode', lang),
                        value: settings.isDarkMode,
                        onChanged: (value) {
                          settings.setDarkMode(value);
                        },
                      ),
                      _buildSwitchSettingsTile(
                        context,
                        icon: Icons.notifications,
                        title: AppStrings.get('profile', 'pushNotifications', lang),
                        value: settings.pushNotificationsEnabled,
                        onChanged: (value) {
                          settings.setPushNotifications(value);
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.delete_outline,
                        title: AppStrings.get('profile', 'clearCache', lang),
                        subtitle: _loadingCache
                            ? AppStrings.get('profile', 'cacheSizeCalculating', lang)
                            : (_cacheSize == null
                                ? null
                                : CacheService.formatBytes(_cacheSize!)),
                        onTap: () {
                          _showClearCacheDialog(context, lang);
                        },
                      ),
                    ],
                  ),
                ),

                Divider(color: AppColors.border),

                // About section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppStrings.get('profile', 'about', lang),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsTile(
                        context,
                        icon: Icons.star,
                        title: AppStrings.get('profile', 'rateUs', lang),
                        onTap: () async {
                          try {
                            await AppStoreService.openPlayStore();
                          } catch (e) {
                            if (context.mounted) {
                              _showErrorSnackbar(context, 'Could not open Play Store');
                            }
                          }
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.share,
                        title: AppStrings.get('profile', 'shareWithFriends', lang),
                        onTap: () async {
                          try {
                            await AppStoreService.shareApp();
                          } catch (e) {
                            if (context.mounted) {
                              _showErrorSnackbar(context, 'Could not share app');
                            }
                          }
                        },
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.apps,
                        title: AppStrings.get('profile', 'moreApps', lang),
                        onTap: () async {
                          try {
                            await AppStoreService.openMoreApps();
                          } catch (e) {
                            if (context.mounted) {
                              _showErrorSnackbar(context, 'Could not open app page');
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                Divider(color: AppColors.border),

                // Admin section
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              AppStrings.get('profile', 'admin', lang),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildSettingsTile(
                            context,
                            icon: Icons.admin_panel_settings,
                            title: AppStrings.get('profile', 'adminDashboard', lang),
                            onTap: () {
                              if (auth.isAdmin) {
                                Navigator.pushNamed(context, AppRouter.adminDashboard);
                              } else {
                                Navigator.pushNamed(context, AppRouter.adminLogin);
                              }
                            },
                          ),
                          if (auth.currentUser != null)
                            _buildSettingsTile(
                              context,
                              icon: Icons.logout,
                              title: AppStrings.get('profile', 'signOut', lang),
                              onTap: () {
                                _showSignOutDialog(context, lang);
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
          bottomNavigationBar: widget.showBottomNav
              ? BottomNavigationWidget(
                  currentIndex: 3,
                  onTap: (index) {
                    if (widget.onTabSelect != null) {
                      widget.onTabSelect!(index);
                    }
                  },
                )
              : null,
        );
      },
    );
  }

  Widget _buildLanguageTile(BuildContext context, String currentLang) {
    return ListTile(
      leading: const Icon(Icons.language, color: AppColors.cyan),
      title: Text(
        AppStrings.get('profile', 'language', currentLang),
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(
        SettingsProvider.getLanguageName(currentLang),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AppColors.textSecondary),
      onTap: () {
        _showLanguageDialog(context);
      },
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cyan),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: subtitle != null
          ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildSwitchSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cyan),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.cyan,
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    final currentLang = settings.language;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppStrings.get('profile', 'language', currentLang),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SettingsProvider.getAvailableLanguages()
              .map((lang) => RadioListTile<String>(
                    title: Text(lang['name'] ?? ''),
                    value: lang['code'] ?? '',
                    groupValue: currentLang,
                    onChanged: (value) {
                      if (value != null) {
                        settings.setLanguage(value);
                        Navigator.pop(context);
                      }
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppStrings.get('profile', 'clearCache', lang),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          AppStrings.get('profile', 'confirmClearCache', lang),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('common', 'cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await CacheService.clearCache();
                _loadCacheSize();
                if (context.mounted) {
                  _showSuccessSnackbar(
                    context,
                    AppStrings.get('profile', 'cacheCleared', lang),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  _showErrorSnackbar(context, 'Failed to clear cache');
                }
              }
            },
            child: Text(AppStrings.get('common', 'delete', lang)),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          AppStrings.get('profile', 'signOut', lang),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          AppStrings.get('profile', 'confirmSignOut', lang),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.get('common', 'cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.home,
                  (route) => false,
                );
              }
            },
            child: Text(AppStrings.get('profile', 'signOut', lang)),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
}
