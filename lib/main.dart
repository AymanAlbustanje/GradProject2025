import 'package:flutter/material.dart';
import 'package:gradproject2025/presentation/screens/notifications_screen.dart';
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
    final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'Smart Stock',
          debugShowCheckedModeBanner: false,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeMode,
          home: MainScreen(themeNotifier: themeNotifier),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData.light().copyWith(
      primaryColor: const Color(0xFF54ACE3),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF54ACE3),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        toolbarHeight: 52,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
        ),
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
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData.dark().copyWith(
      primaryColor: const Color(0xFF1E1E1E),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        toolbarHeight: 52, // Set the height for all AppBars
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
        ),
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
      appBar: AppBar(
        title: const Text('SmartStock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen()));
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51), // Equivalent to 20% opacity
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
          currentIndex: _currentIndex,
          selectedItemColor: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: Theme.of(context).bottomNavigationBarTheme.unselectedItemColor,
          showSelectedLabels: true,
          showUnselectedLabels: false,
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
    );
  }
}
