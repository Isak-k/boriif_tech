import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../services/url_launcher_service.dart';
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

  String? _selectedPostType;
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

    _selectedPostType = widget.post?.postType ?? 'article';
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

  bool _validateForm(AdminProvider admin) {
    if (!_formKey.currentState!.validate()) return false;

    if (_selectedCategoryId == null) {
      SnackbarHelper.showError(context, 'Please select a category');
      return false;
    }

    // App posts require Play Store URL
    if (_selectedPostType == 'app' && _playStoreUrlController.text.isEmpty) {
      SnackbarHelper.showError(context, 'App posts require a Google Play Store URL');
      return false;
    }

    // App posts require image
    final hasImage = _selectedImage != null ||
        (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) ||
        _imageUrlController.text.trim().isNotEmpty;
    if (_selectedPostType == 'app' && !hasImage) {
      SnackbarHelper.showError(context, 'App posts require an image (upload or paste URL)');
      return false;
    }

    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateForm(context.read<AdminProvider>())) return;

    final admin = context.read<AdminProvider>();

    if (_imageUrlController.text.trim().isNotEmpty) {
      _uploadedImageUrl = _imageUrlController.text.trim();
    }

    // Upload image if selected
    if (_selectedImage != null) {
      await _uploadImage(admin);
    }

    if (_uploadedImageUrl == null && _imageUrlController.text.trim().isNotEmpty) {
      _uploadedImageUrl = _imageUrlController.text.trim();
    }

    if (_uploadedImageUrl == null && _selectedPostType == 'app') {
      SnackbarHelper.showError(context, 'Image upload or URL required for app posts');
      return;
    }

    final isEditing = widget.post != null;
    bool success;

    if (isEditing) {
      success = await admin.updatePost(
        postId: widget.post!.id,
        title: _titleController.text,
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        shortDescription: _shortDescController.text,
        description: _descriptionController.text,
        postType: _selectedPostType!,
        categoryId: _selectedCategoryId!,
        imageUrl: _uploadedImageUrl,
        playStoreUrl: _playStoreUrlController.text.isEmpty
            ? null
            : _playStoreUrlController.text,
        externalUrl: _externalUrlController.text.isEmpty
            ? null
            : _externalUrlController.text,
        isPublished: !_isDraft,
      );
    } else {
      final postId = await admin.createPost(
        title: _titleController.text,
        code: _codeController.text.trim().isNotEmpty ? _codeController.text.trim() : null,
        shortDescription: _shortDescController.text,
        description: _descriptionController.text,
        postType: _selectedPostType!,
        categoryId: _selectedCategoryId!,
        imageUrl: _uploadedImageUrl,
        playStoreUrl: _playStoreUrlController.text.isEmpty
            ? null
            : _playStoreUrlController.text,
        externalUrl: _externalUrlController.text.isEmpty
            ? null
            : _externalUrlController.text,
        isPublished: !_isDraft,
      );
      success = postId != null;
    }

    if (mounted) {
      if (success) {
        // Refresh PostProvider so Home screen and Category screens see the new post immediately!
        try {
          context.read<PostProvider>().fetchPublishedPosts();
        } catch (_) {}
        Navigator.pop(context, true);
      } else {
        SnackbarHelper.showError(context, admin.errorMessage ?? 'Operation failed');
      }
    }
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
                    // Image picker
                    _buildImageSection(admin),
                    const SizedBox(height: 24),

                    // Title
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Post title',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Title is required';
                        }
                        if (value.length < 3) {
                          return 'Title must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Post Code (Optional custom code e.g. APP-01)
                    _buildTextField(
                      controller: _codeController,
                      label: 'Post Code (Optional, e.g. APP-01)',
                      hint: 'Leave blank to auto-generate',
                    ),
                    const SizedBox(height: 16),

                    // Short description
                    _buildTextField(
                      controller: _shortDescController,
                      label: 'Short Description',
                      hint: 'Brief description for listing',
                      minLines: 2,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Short description is required';
                        }
                        if (value.length < 10) {
                          return 'At least 10 characters required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Full description
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Full Description',
                      hint: 'Detailed description',
                      minLines: 4,
                      maxLines: 8,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Description is required';
                        }
                        if (value.length < 20) {
                          return 'At least 20 characters required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Post type
                    _buildDropdownField(
                      label: 'Post Type',
                      value: _selectedPostType,
                      items: const ['app', 'article', 'job'],
                      onChanged: (value) {
                        setState(() => _selectedPostType = value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Category
                    _buildCategoryDropdown(admin),
                    const SizedBox(height: 16),

                    // App Play Store URL (conditional)
                    if (_selectedPostType == 'app')
                      Column(
                        children: [
                          _buildTextField(
                            controller: _playStoreUrlController,
                            label: 'Google Play Store URL',
                            hint: 'https://play.google.com/store/apps/details?id=...',
                            validator: (value) {
                              if (_selectedPostType == 'app' && (value == null || value.isEmpty)) {
                                return 'Play Store URL is required for app posts';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // External URL (conditional for article/job)
                    if (_selectedPostType != 'app')
                      Column(
                        children: [
                          _buildTextField(
                            controller: _externalUrlController,
                            label: 'External URL (Optional)',
                            hint: 'https://example.com',
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Draft/Publish toggle
                    _buildPublishToggle(),
                    const SizedBox(height: 24),

                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(isEditing ? 'Update Post' : 'Create Post'),
                        onPressed: admin.isLoading ? null : _submitForm,
                      ),
                    ),
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
        fit: BoxFit.cover,
      );
    }
    if (_uploadedImageUrl != null && _uploadedImageUrl!.isNotEmpty) {
      if (_uploadedImageUrl!.startsWith('data:image')) {
        try {
          final base64String = _uploadedImageUrl!.split(',').last;
          return Image.memory(
            base64Decode(base64String),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.broken_image, color: Colors.white70, size: 40),
            ),
          );
        } catch (_) {}
      }
      return Image.network(
        _uploadedImageUrl!,
        fit: BoxFit.cover,
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
          'Post Image',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: admin.isLoading ? null : _pickImage,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: hasImage ? AppColors.cyan : AppColors.textSecondary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface.withOpacity(0.5),
            ),
            child: hasImage
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildPreviewImage(),
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
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 48,
                        color: AppColors.cyan,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to select image from Gallery',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _imageUrlController,
          decoration: InputDecoration(
            labelText: 'Or Paste Image URL',
            hintText: 'https://example.com/image.png',
            prefixIcon: const Icon(Icons.link),
            suffixIcon: _imageUrlController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _imageUrlController.clear();
                        if (_selectedImage == null) {
                          _uploadedImageUrl = null;
                        }
                      });
                    },
                  )
                : null,
          ),
          onChanged: (val) {
            setState(() {
              if (val.trim().isNotEmpty) {
                _uploadedImageUrl = val.trim();
                _selectedImage = null;
              } else if (_selectedImage == null) {
                _uploadedImageUrl = null;
              }
            });
          },
        ),
        if (admin.isLoading)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                const Text('Uploading...'),
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

  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: items
              .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item.toUpperCase()),
              ))
              .toList(),
          onChanged: onChanged,
          validator: (value) {
            if (value == null) return 'Please select a type';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AdminProvider admin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: admin.categories
              .map<DropdownMenuItem<String>>((cat) => DropdownMenuItem<String>(
                value: cat.id,
                child: Text(cat.name ?? 'Unnamed'),
              ))
              .toList(),
          onChanged: (String? value) {
            setState(() => _selectedCategoryId = value);
          },
          validator: (value) {
            if (value == null) return 'Please select a category';
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
        Text('Status', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.textSecondary),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDraft = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isDraft ? AppColors.cyan : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(7),
                        bottomLeft: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Draft',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _isDraft ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _isDraft = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isDraft ? Colors.green : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(7),
                        bottomRight: Radius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Publish',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: !_isDraft ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
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
