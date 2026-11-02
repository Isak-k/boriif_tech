import 'package:flutter/material.dart';
import '../../features/home/screens/main_screen.dart';
import '../../features/categories/screens/category_posts_screen.dart';
import '../../features/post_details/screens/post_details_screen.dart';
import '../../features/profile/screens/privacy_policy_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../models/category_model.dart';
import '../../models/post_model.dart';

class AppRouter {
  static const String home = '/';
  static const String categories = '/categories';
  static const String favorites = '/favorites';
  static const String profile = '/profile';
  static const String categoryPosts = '/category-posts';
  static const String postDetails = '/post-details';
  static const String privacyPolicy = '/privacy-policy';
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0));
      case categories:
        return MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1));
      case favorites:
        return MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 2));
      case profile:
        return MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 3));
      case categoryPosts:
        final category = settings.arguments as Category?;
        if (category == null) {
          return MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 1));
        }
        return MaterialPageRoute(
          builder: (_) => CategoryPostsScreen(category: category),
        );
      case postDetails:
        Post? initialPost;
        String? postId;
        if (settings.arguments is Post) {
          initialPost = settings.arguments as Post;
          postId = initialPost.id;
        } else if (settings.arguments is String) {
          postId = settings.arguments as String;
        }
        return MaterialPageRoute(
          builder: (_) => PostDetailsScreen(
            postId: postId,
            initialPost: initialPost,
          ),
        );
      case privacyPolicy:
        return MaterialPageRoute(
          builder: (_) => const PrivacyPolicyScreen(),
        );
      case adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
      default:
        return MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0));
    }
  }
}
