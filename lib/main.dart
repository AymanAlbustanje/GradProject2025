import 'package:flutter/material.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/discover_screen.dart';
import 'presentation/screens/statistics_screen.dart';
import 'presentation/screens/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a ValueNotifier to manage the theme state
    final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Smart Stock',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light().copyWith(
            primaryColor: const Color(0xFF54ACE3),
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF54ACE3),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color(0xFF54ACE3),
              unselectedItemColor: Colors.grey,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.black),
              bodyMedium: TextStyle(color: Colors.black87),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: const Color(0xFF1E1E1E),
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color(0xFF1E1E1E),
              selectedItemColor: Color(0xFF0078D4),
              unselectedItemColor: Colors.grey,
            ),
            textTheme: const TextTheme(
              bodyLarge: TextStyle(color: Colors.white),
              bodyMedium: TextStyle(color: Colors.white70),
            ),
          ),
          themeMode: themeMode, // Dynamically switch between light and dark themes
          home: MainScreen(themeNotifier: themeNotifier),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainScreen({super.key, required this.themeNotifier});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SmartStock'), centerTitle: true),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).bottomNavigationBarTheme.backgroundColor, // Dynamic background color
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2), // Subtle shadow
              spreadRadius: 2,
              blurRadius: 10,
              offset: const Offset(0, -2), // Shadow above the bar
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed, // Fixed mode for consistent layout
            backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor, // Dynamic background color
            currentIndex: _currentIndex,
            selectedItemColor:
                Theme.of(context).bottomNavigationBarTheme.selectedItemColor, // Dynamic selected item color
            unselectedItemColor:
                Theme.of(context).bottomNavigationBarTheme.unselectedItemColor, // Dynamic unselected item color
            showSelectedLabels: true, // Show labels for selected items
            showUnselectedLabels: false, // Hide labels for unselected items
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Discover'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
          ),
        ),
      ),
    );
  }
}
