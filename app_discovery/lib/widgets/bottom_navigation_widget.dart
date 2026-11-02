import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/localization/app_strings.dart';
import '../providers/settings_provider.dart';

class BottomNavigationWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigationWidget({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final lang = settings.language;

        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.access_time),
              label: AppStrings.get('navigation', 'home', lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.category),
              label: AppStrings.get('navigation', 'categories', lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border),
              label: AppStrings.get('navigation', 'favorites', lang),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person),
              label: AppStrings.get('navigation', 'profile', lang),
            ),
          ],
        );
      },
    );
  }
}
