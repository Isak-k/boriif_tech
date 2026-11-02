import 'package:flutter/material.dart';

/// Widget for creating/editing posts
class PostFormWidget extends StatefulWidget {
  final String title;
  final VoidCallback onSave;
  final Function(Map<String, String>) onFormData;
  final bool isLoading;
  final String? initialTitle;
  final String? initialCode;
  final String? initialDescription;
  final String? initialShortDescription;
  final String? initialPostType;
  final String? initialCategoryId;
  final List<String> categories;

  const PostFormWidget({
    super.key,
    required this.title,
    required this.onSave,
    required this.onFormData,
    required this.isLoading,
    required this.categories,
    this.initialTitle,
    this.initialCode,
    this.initialDescription,
    this.initialShortDescription,
    this.initialPostType,
    this.initialCategoryId,
  });

  @override
  State<PostFormWidget> createState() => _PostFormWidgetState();
}

class _PostFormWidgetState extends State<PostFormWidget> {
  late TextEditingController _titleController;
  late TextEditingController _codeController;
  late TextEditingController _shortDescController;
  late TextEditingController _descriptionController;
  late TextEditingController _playStoreUrlController;
  late TextEditingController _externalUrlController;
  
  String? _selectedPostType;
  String? _selectedCategory;
  
  final _formKey = GlobalKey<FormState>();
  static const List<String> postTypes = ['app', 'article', 'job'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _codeController = TextEditingController(text: widget.initialCode);
    _shortDescController = TextEditingController(text: widget.initialShortDescription);
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _playStoreUrlController = TextEditingController();
    _externalUrlController = TextEditingController();
    
    _selectedPostType = widget.initialPostType ?? 'article';
    _selectedCategory = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _codeController.dispose();
    _shortDescController.dispose();
    _descriptionController.dispose();
    _playStoreUrlController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.onFormData({
        'title': _titleController.text.trim(),
        'code': _codeController.text.trim(),
        'shortDescription': _shortDescController.text.trim(),
        'description': _descriptionController.text.trim(),
        'postType': _selectedPostType ?? 'article',
        'categoryId': _selectedCategory ?? '',
        'playStoreUrl': _playStoreUrlController.text.trim(),
        'externalUrl': _externalUrlController.text.trim(),
      });
      widget.onSave();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Post Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Post Code (Optional)
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  hintText: 'Post Code (e.g. APP-01, optional)',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),

              // Short Description
              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(
                  hintText: 'Short Description (1-2 sentences)',
                  prefixIcon: Icon(Icons.short_text),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a short description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Full Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Full Description',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter full description';
                  }
                  if (value.length < 20) {
                    return 'Description must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Post Type
              DropdownButtonFormField<String>(
                initialValue: _selectedPostType,
                decoration: const InputDecoration(
                  hintText: 'Post Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: postTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedPostType = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a post type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  hintText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem(
                    value: cat,
                    child: Text(cat),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Optional: Play Store URL
              TextFormField(
                controller: _playStoreUrlController,
                decoration: const InputDecoration(
                  hintText: 'Play Store URL (Optional)',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Optional: External URL
              TextFormField(
                controller: _externalUrlController,
                decoration: const InputDecoration(
                  hintText: 'External URL (Optional)',
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.isLoading ? null : _submitForm,
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save Post'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
