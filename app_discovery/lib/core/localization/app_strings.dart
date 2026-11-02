class AppStrings {
  // Navigation
  static const Map<String, Map<String, String>> navigation = {
    'en': {
      'home': 'Home',
      'categories': 'Categories',
      'favorites': 'Favorites',
      'profile': 'Profile',
    },
    'om': {
      'home': 'Mana Jalaa',
      'categories': 'Caasimaa',
      'favorites': 'Kos Gaarii',
      'profile': 'Galmee',
    },
  };

  // Common
  static const Map<String, Map<String, String>> common = {
    'en': {
      'appName': 'App Discovery',
      'appVersion': 'v1.0.0',
      'loading': 'Loading...',
      'error': 'Error',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'back': 'Back',
      'close': 'Close',
      'confirm': 'Confirm',
      'success': 'Success',
      'warning': 'Warning',
      'noResults': 'No results found',
    },
    'om': {
      'appName': 'App Discovery',
      'appVersion': 'v1.0.0',
      'loading': 'Dirqama jira...',
      'error': 'Dhadhaa',
      'retry': 'Irra deebi\'i',
      'cancel': 'Hir\'isi',
      'save': 'Kuusisi',
      'delete': 'Haqaa',
      'edit': 'Gulaalchisi',
      'back': 'Duuba',
      'close': 'Cufi',
      'confirm': 'Mirkaneessi',
      'success': 'Milkaa\'ina',
      'warning': 'Akeekachuu',
      'noResults': 'Bu\'aa hin argamne',
    },
  };

  // Profile
  static const Map<String, Map<String, String>> profile = {
    'en': {
      'profile': 'Profile',
      'settings': 'Settings',
      'about': 'About',
      'admin': 'Admin',
      'language': 'Language',
      'darkMode': 'Dark Mode',
      'pushNotifications': 'Push Notifications',
      'clearCache': 'Clear Cached Data',
      'freeUpSpace': 'Free up storage space',
      'rateUs': 'Rate Us',
      'shareWithFriends': 'Share with Friends',
      'moreApps': 'More Apps',
      'adminDashboard': 'Admin Dashboard',
      'signOut': 'Sign Out',
      'confirmClearCache': 'Are you sure you want to clear all cached data?',
      'confirmSignOut': 'Are you sure you want to sign out?',
      'cacheSizeCalculating': 'Calculating cache size...',
      'cacheCleared': 'Cache cleared successfully',
      'aboutMessage': 'App Discovery helps you discover, promote, and explore amazing apps, articles, and opportunities.',
    },
    'om': {
      'profile': 'Galmee',
      'settings': 'Sagantaa',
      'about': 'Waa\'ee',
      'admin': 'Bulchiinsaa',
      'language': 'Afaan',
      'darkMode': 'Haala Dubbii',
      'pushNotifications': 'Ililaa Push',
      'clearCache': 'Meeshaan Kuufamee Salphisi',
      'freeUpSpace': 'Bakka iccitii hir\'isi',
      'rateUs': 'Nu Jabeessi',
      'shareWithFriends': 'Michuu Qofa Waliin Qoodi',
      'moreApps': 'Hoggansa App\'ota',
      'adminDashboard': 'Gaba Bulchiinsaa',
      'signOut': 'Ba\'i',
      'confirmClearCache': 'Meeshaan kuufamee hundaa salphisuuf mirkaneessa?',
      'confirmSignOut': 'Ba\'uuf mirkaneessa?',
      'cacheSizeCalculating': 'Hammiiga meeshaa shallagaa jira...',
      'cacheCleared': 'Meeshaa kuufamee milkaa\'ina salphifame',
      'aboutMessage': 'App Discovery gara app\'ota, barreeffamaa, fi karaa midhaa ta\'an keessaniif isinibarbaada.',
    },
  };

  // Home
  static const Map<String, Map<String, String>> home = {
    'en': {
      'discoverApps': 'Discover Apps',
      'recent': 'Recent',
      'featured': 'Featured',
      'viewCount': 'views',
      'getItNow': 'Get it now',
      'readArticle': 'Read Full Article',
      'applyNow': 'Get it now',
    },
    'om': {
      'discoverApps': 'App\'ota Argachuu',
      'recent': 'Yeroo Dhihoo',
      'featured': 'Mirkaneeffame',
      'viewCount': 'ilaalaan',
      'getItNow': 'Amma Argadhaa',
      'readArticle': 'Barreeffama Guutuu Dubbisi',
      'applyNow': 'Amma Argadhaa',
    },
  };

  // Categories
  static const Map<String, Map<String, String>> categories = {
    'en': {
      'categories': 'Categories',
      'selectCategory': 'Select a category',
      'noCategoriesFound': 'No categories found',
    },
    'om': {
      'categories': 'Caasimaa',
      'selectCategory': 'Caasimaa Filadhu',
      'noCategoriesFound': 'Caasimaan hin argamne',
    },
  };

  // Admin
  static const Map<String, Map<String, String>> admin = {
    'en': {
      'adminDashboard': 'Admin Dashboard',
      'adminLogin': 'Admin Login',
      'posts': 'Posts',
      'categories': 'Categories',
      'statistics': 'Statistics',
      'logout': 'Logout',
    },
    'om': {
      'adminDashboard': 'Gaba Bulchiinsaa',
      'adminLogin': 'Seenuun Bulchiinsaa',
      'posts': 'Barreeffamaa',
      'categories': 'Caasimaa',
      'statistics': 'Tilmaamota',
      'logout': 'Ba\'i',
    },
  };

  // Get string by key
  static String get(String section, String key, String language) {
    switch (section) {
      case 'navigation':
        return navigation[language]?[key] ?? navigation['en']![key]!;
      case 'common':
        return common[language]?[key] ?? common['en']![key]!;
      case 'profile':
        return profile[language]?[key] ?? profile['en']![key]!;
      case 'home':
        return home[language]?[key] ?? home['en']![key]!;
      case 'categories':
        return categories[language]?[key] ?? categories['en']![key]!;
      case 'admin':
        return admin[language]?[key] ?? admin['en']![key]!;
      default:
        return key;
    }
  }
}
