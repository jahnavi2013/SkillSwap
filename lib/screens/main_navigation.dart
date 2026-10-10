import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'discover_screen.dart';
import 'swaps_screen.dart';
import 'quests_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final String userId;

  const MainNavigation({super.key, required this.userId});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  Widget _buildCurrentScreen() {
    switch (_selectedIndex) {
      case 0:
        return const HomeScreen();

      case 1:
        return const DiscoverScreen();

      case 2:
        return const SwapsScreen();

      case 3:
        return const QuestsScreen();

      case 4:
        return ProfileScreen(userId: widget.userId);

      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildCurrentScreen(),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,

        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),

          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Discover',
          ),

          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            selectedIcon: Icon(Icons.swap_horiz_rounded),
            label: 'Swaps',
          ),

          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events_rounded),
            label: 'Quests',
          ),

          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
