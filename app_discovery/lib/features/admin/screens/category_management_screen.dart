import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../models/category_model.dart';
import '../../../widgets/snackbar_helper.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchCategories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage Categories'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Category'),
        onPressed: () {
          _showCreateCategoryDialog(context);
        },
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading && admin.categories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (admin.categories.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admin.categories.length,
            itemBuilder: (context, index) {
              final category = admin.categories[index];
              return _buildCategoryCard(context, admin, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No categories yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first category to organize posts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    AdminProvider admin,
    Category category,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.folder, color: AppColors.cyan),
        title: Text(category.name),
        subtitle: Text(
          'ID: ${category.id}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Text('Edit'),
              onTap: () {
                _showEditCategoryDialog(context, admin, category);
              },
            ),
            PopupMenuItem(
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () {
                _showDeleteCategoryConfirmation(context, admin, category);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Create Category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AdminProvider>(
            builder: (context, admin, _) {
              return ElevatedButton(
                onPressed: admin.isLoading
                    ? null
                    : () async {
                  if (nameController.text.isEmpty) {
                    SnackbarHelper.showError(context, 'Enter category name');
                    return;
                  }

                  final success =
                      await admin.createCategory(nameController.text);

                  if (mounted) {
                    if (success) {
                      try {
                        context.read<CategoryProvider>().fetchCategories();
                      } catch (_) {}
                      Navigator.pop(context);
                      SnackbarHelper.showSuccess(
                          context, 'Category created');
                    } else {
                      SnackbarHelper.showError(context,
                          admin.errorMessage ?? 'Failed to create');
                    }
                  }
                },
                child: admin.isLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Create'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    AdminProvider admin,
    Category category,
  ) {
    final nameController = TextEditingController(text: category.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Edit Category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Category name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AdminProvider>(
            builder: (context, admin, _) {
              return ElevatedButton(
                onPressed: admin.isLoading
                    ? null
                    : () async {
                  if (nameController.text.isEmpty) {
                    SnackbarHelper.showError(context, 'Enter category name');
                    return;
                  }

                  final success = await admin.updateCategory(
                    categoryId: category.id,
                    name: nameController.text,
                  );

                  if (mounted) {
                    if (success) {
                      try {
                        context.read<CategoryProvider>().fetchCategories();
                      } catch (_) {}
                      Navigator.pop(context);
                      SnackbarHelper.showSuccess(context, 'Category updated');
                    } else {
                      SnackbarHelper.showError(
                          context, admin.errorMessage ?? 'Failed to update');
                    }
                  }
                },
                child: admin.isLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Update'),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryConfirmation(
    BuildContext context,
    AdminProvider admin,
    Category category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Category',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"? '
          'Please ensure all associated posts are reassigned first.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Consumer<AdminProvider>(
            builder: (context, admin, _) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                ),
                onPressed: admin.isLoading
                    ? null
                    : () async {
                  final success = await admin.deleteCategory(category.id);

                  if (mounted) {
                    Navigator.pop(context);
                    if (success) {
                      try {
                        context.read<CategoryProvider>().fetchCategories();
                      } catch (_) {}
                      SnackbarHelper.showSuccess(context, 'Category deleted');
                    } else {
                      SnackbarHelper.showError(
                          context, admin.errorMessage ?? 'Failed to delete');
                    }
                  }
                },
                child: admin.isLoading
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Delete'),
              );
            },
          ),
        ],
      ),
    );
  }
}
