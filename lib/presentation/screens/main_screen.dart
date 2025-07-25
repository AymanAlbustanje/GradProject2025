// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/Logic/blocs/statistics_bloc.dart';
import 'package:gradproject2025/Logic/blocs/to_buy_bloc.dart';
import 'package:gradproject2025/presentation/screens/to_buy_screen.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'in_house_screen.dart';
import 'statistics_screen.dart';
import 'account_screen.dart';
import 'household_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;

  const MainScreen({super.key, required this.themeNotifier});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HouseholdBloc>().add(LoadHouseholds());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final navBarBackgroundColor = isDarkMode ? Colors.grey[850] : Colors.white;
    final primaryColor = const Color(0xFF0078D4);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ToBuy',
          style: GoogleFonts.lato(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: const Color(0xFF0078D4),
          ),
        ),
        actions: [
          BlocBuilder<CurrentHouseholdBloc, CurrentHouseholdState>(
            builder: (context, currentHouseholdState) {
              return BlocBuilder<HouseholdBloc, HouseholdState>(
                builder: (context, householdState) {
                  if (householdState is HouseholdLoaded) {
                    final households = householdState.myHouseholds;
                    String currentHouseholdName = 'Select Household';

                    if (currentHouseholdState is CurrentHouseholdSet) {
                      final currentHousehold = households.firstWhere(
                        (h) => h.id == currentHouseholdState.household.id,
                        orElse: () => currentHouseholdState.household,
                      );
                      currentHouseholdName = currentHousehold.name;
                    }

                    return Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      margin: const EdgeInsets.only(right: 8),
                      child: PopupMenuButton<Household>(
                        tooltip: 'Switch Household',
                        position: PopupMenuPosition.under,
                        onSelected: (household) {
                          context.read<CurrentHouseholdBloc>().add(SetCurrentHousehold(household: household));
                        },
                        offset: const Offset(0, 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.home, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  households.isEmpty ? 'No Households' : currentHouseholdName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down),
                            ],
                          ),
                        ),
                        itemBuilder: (context) {
                          if (households.isEmpty) {
                            return [
                              const PopupMenuItem(enabled: false, child: Text('No households available')),
                              PopupMenuItem(
                                child: TextButton.icon(
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Household'),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showAddHouseholdDialog(context);
                                  },
                                ),
                              ),
                            ];
                          }

                          return [
                            ...households.map((household) {
                              return PopupMenuItem<Household>(
                                value: household,
                                child: Row(
                                  children: [
                                    const Icon(Icons.home, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(household.name)),
                                    if (currentHouseholdState is CurrentHouseholdSet &&
                                        currentHouseholdState.household.id == household.id)
                                      const Icon(Icons.check, size: 18, color: Color(0xFF0078D4)),
                                  ],
                                ),
                              );
                            }),
                            const PopupMenuDivider(),
                            PopupMenuItem(
                              child: TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: const Text('Create New Household'),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAddHouseholdDialog(context);
                                },
                              ),
                            ),
                          ];
                        },
                      ),
                    );
                  } else if (householdState is HouseholdLoading) {
                    return Container(
                      constraints: const BoxConstraints(maxWidth: 180),
                      margin: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: null,
                        icon: const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        label: const Text('Loading...'),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),

          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'view') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const HouseholdScreen())).then((_) {
                  // Refresh the list of households after returning from manage/join screen
                  context.read<HouseholdBloc>().add(LoadHouseholds());
                });
              }
            },
            itemBuilder: (context) => [const PopupMenuItem(value: 'view', child: Text('Manage Households'))],
          ),
        ],
      ),
      body: BlocBuilder<CurrentHouseholdBloc, CurrentHouseholdState>(
        builder: (context, householdState) {
          if (_currentIndex == 3) {
            return AccountScreen(themeNotifier: widget.themeNotifier);
          }

          if (householdState is CurrentHouseholdSet) {
            return _buildCurrentScreen(householdState.household.id);
          } else if (householdState is CurrentHouseholdLoading) {
            return const Center(child: CircularProgressIndicator());
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('No household selected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Please select or create a household to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      _showAddHouseholdDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                    ),
                    child: const Text('Create a Household'),
                  ),
                ],
              ),
            );
          }
        },
      ),
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
            selectedItemColor: primaryColor,
            unselectedItemColor: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'To Buy'),
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'In House'),
              BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Statistics'),
              BottomNavigationBarItem(icon: Icon(Icons.account_box_outlined), label: 'Account'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen(dynamic householdId) {
    final String householdIdStr = householdId.toString();

    switch (_currentIndex) {
      case 0:
        return BlocProvider(
          create: (context) => ToBuyBloc()..add(LoadToBuyItems(householdId: householdIdStr)),
          child: const ToBuyScreen(),
        );
      case 1:
        return BlocProvider(
          create: (context) => InHouseBloc()..add(LoadHouseholdItems(householdId: householdIdStr)),
          child: const InHouseScreen(),
        );
      case 2:
        return BlocProvider(
          create: (context) => StatisticsBloc()..add(LoadStatistics(householdId: householdIdStr)),
          child: const StatisticsScreen(),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _showAddHouseholdDialog(BuildContext context) {
    final TextEditingController householdNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF0078D4);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.home_rounded, color: primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text('Create Household'),
            ],
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: householdNameController,
                  decoration: InputDecoration(
                    labelText: 'Household Name',
                    prefixIcon: Icon(Icons.group_outlined, color: primaryColor.withOpacity(0.8)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primaryColor, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a household name';
                    }
                    if (value.length < 3) {
                      return 'Name must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                const Text(
                  'Create a household to manage your items and shopping lists',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final householdName = householdNameController.text.trim();
                  context.read<HouseholdBloc>().add(
                    CreateHousehold(name: householdName, currentHouseholdBloc: context.read<CurrentHouseholdBloc>()),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Creating household "$householdName"...')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }
}
