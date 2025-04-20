import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'Logic/blocs/Home/home_bloc.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/discover_screen.dart';
import 'presentation/screens/statistics_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(),
      child: MaterialApp(
        title: 'Smart Stock',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: const Color(0xFF54ACE3), // Set primary color
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF54ACE3), // Use the color for the color scheme
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF54ACE3), // AppBar color
            foregroundColor: Colors.white, // Text and icon color in AppBar
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const DiscoverScreen(),
    const StatisticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartStock'),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
        ],
      ),
    );
  }
}