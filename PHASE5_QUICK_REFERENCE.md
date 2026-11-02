# PHASE 5 Quick Reference

## Files Created
| File | Purpose |
|------|---------|
| `admin_dashboard_screen.dart` | Main dashboard with stats and quick actions |
| `post_management_screen.dart` | Post list with search, filter, and inline actions |
| `create_edit_post_screen.dart` | Post creation/editing with image upload |
| `category_management_screen.dart` | Category CRUD |
| `admin_service.dart` | Updated with new methods |
| `admin_provider.dart` | Complete state management |

## Navigation Flow

```
Admin Dashboard
├── Quick Action: Create New Post → Create/Edit Screen
├── Quick Action: Manage Posts → Post Management Screen
│   ├── Search/Filter
│   ├── Edit Post → Create/Edit Screen
│   ├── Publish/Unpublish (inline)
│   └── Delete (with confirmation)
└── Quick Action: Manage Categories → Category Management Screen
    ├── Create Category Dialog
    ├── Edit Category Dialog
    └── Delete Category (with safeguards)
```

## Key Methods

### Dashboard
```dart
admin.loadDashboardStats()     // Load statistics
admin.loadRecentPosts()         // Load recent posts
admin.fetchAllPosts()           // Get all posts for management
admin.fetchCategories()         // Get all categories
```

### Post Operations
```dart
admin.createPost(...)           // Create new post (draft or published)
admin.updatePost(...)           // Update existing post
admin.deletePost(postId)        // Delete post
admin.publishPost(postId)       // Publish draft
admin.unpublishPost(postId)     // Revert to draft
admin.uploadImage(imageFile)    // Upload image
```

### Category Operations
```dart
admin.createCategory(name)      // Create category
admin.updateCategory(id, name)  // Update category
admin.deleteCategory(id)        // Delete category (with check)
admin.fetchCategories()         // Get all categories
```

## UI Components

### Dashboard
- **Stats Cards**: Real-time metrics display
- **Quick Actions**: Tap-able cards for main operations
- **Recent Posts**: Scrollable feed with thumbnails

### Post Management
- **Search Bar**: Type to filter posts
- **Filters**: Status (published/draft) and Type (app/article/job)
- **Post Cards**: Thumbnail, title, badges, metadata
- **Actions**: 3-dot menu per post

### Create/Edit Post
- **Image Section**: Tap to pick, preview, remove
- **Form Fields**: Title, descriptions, type, category
- **Conditional Fields**: URLs based on post type
- **Status Toggle**: Draft or Publish
- **Save Button**: Create or Update

### Categories
- **List**: All categories with IDs
- **Dialogs**: Create/edit inline
- **Actions**: 3-dot menu per category

## Testing Scenarios

### Basic Create & Publish
1. Dashboard → Create New Post
2. Fill required fields
3. Select image
4. Toggle to Publish
5. Save
✓ Check dashboard recent posts

### Edit & Unpublish
1. Manage Posts → Find post
2. Tap menu → Edit
3. Change status to Draft
4. Update
✓ Check post shows Draft badge

### Filter & Search
1. Manage Posts
2. Search for keyword
3. Filter by status/type
✓ Check results match

### Category Management
1. Manage Categories
2. Create new category
3. Edit name
4. Try delete (should work if no posts)
✓ Check operations succeed

## Form Validation

| Field | Rules |
|-------|-------|
| Title | Min 3 chars |
| Short Desc | Min 10 chars |
| Full Desc | Min 20 chars |
| Category | Required |
| Image (app) | Required |
| Play Store URL (app) | Required |
| External URL | Optional |

## Status Badges

- **Published** (Green): Post is live
- **Draft** (Orange): Post not published
- **app** (Blue): App type
- **article** (Blue): Article type
- **job** (Blue): Job type

## Error Messages

| Error | Solution |
|-------|----------|
| "Title is required" | Enter a title |
| "Image upload failed" | Check file size/connection |
| "App posts require Play Store URL" | Enter valid Play Store URL for app type |
| "Cannot delete category with X posts" | Reassign posts first |
| "You do not have admin access" | Login with admin account |

## Statistics Explained

- **Total Posts**: Count of all posts (published + drafts)
- **Published Posts**: Count where isPublished = true
- **Total Views**: Sum of viewsCount across all posts
- **Categories**: Count of category documents

## Timestamps

- **createdAt**: Set when post created, never changes
- **updatedAt**: Updated whenever post is modified
- **publishedAt**: Set when first published, doesn't change on edit

## Image Upload

1. Tap image area
2. Select from gallery
3. Shows preview
4. Uploads to Firebase Storage
5. URL saved to post
6. Path: `posts/{postId}/cover-{timestamp}.ext`

## Workflow Examples

### App Post Workflow
```
Create Draft → Add Image → Add Play Store URL → 
Add Category → Publish → Dashboard shows it
```

### Article Post Workflow
```
Create Draft → Optional Image → Optional URL → 
Add Category → Publish → Dashboard shows it
```

### Edit Post Workflow
```
Open for Edit → Change fields → Image replaces old →
Update Status if needed → Save → List updates
```

### Delete Post Workflow
```
Post Management → 3-dot menu → Delete → 
Confirm dialog → Post removed
```

## State Management

```dart
// Access in widgets
final admin = context.read<AdminProvider>();
final adminWatch = context.watch<AdminProvider>();

// Important properties
admin.dashboardStats       // Map of statistics
admin.allPosts            // List of all posts
admin.recentPosts         // 5 most recent
admin.categories          // All categories
admin.isLoading           // Loading state
admin.errorMessage        // Last error
```

## Common Patterns

### Load data on init
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<AdminProvider>().fetchCategories();
  });
}
```

### Show confirmation
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: Text('Delete Post'),
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(onPressed: () => deleteOperation(), child: Text('Delete')),
    ],
  ),
);
```

### Handle async operation
```dart
final success = await admin.createPost(...);
if (mounted) {
  if (success) {
    SnackbarHelper.showSuccess(context, 'Post created');
    Navigator.pop(context, true);
  } else {
    SnackbarHelper.showError(context, admin.errorMessage);
  }
}
```

## Debugging Tips

1. **Check Firestore**: Verify documents have correct structure
2. **Check Timestamps**: Ensure timestamps are properly formatted
3. **Check Auth**: Verify user is in admins collection
4. **Check Storage**: Images should be in posts/ folder
5. **Check Logs**: Look for error messages in console

## Performance

- Dashboard loads stats on init
- Posts list uses pagination-ready structure
- Images lazy-load
- Categories cached in provider
- Real-time streams available for updates

## Accessibility

- All buttons have clear labels
- Color contrasts follow guidelines
- Loading states indicate progress
- Error messages are clear
- Form validation prevents mistakes

## Responsive Design

- Adapts to different screen sizes
- Cards stack on mobile
- Grid adjusts column count
- Dialogs sized appropriately
- Scrollable content areas

## Browser/Platform Support

- Works on Android and iOS
- Requires Flutter 3.12+
- Firebase SDKs compatible
- Image picker works on both platforms

---

## Quick Start

1. **Access Admin Dashboard**: Navigate from home after admin login
2. **Create Post**: Tap "Create New Post" quick action
3. **Fill Form**: Enter all required fields
4. **Upload Image**: Tap image area, select from gallery
5. **Save**: Choose draft or publish, tap save
6. **Verify**: Check dashboard recent posts or manage posts
7. **Edit**: Tap any post in manage screen to edit
8. **Delete**: Use 3-dot menu, confirm deletion

---

**For detailed info, see PHASE5_IMPLEMENTATION_GUIDE.md**
