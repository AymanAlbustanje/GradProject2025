import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import '../../Logic/blocs/item_bloc.dart';
import 'item_screen.dart';
import 'discover_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'household_screen.dart';

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainScreen({super.key, required this.themeNotifier});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navBarBackgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartStock'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'add') {
                _showAddHouseholdDialog(context);
              } else if (value == 'view') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HouseholdScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'add', child: Text('Create a Household')),
              const PopupMenuItem(value: 'view', child: Text('Show My Households')),
            ],
          ),
        ],
      ),
      body: _buildCurrentScreen(),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        height: 60,
        decoration: BoxDecoration(
          color: navBarBackgroundColor,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.0),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFF0078D4),
            unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'To Buy'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return BlocProvider(
          create: (context) => ItemBloc(),
          child: const ItemScreen(),
        );
      case 1:
        return const DiscoverScreen();
      case 2:
        return const StatisticsScreen();
      case 3:
        return SettingsScreen(themeNotifier: widget.themeNotifier);
      default:
        return const SizedBox.shrink();
    }
  }

  void _showAddHouseholdDialog(BuildContext context) {
    final TextEditingController householdNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create Household'),
          content: TextField(
            controller: householdNameController,
            decoration: const InputDecoration(labelText: 'Household Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final householdName = householdNameController.text.trim();
                if (householdName.isNotEmpty) {
                  // Call backend to create household
                  context.read<HouseholdBloc>().add(CreateHousehold(name: householdName));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Household created successfully!')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}