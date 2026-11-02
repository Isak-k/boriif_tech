import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../providers/category_provider.dart';
import '../../../models/post_model.dart';
import '../../../widgets/snackbar_helper.dart';

class CreateEditPostScreen extends StatefulWidget {
  final Post? post;

  const CreateEditPostScreen({super.key, this.post});

  @override
  State<CreateEditPostScreen> createState() => _CreateEditPostScreenState();
}

class _CreateEditPostScreenState extends State<CreateEditPostScreen> {
  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _shortDescController;
  late TextEditingController _descriptionController;
  late TextEditingController _playStoreUrlController;
  late TextEditingController _externalUrlController;
  late TextEditingController _imageUrlController;

  String? _selectedCategoryId;
  File? _selectedImage;
  String? _uploadedImageUrl;
  bool _isDraft = false;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchCategories();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.post?.title ?? '');
    _codeController = TextEditingController(text: widget.post?.code ?? '');
    _shortDescController = TextEditingController(text: widget.post?.shortDescription ?? '');
    _descriptionController = TextEditingController(text: widget.post?.description ?? '');
    _playStoreUrlController = TextEditingController(text: widget.post?.playStoreUrl ?? '');
    _externalUrlController = TextEditingController(text: widget.post?.externalUrl ?? '');
    _imageUrlController = TextEditingController(text: widget.post?.imageUrl ?? '');

    _selectedCategoryId = widget.post?.categoryId;
    _uploadedImageUrl = widget.post?.imageUrl;
    _isDraft = !(widget.post?.isPublished ?? true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _shortDescController.dispose();
    _descriptionController.dispose();
    _playStoreUrlController.dispose();
    _externalUrlController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      SnackbarHelper.showError(context, 'Failed to pick image: $e');
    }
  }

  Future<void> _uploadImage(AdminProvider admin) async {
    if (_selectedImage == null) return;

    final url = await admin.uploadImage(_selectedImage!);
    if (url != null) {
      setState(() {
        _uploadedImageUrl = url;
        _selectedImage = null;
      });
    } else {
      if (mounted) {
        SnackbarHelper.showError(context, admin.errorMessage ?? 'Failed to upload image');
      }
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
      SnackbarHelper.showError(context, 'Please select or create a category');
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm()) return;

    final admin = context.read<AdminProvider>();

    if (_imageUrlController.text.trim().isNotEmpty) {
      _uploadedImageUrl = _imageUrlController.text.trim();
    }

    // Upload image if selected from device
    if (_selectedImage != null) {
      await _uploadImage(admin);
    }

    if (_uploadedImageUrl == null && _imageUrlController.text.trim().isNotEmpty) {
      _uploadedImageUrl = _imageUrlController.text.trim();
    }

    final isEditing = widget.post != null;
    bool success;

    if (isEditing) {
      success = await admin.updatePost(
        postId: widget.post!.id,
        title: _titleController.text.trim(),
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        shortDescription: _shortDescController.text.trim(),
        description: _descriptionController.text.trim(),
        postType: 'app', // Standardized post type
        categoryId: _selectedCategoryId!,
        imageUrl: _uploadedImageUrl,
        playStoreUrl: _playStoreUrlController.text.trim().isEmpty
            ? null
            : _playStoreUrlController.text.trim(),
        externalUrl: _externalUrlController.text.trim().isEmpty
            ? null
            : _externalUrlController.text.trim(),
        isPublished: !_isDraft,
      );
    } else {
      final postId = await admin.createPost(
        title: _titleController.text.trim(),
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        shortDescription: _shortDescController.text.trim(),
        description: _descriptionController.text.trim(),
        postType: 'app', // Standardized post type
        categoryId: _selectedCategoryId!,
        imageUrl: _uploadedImageUrl,
        playStoreUrl: _playStoreUrlController.text.trim().isEmpty
            ? null
            : _playStoreUrlController.text.trim(),
        externalUrl: _externalUrlController.text.trim().isEmpty
            ? null
            : _externalUrlController.text.trim(),
        isPublished: !_isDraft,
      );
      success = postId != null;
    }

    if (mounted) {
      if (success) {
        try {
          context.read<PostProvider>().fetchPublishedPosts();
          context.read<CategoryProvider>().fetchCategories();
        } catch (_) {}
        Navigator.pop(context, true);
        SnackbarHelper.showSuccess(
          context,
          isEditing ? 'Post updated successfully' : 'Post created and saved!',
        );
      } else {
        SnackbarHelper.showError(context, admin.errorMessage ?? 'Operation failed');
      }
    }
  }

  void _showQuickAddCategoryDialog() {
    final catNameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add New Category'),
        content: TextField(
          controller: catNameController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Category Name (e.g. Tools, Games)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = catNameController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              final admin = context.read<AdminProvider>();
              final success = await admin.createCategory(name);
              if (success && mounted) {
                await admin.fetchCategories();
                await context.read<CategoryProvider>().fetchCategories();
                setState(() {
                  final created = admin.categories.firstWhere(
                    (c) => c.name.toLowerCase() == name.toLowerCase(),
                    orElse: () => admin.categories.first,
                  );
                  _selectedCategoryId = created.id;
                });
                SnackbarHelper.showSuccess(context, 'Category "$name" created');
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.post != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Post' : 'Create Post'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Image Section
                    _buildImageSection(admin),
                    const SizedBox(height: 20),

                    // Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Post Title',
                      hint: 'Enter title (e.g. Boriif Cleaner, Super App)',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Title is required';
                        }
                        if (value.trim().length < 2) {
                          return 'Title must be at least 2 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Post Code (Optional custom code e.g. APP-01)
                    _buildTextField(
                      controller: _codeController,
                      label: 'Post Code (Optional, e.g. APP-01)',
                      hint: 'Leave blank to automatically generate',
                    ),
                    const SizedBox(height: 16),

                    // Category Selection
                    _buildCategoryDropdown(admin),
                    const SizedBox(height: 16),

                    // Short Description
                    _buildTextField(
                      controller: _shortDescController,
                      label: 'Short Description',
                      hint: 'Brief summary displayed on home cards',
                      minLines: 2,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Short description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Full Description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Full Description',
                      hint: 'Detailed overview, features, guide...',
                      minLines: 4,
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full description is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Download Link (Play Store or Direct URL for "Get it now")
                    _buildTextField(
                      controller: _playStoreUrlController,
                      label: 'Download / App Link ("Get it now" URL, Optional)',
                      hint: 'https://play.google.com/store/apps/details?id=... or direct link',
                    ),
                    const SizedBox(height: 16),

                    // External Website Link (Optional)
                    _buildTextField(
                      controller: _externalUrlController,
                      label: 'External Website Link (Optional)',
                      hint: 'https://example.com',
                    ),
                    const SizedBox(height: 16),

                    // Status (Published / Draft)
                    _buildPublishToggle(),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        icon: admin.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.check_circle_outline, size: 22),
                        label: Text(
                          admin.isLoading
                              ? 'Saving...'
                              : (isEditing ? 'Update Post' : 'Save & Publish Post'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        onPressed: admin.isLoading ? null : _submitForm,
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewImage() {
    if (_selectedImage != null) {
      return Image.file(
        _selectedImage!,
        fit: BoxFit.contain,
      );
    }
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      if (_uploadedImageUrl!.startsWith('data:image')) {
        try {
          final base64String = _uploadedImageUrl!.split(',').last;
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
            ),
          );
        } catch (_) {}
      }
      return Image.network(
        _uploadedImageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildImageSection(AdminProvider admin) {
    final hasImage = _selectedImage != null ||
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Post Image (Full Display)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: admin.isLoading ? null : _pickImage,
          child: Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasImage ? AppColors.cyan : AppColors.textSecondary.withValues(alpha: 0.4),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
              color: AppColors.surface.withValues(alpha: 0.6),
            ),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: _buildPreviewImage(),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                              _uploadedImageUrl = null;
                              _imageUrlController.clear();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.cyan.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to upload image from device',
                        style: TextStyle(
                          color: AppColors.cyan,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Direct Cloudinary upload & offline device cache',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 10),
        // Image URL alternative
        TextFormField(
          controller: _imageUrlController,
          decoration: InputDecoration(
            hintText: 'Or paste external image URL',
            prefixIcon: const Icon(Icons.link, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: (value) {
            setState(() {
              if (value.trim().isNotEmpty) {
                _uploadedImageUrl = value.trim();
              } else if (_selectedImage == null) {
                _uploadedImageUrl = null;
              }
            });
          },
        ),
        if (admin.isLoading)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Processing image...', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int minLines = 1,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          minLines: minLines,
          maxLines: maxLines,
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AdminProvider admin) {
    // Collect all available categories (from admin + category provider)
    final categories = admin.categories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Category', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Category', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.cyan,
                padding: EdgeInsets.zero,
                minimumSize: const Size(50, 30),
              ),
              onPressed: _showQuickAddCategoryDialog,
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (categories.isEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.cyan.withValues(alpha: 0.08),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.cyan, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No categories exist yet. Click "+ Add Category" to create one!',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          )
        else
          DropdownButtonFormField<String>(
            value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
            decoration: InputDecoration(
              hintText: 'Select category',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: categories
                .map<DropdownMenuItem<String>>((cat) => DropdownMenuItem<String>(
                      value: cat.id,
                      child: Text(cat.name.isNotEmpty ? cat.name : 'Unnamed'),
                    ))
                .toList(),
            onChanged: (String? value) {
              setState(() => _selectedCategoryId = value);
            },
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please select a category';
              return null;
            },
          ),
      ],
    );
  }

  Widget _buildPublishToggle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Publish Status', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDraft = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isDraft ? AppColors.cyan : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomLeft: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Published (Visible to all)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isDraft ? Colors.black : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDraft = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isDraft ? AppColors.purple : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Draft (Admin only)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDraft ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
