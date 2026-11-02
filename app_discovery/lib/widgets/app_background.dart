import 'package:flutter/material.dart';

/// Reusable wrapper that renders the geometric obsidian starry wallpaper
/// with an elegant dark overlay for optimal readability.
class AppBackground extends StatelessWidget {
  final Widget child;
  final double overlayOpacity;

  const AppBackground({
    super.key,
    required this.child,
    this.overlayOpacity = 0.25,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Geometric Low-Poly Starry Wallpaper
        Image.asset(
          'assets/images/app_bg.jpg',
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),

        // Subtle obsidian gradient tint overlay for contrast & crystal clarity
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF06090E).withOpacity(overlayOpacity),
                const Color(0xFF06090E).withOpacity(overlayOpacity * 0.7),
                const Color(0xFF06090E).withOpacity(overlayOpacity * 1.15),
              ],
            ),
          ),
        ),

        // Screen content
        child,
      ],
    );
  }
}
