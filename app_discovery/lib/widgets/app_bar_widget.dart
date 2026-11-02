import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onLanguagePressed;

  const AppBarWidget({
    super.key,
    required this.title,
    this.onNotificationPressed,
    this.onProfilePressed,
    this.onLanguagePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cyan.withValues(alpha: 0.6), width: 1.5),
                color: Colors.white,
              ),
              child: Image.asset(
                'assets/images/boriif_icon.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.language),
          onPressed: onLanguagePressed,
          tooltip: 'Language',
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: onNotificationPressed,
          tooltip: 'Notifications',
        ),
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.cyan, width: 2),
          ),
          child: IconButton(
            icon: const Icon(Icons.person),
            onPressed: onProfilePressed,
            iconSize: 20,
            tooltip: 'Profile',
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
