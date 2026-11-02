import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/admin_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/snackbar_helper.dart';
import '../../../services/auth_service.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addNewAdmin(String currentEmail) async {
    final newEmail = _emailController.text.trim();
    final newPassword = _passwordController.text;

    if (newEmail.isEmpty || newPassword.isEmpty) {
      SnackbarHelper.showError(context, 'Please enter email and password for the new admin');
      return;
    }

    if (!newEmail.contains('@') || !newEmail.contains('.')) {
      SnackbarHelper.showError(context, 'Please enter a valid email address');
      return;
    }

    if (!AdminConstants.isSuperAdmin(currentEmail)) {
      SnackbarHelper.showError(context, 'Unauthorized: Only ${AdminConstants.superAdminEmail} can add admins');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Add to AdminConstants and persist
      await AdminConstants.addAdmin(newEmail, requestedBy: currentEmail);

      // 2. Provision in Firestore
      final uid = 'admin_${newEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
      await _authService.storeSignedUser(uid, newEmail);

      // 3. Attempt creation in Firebase Auth
      try {
        await _authService.createUser(newEmail, newPassword);
      } catch (e) {
        print('Notice creating admin in Firebase Auth: $e');
      }

      _emailController.clear();
      _passwordController.clear();

      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showSuccess(context, 'Admin access successfully granted to $newEmail');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(context, 'Error adding admin: $e');
      }
    }
  }

  Future<void> _removeAdmin(String adminEmail, String currentEmail) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Revoke Admin Privileges'),
        content: Text('Are you sure you want to remove administrator privileges from $adminEmail?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminConstants.removeAdmin(adminEmail, requestedBy: currentEmail);
      if (mounted) {
        if (success) {
          // Update Firestore
          try {
            final uid = 'admin_${adminEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
            await FirebaseFirestore.instance.collection('admins').doc(uid).delete();
            await FirebaseFirestore.instance.collection('users').doc(uid).update({'isAdmin': false});
          } catch (_) {}

          setState(() {});
          SnackbarHelper.showSuccess(context, 'Admin privileges revoked for $adminEmail');
        } else {
          SnackbarHelper.showError(context, 'Failed to revoke admin privileges');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentEmail = auth.activeEmail ?? '';
    final isSuper = AdminConstants.isSuperAdmin(currentEmail);

    if (!isSuper) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Management')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Only the Super Administrator (${AdminConstants.superAdminEmail}) has permissions to add or manage administrators.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final adminList = AdminConstants.getAllAdminEmails();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Administrators'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shield, color: AppColors.cyan, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Super Admin Access Active',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Logged in as $currentEmail',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Add Admin Card
            Text(
              'Add New Administrator',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'New Admin Email',
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.person_add),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Temporary Password',
                      hintText: 'Enter password for new admin',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _addNewAdmin(currentEmail),
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_moderator),
                      label: Text(_isLoading ? 'Granting Access...' : 'Grant Admin Privileges'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Active Admins list
            Text(
              'Active Administrators (${adminList.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: adminList.length,
              itemBuilder: (context, index) {
                final email = adminList[index];
                final isThisSuper = AdminConstants.isSuperAdmin(email);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isThisSuper ? AppColors.cyan.withOpacity(0.2) : AppColors.surface,
                      child: Icon(
                        isThisSuper ? Icons.stars : Icons.security,
                        color: isThisSuper ? AppColors.cyan : AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      email,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      isThisSuper ? 'Super Administrator' : 'Administrator',
                      style: TextStyle(
                        color: isThisSuper ? AppColors.cyan : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    trailing: isThisSuper
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.cyan.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'OWNER',
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error),
                            tooltip: 'Revoke Admin Privileges',
                            onPressed: () => _removeAdmin(email, currentEmail),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
