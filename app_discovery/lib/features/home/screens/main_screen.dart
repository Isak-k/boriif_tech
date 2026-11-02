import 'package:flutter/material.dart';
import '../../../widgets/bottom_navigation_widget.dart';
import '../../categories/screens/categories_screen.dart';
import '../../favorites/screens/favorites_screen.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

/// Main container screen holding the 4 primary tabs via IndexedStack
class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int index) {
    if (_currentIndex != index) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(
            showBottomNav: false,
            onTabSelect: _onTabSelected,
          ),
          CategoriesScreen(
            showBottomNav: false,
            onTabSelect: _onTabSelected,
          ),
          FavoritesScreen(
            showBottomNav: false,
            onTabSelect: _onTabSelected,
          ),
          ProfileScreen(
            showBottomNav: false,
            onTabSelect: _onTabSelected,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        currentIndex: _currentIndex,
        onTap: _onTabSelected,
      ),
    );
  }
}
