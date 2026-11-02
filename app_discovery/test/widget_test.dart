import 'package:flutter_test/flutter_test.dart';
import 'package:app_discovery/models/category_model.dart';
import 'package:app_discovery/models/post_model.dart';
import 'package:app_discovery/models/user_model.dart';
import 'package:app_discovery/core/constants/admin_constants.dart';
import 'package:app_discovery/core/localization/app_strings.dart';
import 'package:app_discovery/providers/settings_provider.dart';

void main() {
  group('Category Model Tests', () {
    test('creates Category model and converts to Map', () {
      final now = DateTime.now();
      final category = Category(
        id: 'cat_tech',
        name: 'Technology',
        createdAt: now,
        updatedAt: now,
      );

      expect(category.id, 'cat_tech');
      expect(category.name, 'Technology');

      final map = category.toFirestore();
      expect(map['name'], 'Technology');
      expect(map['createdAt'], isNotNull);
      expect(map['updatedAt'], isNotNull);
    });

    test('copyWith creates modified clone', () {
      final now = DateTime.now();
      final category = Category(
        id: 'cat_tech',
        name: 'Technology',
        createdAt: now,
        updatedAt: now,
      );

      final updated = category.copyWith(name: 'Software');
      expect(updated.id, 'cat_tech');
      expect(updated.name, 'Software');
      expect(category.name, 'Technology');
    });
  });

  group('Post Model Tests', () {
    test('creates Post model with correct fields', () {
      final now = DateTime.now();
      final post = Post(
        id: 'post_1',
        title: 'Flutter Guide',
        shortDescription: 'Learn Flutter fast',
        description: 'Comprehensive guide to Flutter mobile development.',
        postType: 'article',
        categoryId: 'cat_tech',
        isPublished: true,
        createdAt: now,
        updatedAt: now,
        viewsCount: 42,
      );

      expect(post.id, 'post_1');
      expect(post.title, 'Flutter Guide');
      expect(post.postType, 'article');
      expect(post.viewsCount, 42);
      expect(post.isFavorite, false);

      final map = post.toFirestore();
      expect(map['title'], 'Flutter Guide');
      expect(map['postType'], 'article');
      expect(map['viewsCount'], 42);
      expect(map['isPublished'], true);
    });

    test('Post copyWith toggles isFavorite and updates likesCount and viewsCount', () {
      final now = DateTime.now();
      final post = Post(
        id: 'post_1',
        title: 'App Title',
        shortDescription: 'Short',
        description: 'Long description...',
        postType: 'app',
        categoryId: 'cat_apps',
        isPublished: true,
        createdAt: now,
        updatedAt: now,
        viewsCount: 10,
        likesCount: 5,
        isFavorite: false,
      );

      final favPost = post.copyWith(isFavorite: true, likesCount: 6, viewsCount: 11);
      expect(favPost.isFavorite, true);
      expect(favPost.likesCount, 6);
      expect(favPost.viewsCount, 11);
      expect(post.isFavorite, false);
      expect(post.likesCount, 5);
      expect(post.viewsCount, 10);
    });
  });

  group('User Model Tests', () {
    test('creates AppUser and checks admin role', () {
      final now = DateTime.now();
      final adminUser = AppUser(
        id: 'user_1',
        email: 'hisakkedi@gmail.com',
        isAdmin: true,
        createdAt: now,
        updatedAt: now,
      );

      expect(adminUser.id, 'user_1');
      expect(adminUser.email, 'hisakkedi@gmail.com');
      expect(adminUser.isAdmin, true);

      final map = adminUser.toFirestore();
      expect(map['email'], 'hisakkedi@gmail.com');
      expect(map['isAdmin'], true);
    });
  });

  group('Admin Constants & Authorization Tests', () {
    test('recognizes hisakkedi@gmail.com as authorized admin and super admin', () {
      expect(AdminConstants.isAdminEmail('hisakkedi@gmail.com'), true);
      expect(AdminConstants.isAdminEmail('HISAKKEDI@GMAIL.COM'), true);
      expect(AdminConstants.isAdminEmail(' hisakkedi@gmail.com '), true);
      expect(AdminConstants.isSuperAdmin('hisakkedi@gmail.com'), true);
      expect(AdminConstants.isSuperAdmin('other@gmail.com'), false);
    });

    test('validates super admin default password', () {
      expect(AdminConstants.verifySuperAdminPassword(r'1!2@3#4$5%'), true);
      expect(AdminConstants.verifySuperAdminPassword('wrong_pass'), false);
    });

    test('rejects unauthorized emails', () {
      expect(AdminConstants.isAdminEmail('random@gmail.com'), false);
      expect(AdminConstants.isAdminEmail(''), false);
      expect(AdminConstants.isAdminEmail(null), false);
    });
  });

  group('Localization AppStrings Tests', () {
    test('returns English strings by default or when requested', () {
      expect(AppStrings.get('common', 'appName', 'en'), 'App Discovery');
      expect(AppStrings.get('navigation', 'home', 'en'), 'Home');
      expect(AppStrings.get('navigation', 'categories', 'en'), 'Categories');
      expect(AppStrings.get('navigation', 'favorites', 'en'), 'Favorites');
      expect(AppStrings.get('navigation', 'profile', 'en'), 'Profile');
    });

    test('returns Afaan Oromoo strings for om language code', () {
      expect(AppStrings.get('common', 'appName', 'om'), 'App Discovery');
      expect(AppStrings.get('navigation', 'home', 'om'), 'Mana Jalaa');
      expect(AppStrings.get('navigation', 'categories', 'om'), 'Caasimaa');
      expect(AppStrings.get('navigation', 'favorites', 'om'), 'Kos Gaarii');
      expect(AppStrings.get('navigation', 'profile', 'om'), 'Galmee');
    });

    test('SettingsProvider language helper functions', () {
      final languages = SettingsProvider.getAvailableLanguages();
      expect(languages.length, 2);
      expect(SettingsProvider.getLanguageName('en'), 'English');
      expect(SettingsProvider.getLanguageName('om'), 'Afaan Oromoo');
    });
  });
}
