import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/admin_provider.dart';
import '../../../providers/post_provider.dart';
import '../../../models/post_model.dart';
import '../../../widgets/snackbar_helper.dart';
import 'create_edit_post_screen.dart';

class PostManagementScreen extends StatefulWidget {
  const PostManagementScreen({super.key});

  @override
  State<PostManagementScreen> createState() => _PostManagementScreenState();
}

class _PostManagementScreenState extends State<PostManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedStatusFilter;
  String? _selectedTypeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAllPosts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Post> _getFilteredPosts(List<Post> posts) {
    var filtered = posts.where((post) {
      // Search filter by title or code
      final query = _searchController.text.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          post.title.toLowerCase().contains(query) ||
          post.code.toLowerCase().contains(query);

      // Status filter
      final matchesStatus = _selectedStatusFilter == null ||
          (_selectedStatusFilter == 'published' && post.isPublished) ||
          (_selectedStatusFilter == 'draft' && !post.isPublished);

      // Type filter
      final matchesType = _selectedTypeFilter == null ||
          post.postType == _selectedTypeFilter;

      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Manage Posts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateEditPostScreen(),
            ),
          );
          if (result == true && mounted) {
            await context.read<AdminProvider>().fetchAllPosts();
            try {
              context.read<PostProvider>().fetchPublishedPosts();
            } catch (_) {}
            SnackbarHelper.showSuccess(context, 'Post created successfully');
          }
        },
      ),
      body: Consumer<AdminProvider>(
        builder: (context, admin, _) {
          if (admin.isLoading && admin.allPosts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final filteredPosts = _getFilteredPosts(admin.allPosts);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search posts...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Filters
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedStatusFilter,
                          hint: const Text('Status'),
                          items: const [
                            DropdownMenuItem(child: Text('All'), value: null),
                            DropdownMenuItem(child: Text('Published'), value: 'published'),
                            DropdownMenuItem(child: Text('Draft'), value: 'draft'),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStatusFilter = value);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedTypeFilter,
                          hint: const Text('Type'),
                          items: const [
                            DropdownMenuItem(child: Text('All'), value: null),
                            DropdownMenuItem(child: Text('App'), value: 'app'),
                            DropdownMenuItem(child: Text('Article'), value: 'article'),
                            DropdownMenuItem(child: Text('Job'), value: 'job'),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedTypeFilter = value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Posts list or empty state
                  if (filteredPosts.isEmpty)
                    _buildEmptyState(context)
                  else
                    _buildPostsList(context, admin, filteredPosts),
                ],
              ),
            ),
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
          children: [
            Icon(
              Icons.article_outlined,
              size: 64,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No posts found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first post to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(
    BuildContext context,
    AdminProvider admin,
    List<Post> posts,
  ) {
    return Column(
      children: posts.map((post) {
        return _buildPostItem(context, admin, post);
      }).toList(),
    );
  }

  Widget _buildPostItem(BuildContext context, AdminProvider admin, Post post) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (post.code.isNotEmpty) ...[
                            _buildBadge('#${post.code}', AppColors.cyan),
                            const SizedBox(width: 8),
                          ],
                          _buildBadge(post.postType, Colors.blue),
                          const SizedBox(width: 8),
                          _buildBadge(
                            post.isPublished ? 'Published' : 'Draft',
                            post.isPublished ? Colors.green : Colors.orange,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Edit'),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CreateEditPostScreen(post: post),
                          ),
                        );
                        if (result == true && mounted) {
                          await admin.fetchAllPosts();
                          SnackbarHelper.showSuccess(
                              context, 'Post updated successfully');
                        }
                      },
                    ),
                    if (!post.isPublished)
                      PopupMenuItem(
                        child: const Text('Publish'),
                        onTap: () async {
                          final success = await admin.publishPost(post.id);
                          if (mounted) {
                            if (success) {
                              try {
                                context.read<PostProvider>().fetchPublishedPosts();
                              } catch (_) {}
                              SnackbarHelper.showSuccess(
                                  context, 'Post published');
                            } else {
                              SnackbarHelper.showError(
                                  context, admin.errorMessage ?? 'Error');
                            }
                          }
                        },
                      )
                    else
                      PopupMenuItem(
                        child: const Text('Unpublish'),
                        onTap: () async {
                          final success = await admin.unpublishPost(post.id);
                          if (mounted) {
                            if (success) {
                              try {
                                context.read<PostProvider>().fetchPublishedPosts();
                              } catch (_) {}
                              SnackbarHelper.showSuccess(
                                  context, 'Post unpublished');
                            } else {
                              SnackbarHelper.showError(
                                  context, admin.errorMessage ?? 'Error');
                            }
                          }
                        },
                      ),
                    PopupMenuItem(
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
                      onTap: () {
                        _showDeleteConfirmation(context, admin, post);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Metadata
            Row(
              children: [
                const Icon(Icons.visibility, size: 15, color: AppColors.cyan),
                const SizedBox(width: 4),
                Text(
                  '${post.viewsCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                const Icon(Icons.favorite, size: 15, color: AppColors.error),
                const SizedBox(width: 4),
                Text(
                  '${post.likesCount}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.calendar_today,
                    size: 15, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  _formatDate(post.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    AdminProvider admin,
    Post post,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Post',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        content: Text(
          'Are you sure you want to delete "${post.title}"? This action cannot be undone.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final success = await admin.deletePost(post.id);
              if (mounted) {
                if (success) {
                  try {
                    context.read<PostProvider>().fetchPublishedPosts();
                  } catch (_) {}
                  SnackbarHelper.showSuccess(context, 'Post deleted');
                } else {
                  SnackbarHelper.showError(
                      context, admin.errorMessage ?? 'Error');
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
