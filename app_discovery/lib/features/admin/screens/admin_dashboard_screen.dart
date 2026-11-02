import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/admin_provider.dart';
import '../../../widgets/snackbar_helper.dart';
import '../../../widgets/cached_app_image.dart';
import 'post_management_screen.dart';
import 'category_management_screen.dart';
import 'create_edit_post_screen.dart';
import 'admin_management_screen.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../services/cache_service.dart';
import '../../../services/cloudinary_service.dart';

enum AdminSection {
  dashboard,
  settings,
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  AdminSection _currentSection = AdminSection.dashboard;
  String _cacheSizeText = 'Calculating...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadDashboardStats();
      admin.loadRecentPosts();
      _loadCacheSize();
      CloudinaryService.loadConfig();
    });
  }

  Future<void> _loadCacheSize() async {
    try {
      final bytes = await CacheService.getCacheSize();
      if (mounted) {
        setState(() {
          _cacheSizeText = CacheService.formatBytes(bytes);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cacheSizeText = '0 B';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AdminProvider, AuthProvider>(
      builder: (context, admin, auth, _) {
        final activeEmail = auth.activeEmail ?? AdminConstants.superAdminEmail;
        final isSuper = AdminConstants.isSuperAdmin(activeEmail);

        return Scaffold(
          backgroundColor: Colors.transparent,
          drawer: _buildSidebar(context, auth, activeEmail, isSuper),
          appBar: AppBar(
            backgroundColor: const Color(0xEE0A0F18),
            elevation: 0,
            leading: Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: AppColors.cyan, size: 24),
                tooltip: 'Open Sidebar',
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            title: Row(
              children: [
                Icon(
                  _currentSection == AdminSection.dashboard
                      ? Icons.dashboard_rounded
                      : Icons.admin_panel_settings_rounded,
                  color: AppColors.cyan,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentSection == AdminSection.dashboard
                      ? 'Dashboard'
                      : 'Admin Setting & Security',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, color: AppColors.cyan, size: 20),
                onPressed: () {
                  admin.loadDashboardStats();
                  admin.loadRecentPosts();
                  _loadCacheSize();
                },
              ),
              IconButton(
                tooltip: 'Sign Out',
                icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                onPressed: () => _showSignOutDialog(context, auth),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            physics: const BouncingScrollPhysics(),
            child: _currentSection == AdminSection.dashboard
                ? _buildDashboardView(context, admin, activeEmail, isSuper)
                : _buildSettingsView(context, auth, activeEmail, isSuper),
          ),
        );
      },
    );
  }

  // ==========================================
  // SIDEBAR DRAWER (CATEGORIZED AS REQUESTED)
  // ==========================================
  Widget _buildSidebar(
    BuildContext context,
    AuthProvider auth,
    String email,
    bool isSuper,
  ) {
    return Drawer(
      backgroundColor: const Color(0xFF090E17),
      child: SafeArea(
        child: Column(
          children: [
            // Professional Executive Sidebar Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF101726),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cyan, width: 1.5),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Image.asset(
                        'assets/images/boriif_icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSuper
                                    ? AppColors.cyan.withValues(alpha: 0.2)
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isSuper ? 'SUPER ADMIN' : 'ADMIN',
                                style: TextStyle(
                                  color: isSuper ? AppColors.cyan : Colors.white70,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.circle, size: 6, color: Colors.greenAccent),
                            const SizedBox(width: 3),
                            const Text(
                              'Online',
                              style: TextStyle(color: Colors.greenAccent, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Sidebar Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // 1. DASHBOARD
                  _buildSidebarHeader('MAIN'),
                  _buildSidebarItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    subtitle: 'Overview, analytics & recent activity',
                    isSelected: _currentSection == AdminSection.dashboard,
                    onTap: () {
                      Navigator.pop(context); // close drawer
                      setState(() {
                        _currentSection = AdminSection.dashboard;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // 2. CONTENT MANAGEMENT
                  _buildSidebarHeader('CONTENT MANAGEMENT'),
                  _buildSidebarItem(
                    icon: Icons.add_circle_outline_rounded,
                    title: 'Create Post',
                    subtitle: 'New app discovery or article',
                    isSelected: false,
                    onTap: () async {
                      Navigator.pop(context); // close drawer
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CreateEditPostScreen()),
                      );
                      if (result == true && mounted) {
                        context.read<AdminProvider>().fetchAllPosts();
                        SnackbarHelper.showSuccess(context, 'Post created successfully');
                      }
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.article_outlined,
                    title: 'Manage Post',
                    subtitle: 'Edit, publish/unpublish, or delete',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PostManagementScreen()),
                      );
                    },
                  ),
                  _buildSidebarItem(
                    icon: Icons.category_outlined,
                    title: 'Manage Category',
                    subtitle: 'Categories and organization',
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                      );
                    },
                  ),

                  const SizedBox(height: 12),

                  // 3. ADMIN SETTING & SECURITY
                  _buildSidebarHeader('ADMIN SETTING & SECURITY'),
                  _buildSidebarItem(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Setting',
                    subtitle: 'Admin settings, cache, & security',
                    isSelected: _currentSection == AdminSection.settings,
                    onTap: () {
                      Navigator.pop(context);
                      setState(() {
                        _currentSection = AdminSection.settings;
                      });
                    },
                  ),
                ],
              ),
            ),

            // Sidebar Bottom: Direct Logout
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C121D),
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                tileColor: AppColors.error.withValues(alpha: 0.1),
                leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: const Text(
                  'Sign out of admin portal',
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSignOutDialog(context, auth);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 4),
      child: Text(
        title,
        style: TextStyle(
          color: AppColors.cyan.withValues(alpha: 0.8),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.cyan.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.cyan.withValues(alpha: 0.4) : Colors.transparent,
          width: 1,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.cyan : Colors.white70,
          size: 22,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSelected ? Colors.white70 : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 12,
          color: isSelected ? AppColors.cyan : Colors.white24,
        ),
        onTap: onTap,
      ),
    );
  }

  // ==========================================
  // VIEW 1: DASHBOARD (OVERVIEW & RECENT ACTIVITY)
  // ==========================================
  Widget _buildDashboardView(
    BuildContext context,
    AdminProvider admin,
    String activeEmail,
    bool isSuper,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Executive Profile Banner
        _buildExecutiveBanner(activeEmail, isSuper),
        const SizedBox(height: 20),

        // Overview & Analytics Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Overview & Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Text(
              'Live metrics',
              style: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Analytics Metric Cards Grid
        _buildStatsGrid(context, admin),
        const SizedBox(height: 26),

        // Recent Activity with Posts Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.history_rounded, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostManagementScreen()),
                );
              },
              child: const Text('View All Posts', style: TextStyle(color: AppColors.cyan, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Recent Posts List with Live Actions
        _buildRecentPostsList(context, admin),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildExecutiveBanner(String email, bool isSuper) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cyan.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.cyan, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.shield_outlined, color: AppColors.cyan, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSuper
                            ? AppColors.cyan.withValues(alpha: 0.2)
                            : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isSuper ? AppColors.cyan : Colors.white30,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        isSuper ? 'SUPER ADMIN' : 'ADMIN',
                        style: TextStyle(
                          color: isSuper ? AppColors.cyan : Colors.white70,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Full Management Access • Firebase & Cloudinary Sync Active',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, AdminProvider admin) {
    final stats = admin.dashboardStats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.45,
      children: [
        _buildStatCard(
          context,
          'Total Posts',
          stats['totalPosts'].toString(),
          Icons.article_outlined,
          AppColors.cyan,
        ),
        _buildStatCard(
          context,
          'Published',
          stats['publishedPosts'].toString(),
          Icons.public,
          Colors.greenAccent,
        ),
        _buildStatCard(
          context,
          'Total Views',
          _formatNumber(stats['totalViews']),
          Icons.visibility_outlined,
          Colors.amberAccent,
        ),
        _buildStatCard(
          context,
          'Total Likes',
          _formatNumber(stats['totalFavorites']),
          Icons.favorite_rounded,
          AppColors.error,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1522),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 20, color: accentColor),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPostsList(BuildContext context, AdminProvider admin) {
    if (admin.recentPosts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1522),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: AppColors.textSecondary),
              SizedBox(height: 8),
              Text(
                'No recent posts found.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: admin.recentPosts.take(6).map((post) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1522),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: CachedAppImage(
                  imageUrl: post.imageUrl,
                  fit: BoxFit.cover,
                  placeholderIcon: Icons.image_outlined,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (post.code.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#${post.code}',
                      style: const TextStyle(
                        color: AppColors.cyan,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: post.isPublished
                          ? Colors.greenAccent.withValues(alpha: 0.15)
                          : Colors.amberAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      post.isPublished ? 'Published' : 'Draft',
                      style: TextStyle(
                        color: post.isPublished ? Colors.greenAccent : Colors.amberAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.visibility_outlined, size: 12, color: AppColors.cyan),
                  const SizedBox(width: 3),
                  Text('${post.viewsCount}', style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.favorite, size: 12, color: AppColors.error),
                  const SizedBox(width: 3),
                  Text('${post.likesCount}', style: const TextStyle(color: AppColors.error, fontSize: 11)),
                ],
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.cyan),
              tooltip: 'Edit Post',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CreateEditPostScreen(post: post)),
                );
                if (result == true && mounted) {
                  await admin.fetchAllPosts();
                  admin.loadRecentPosts();
                  SnackbarHelper.showSuccess(context, 'Post updated successfully');
                }
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  // ==========================================
  // VIEW 2: SETTINGS (FOR ADMIN SETTING & SECURITY + LOGOUT)
  // ==========================================
  Widget _buildSettingsView(
    BuildContext context,
    AuthProvider auth,
    String activeEmail,
    bool isSuper,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Executive Profile Banner
        _buildExecutiveBanner(activeEmail, isSuper),
        const SizedBox(height: 20),

        const Row(
          children: [
            Icon(Icons.security_rounded, color: AppColors.cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'Security & Administrator Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F1522),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // Change Password Option
              ListTile(
                leading: const Icon(Icons.lock_reset, color: AppColors.cyan),
                title: const Text(
                  'Change Admin Password',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                subtitle: const Text(
                  'Update password for administrator portal login',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                onTap: () => _showChangePasswordDialog(context),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Superadmin Management
              if (isSuper) ...[
                ListTile(
                  leading: const Icon(Icons.manage_accounts, color: Colors.amberAccent),
                  title: Row(
                    children: [
                      const Text(
                        'Add / Manage Administrators',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amberAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EXCLUSIVE',
                          style: TextStyle(
                            color: Colors.amberAccent,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: const Text(
                    'Grant or revoke administrator access rights',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminManagementScreen()),
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
              ],

              // Cloudinary Configuration
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: Colors.lightBlueAccent),
                title: const Text(
                  'Cloudinary Image Integration',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  CloudinaryService.isConfigured()
                      ? 'Connected: ${CloudinaryService.cloudName}'
                      : 'Unconfigured (default fallback active)',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                onTap: () => _showCloudinaryConfigDialog(context),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Cache & Device Maintenance
              ListTile(
                leading: const Icon(Icons.cleaning_services_outlined, color: Colors.tealAccent),
                title: const Text(
                  'Purge Device Image Cache',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  'Current cache size: $_cacheSizeText',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent.withValues(alpha: 0.15),
                    foregroundColor: Colors.tealAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: const Size(60, 32),
                  ),
                  onPressed: () async {
                    await CacheService.clearCache();
                    await _loadCacheSize();
                    if (context.mounted) {
                      SnackbarHelper.showSuccess(context, 'Device cache purged successfully');
                    }
                  },
                  child: const Text('Clear', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Prominent Setting Logout Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0F1522),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.power_settings_new_rounded, color: AppColors.error, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Session Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'End your administrative session safely. You will need your credentials to log back in.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.logout_rounded, size: 18),
                    label: const Text(
                      'Logout from Admin Portal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: () => _showSignOutDialog(context, auth),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 30),
      ],
    );
  }

  void _showCloudinaryConfigDialog(BuildContext context) {
    final cloudNameController = TextEditingController(text: CloudinaryService.cloudName);
    final presetController = TextEditingController(text: CloudinaryService.uploadPreset);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E131C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cyan, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.cloud_upload_outlined, color: AppColors.cyan),
            SizedBox(width: 10),
            Text('Cloudinary Settings', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure your Cloudinary credentials for direct high-speed image uploads:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: cloudNameController,
              decoration: const InputDecoration(
                labelText: 'Cloud Name',
                hintText: 'e.g. dxyz123',
                prefixIcon: Icon(Icons.cloud),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: presetController,
              decoration: const InputDecoration(
                labelText: 'Upload Preset (Unsigned)',
                hintText: 'e.g. app_discovery_unsigned',
                prefixIcon: Icon(Icons.vpn_key_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.cyan, foregroundColor: Colors.black),
            onPressed: () async {
              final cName = cloudNameController.text.trim();
              final pPreset = presetController.text.trim();
              if (cName.isNotEmpty && pPreset.isNotEmpty) {
                await CloudinaryService.saveConfig(
                  newCloudName: cName,
                  newUploadPreset: pPreset,
                );
                if (mounted) setState(() {});
                if (context.mounted) {
                  Navigator.pop(context);
                  SnackbarHelper.showSuccess(context, 'Cloudinary settings saved successfully');
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isObscured = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0E131C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cyan, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_reset, color: AppColors.cyan),
              SizedBox(width: 10),
              Text(
                'Change Admin Password',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter your new administrator password. This will update your sign-in credentials immediately.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: isObscured,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Enter at least 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(isObscured ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setDialogState(() => isObscured = !isObscured),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmPasswordController,
                obscureText: isObscured,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Re-enter new password',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: Colors.black,
              ),
              onPressed: () async {
                final newPass = newPasswordController.text;
                final confirmPass = confirmPasswordController.text;

                if (newPass.isEmpty || confirmPass.isEmpty) {
                  SnackbarHelper.showError(context, 'Please fill in both fields');
                  return;
                }
                if (newPass.length < 6) {
                  SnackbarHelper.showError(context, 'Password must be at least 6 characters');
                  return;
                }
                if (newPass != confirmPass) {
                  SnackbarHelper.showError(context, 'Passwords do not match');
                  return;
                }

                Navigator.pop(context);

                final auth = context.read<AuthProvider>();
                final success = await auth.changePassword(newPass);

                if (context.mounted) {
                  if (success) {
                    SnackbarHelper.showSuccess(
                      context,
                      'Password updated successfully. Use your new password on next login.',
                    );
                  } else {
                    SnackbarHelper.showError(
                      context,
                      auth.errorMessage ?? 'Failed to update password',
                    );
                  }
                }
              },
              child: const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E131C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to exit the Admin Command Center?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  String _formatNumber(dynamic number) {
    if (number == null) return '0';
    final n = int.tryParse(number.toString()) ?? 0;
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return n.toString();
  }
}
