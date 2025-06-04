// ignore_for_file: deprecated_member_use, empty_catches

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/Logic/blocs/to_buy_bloc.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import 'package:gradproject2025/data/DataSources/to_buy_service.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ListViewMode { currentHousehold, allHouseholds }

class ToBuyScreen extends StatefulWidget {
  const ToBuyScreen({super.key});

  @override
  State<ToBuyScreen> createState() => _ToBuyScreenState();
}

class _ToBuyScreenState extends State<ToBuyScreen> {
  static const String _selectedViewModeKey = 'toBuyScreen_selectedViewMode';
  ListViewMode _currentView = ListViewMode.currentHousehold; // Default
  Map<String, List<Item>> _groupedAllHouseholdsItems = {};
  bool _isLoadingAllItems = false;

  @override
  void initState() {
    super.initState();
    _loadPreferencesAndInitialData();
  }

  Future<void> _loadPreferencesAndInitialData() async {
    await _loadSelectedViewPreference();
    if (_currentView == ListViewMode.allHouseholds) {
      await _loadAllHouseholdsItems();
    } else {
      _loadToBuyItems(); 
    }
  }

  Future<void> _loadSelectedViewPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedViewIndex = prefs.getInt(_selectedViewModeKey);
    if (savedViewIndex != null && mounted) {
      setState(() {
        _currentView = ListViewMode.values[savedViewIndex];
      });
    }
  }

  Future<void> _saveSelectedViewPreference(ListViewMode viewMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_selectedViewModeKey, viewMode.index);
  }

  Future<void> _loadToBuyItems() async {
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      final String householdIdStr = currentHouseholdState.household.id.toString();
      context.read<ToBuyBloc>().add(LoadToBuyItems(householdId: householdIdStr));
    }
  }

  Future<void> _loadAllHouseholdsItems() async {
    if (!mounted) return;

    setState(() {
      _isLoadingAllItems = true;
      _groupedAllHouseholdsItems = {};
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token not found');

      final userId = prefs.getString('userId');
      if (kDebugMode) {
        print('Loading all households items with userId: "$userId"');
      }

      if (userId == null || userId.isEmpty) {
        setState(() {
          _isLoadingAllItems = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User ID not found. Please log in again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/household-items/all-to-buy-itmes-in-all-households-user-in?userId=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('===== GET ALL HOUSEHOLDS ITEMS RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> rawItemsData = responseData['items'] ?? [];
        
        Map<String, List<Item>> tempGroupedItems = {};
        for (var rawItem in rawItemsData) {
          final item = Item(
            id: rawItem['id']?.toString(),
            name: rawItem['item_name'] ?? 'Unknown Item',
            photoUrl: rawItem['item_photo'],
            category: rawItem['category'],
            location: 'to_buy',
            price: rawItem['price'] != null ? double.tryParse(rawItem['price'].toString()) : null,
          );
          final String householdName = rawItem['household_name'] ?? 'Unknown Household';
          if (tempGroupedItems.containsKey(householdName)) {
            tempGroupedItems[householdName]!.add(item);
          } else {
            tempGroupedItems[householdName] = [item];
          }
        }

        setState(() {
          _groupedAllHouseholdsItems = tempGroupedItems;
          _isLoadingAllItems = false;
        });

      } else {
        String errorMessage = 'Failed to load items from all households';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
            if (errorData['errors'] != null && errorData['errors'] is List && errorData['errors'].isNotEmpty) {
              final firstError = errorData['errors'][0];
              if (firstError['field'] == 'userId' && firstError['message'] != null) {
                errorMessage = 'User ID error: ${firstError['message']}';
              }
            }
          }
        } catch (e) {
        }
        setState(() {
          _isLoadingAllItems = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingAllItems = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading all households items: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
  
  Widget _buildEmptyStateWidget({required String title, required String message, required IconData icon, Color? iconColor}) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final titleColor = isDarkMode ? Colors.grey[300] : Colors.grey[700];

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: iconColor ?? (isDarkMode ? Colors.grey[600] : Colors.grey[400])),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: titleColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 15, color: textColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final scaffoldBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom:12.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Shopping List',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Show items for:',
                      style: TextStyle(fontSize: 14, color: subtitleColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800]?.withOpacity(0.7) : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ListViewMode>(
                            value: _currentView,
                            isExpanded: true,
                            dropdownColor: isDarkMode ? Colors.grey[850] : Colors.white,
                            icon: Icon(Icons.arrow_drop_down_rounded, color: subtitleColor, size: 28),
                            style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500),
                            onChanged: (ListViewMode? newValue) async {
                              if (newValue != null) {
                                setState(() {
                                  _currentView = newValue;
                                });
                                await _saveSelectedViewPreference(newValue); // Save preference
                                if (newValue == ListViewMode.allHouseholds) {
                                  _loadAllHouseholdsItems();
                                } else {
                                  _loadToBuyItems();
                                }
                              }
                            },
                            items: [
                              DropdownMenuItem(
                                value: ListViewMode.currentHousehold,
                                child: Text('Current Household', style: TextStyle(color: textColor)),
                              ),
                              DropdownMenuItem(
                                value: ListViewMode.allHouseholds,
                                child: Text('All My Households', style: TextStyle(color: textColor)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                if (_currentView == ListViewMode.currentHousehold) {
                  await _loadToBuyItems();
                } else {
                  await _loadAllHouseholdsItems();
                }
              },
              color: primaryColor,
              backgroundColor: Theme.of(context).cardColor,
              child: _currentView == ListViewMode.currentHousehold
                  ? BlocConsumer<ToBuyBloc, ToBuyState>(
                      listener: (context, state) {
                        if (state is ToBuyError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is ToBuyLoading) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (state is ToBuyLoaded) {
                          final items = state.items;
                          return items.isEmpty
                              ? _buildEmptyStateWidget(
                                title: 'Shopping List Empty',
                                message: 'Items you need to buy for this household will appear here.',
                                icon: Icons.add_shopping_cart_rounded,
                               )
                              : _buildItemsList(items, isDarkMode, textColor, subtitleColor ?? Colors.grey, primaryColor);
                        } else if (state is ToBuyError) {
                           return _buildEmptyStateWidget(
                                title: 'Error Loading Items',
                                message: 'Could not load shopping list: ${state.error}. Pull down to try again.',
                                icon: Icons.error_outline_rounded,
                                iconColor: Colors.red[300],
                               );
                        }
                        return const SizedBox.shrink();
                      },
                    )
                  : _isLoadingAllItems
                      ? const Center(child: CircularProgressIndicator())
                      : _groupedAllHouseholdsItems.isEmpty
                          ? _buildEmptyStateWidget(
                                title: 'No Items Across Households',
                                message: 'Shopping lists for all your households are currently empty.',
                                icon: Icons.search_off_rounded,
                            )
                          : _buildAllHouseholdsItemsList(_groupedAllHouseholdsItems, isDarkMode, textColor, subtitleColor ?? Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<Item> items, bool isDarkMode, Color textColor, Color subtitleColor, Color primaryColor) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          elevation: isDarkMode ? 1.0 : 2.0,
          shadowColor: isDarkMode ? Colors.black.withOpacity(0.5) : Colors.grey.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            leading: item.photoUrl != null && item.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item.photoUrl!,
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(width: 55, height: 55, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8.0)), child: Icon(Icons.shopping_bag_outlined, size: 30, color: Colors.grey[600])),
                    ),
                  )
                : Container(width: 55, height: 55, decoration: BoxDecoration(color: isDarkMode ? Colors.grey[700] : Colors.grey[200], borderRadius: BorderRadius.circular(8.0)), child: Icon(Icons.shopping_bag_outlined, size: 30, color: isDarkMode ? Colors.grey[300] : Colors.grey[600])),
            title: Text(
              item.name,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.5, color: textColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: item.category != null && item.category!.isNotEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      item.category!,
                      style: TextStyle(color: subtitleColor, fontSize: 13.5),
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.add_home_work_outlined, color: Colors.green[600], size: 26),
                  tooltip: 'Move to In-House',
                  onPressed: () => _showMoveToHouseDialog(context, item),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: subtitleColor), // Standard icon
                  tooltip: "More options",
                  color: Theme.of(context).cardColor, // Use card color for menu background
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Standard shape
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'update',
                      child: ListTile( // Use ListTile for standard appearance
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile( // Use ListTile for standard appearance
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'update') {
                      _showUpdateItemDialog(context, item);
                    } else if (value == 'delete') {
                      _showDeleteConfirmDialog(context, item);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllHouseholdsItemsList(Map<String, List<Item>> groupedItems, bool isDarkMode, Color textColor, Color subtitleColor) {
    final householdNames = groupedItems.keys.toList();
    householdNames.sort();


    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      itemCount: householdNames.length,
      itemBuilder: (context, sectionIndex) {
        final householdName = householdNames[sectionIndex];
        final itemsInHousehold = groupedItems[householdName]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
              child: Text(
                householdName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor.withOpacity(0.9),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsInHousehold.length,
              itemBuilder: (context, itemIndex) {
                final item = itemsInHousehold[itemIndex];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                  elevation: isDarkMode ? 0.8 : 1.5,
                  shadowColor: isDarkMode ? Colors.black.withOpacity(0.4) : Colors.grey.withOpacity(0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                    leading: item.photoUrl != null && item.photoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              item.photoUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(width: 50, height: 50, decoration: BoxDecoration(color: isDarkMode ? Colors.grey[700] : Colors.grey[200], borderRadius: BorderRadius.circular(8.0)), child: Icon(Icons.broken_image_outlined, size: 28, color: subtitleColor)),
                            ),
                          )
                        : Container(width: 50, height: 50, decoration: BoxDecoration(color: isDarkMode ? Colors.grey[700] : Colors.grey[200], borderRadius: BorderRadius.circular(8.0)), child: Icon(Icons.shopping_bag_outlined, size: 28, color: isDarkMode ? Colors.grey[300] : Colors.grey[600])),
                    title: Text(
                      item.name,
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: item.category != null && item.category!.isNotEmpty
                        ? Padding(
                            padding: const EdgeInsets.only(top: 3.0),
                            child: Text(
                              item.category!,
                              style: TextStyle(color: subtitleColor, fontSize: 13),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
            if (sectionIndex < householdNames.length - 1)
              Divider(height: 20, thickness: 0.8, indent: 16, endIndent: 16, color: isDarkMode ? Colors.grey[800] : Colors.grey[300]),
          ],
        );
      },
    );
  }

  void _showMoveToHouseDialog(BuildContext context, Item item) {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot move item - missing item ID.')));
      return;
    }
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is! CurrentHouseholdSet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a household first.')));
      return;
    }

    final householdId = currentHouseholdState.household.id;
    final priceController = TextEditingController(text: item.price?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate = item.expirationDate;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dialogBackgroundColor = isDarkMode ? const Color(0xFF2c2c2e) : Colors.white; 
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100]!.withOpacity(0.7);

    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: dialogBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.add_home_work_outlined, color: primaryColor, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Move ${item.name} to In-House',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enter purchased item details:',
                        style: TextStyle(color: subtitleColor, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: priceController,
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          hintText: '0.00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.attach_money_rounded, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          hintStyle: TextStyle(color: subtitleColor?.withOpacity(0.7)),
                          filled: true,
                          fillColor: inputFillColor,
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 1.5),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Please enter a price';
                          final price = double.tryParse(value.trim());
                          if (price == null) return 'Please enter a valid number';
                          if (price < 0) return 'Price cannot be negative';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedExpirationDate ?? DateTime.now().add(const Duration(days:1)),
                            firstDate: DateTime.now().add(const Duration(days:1)), 
                            lastDate: DateTime.now().add(const Duration(days: 1825)), 
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context).colorScheme.copyWith(
                                        primary: primaryColor,
                                        onPrimary: Colors.white,
                                        surface: dialogBackgroundColor,
                                        onSurface: textColor,
                                      ),
                                  dialogBackgroundColor: dialogBackgroundColor,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedExpirationDate = picked;
                            });
                          }
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.transparent), 
                            borderRadius: BorderRadius.circular(12.0),
                            color: inputFillColor,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined, color: primaryColor.withOpacity(0.8), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedExpirationDate == null
                                      ? 'Expiration Date (Optional)'
                                      : 'Expires on: ${DateFormat.yMd().format(selectedExpirationDate!)}',
                                  style: TextStyle(color: selectedExpirationDate == null ? subtitleColor : textColor),
                                ),
                              ),
                              if (selectedExpirationDate != null)
                                IconButton(
                                  icon: Icon(Icons.clear_rounded, color: subtitleColor, size: 20),
                                  tooltip: "Clear date",
                                  onPressed: () {
                                    setStateDialog(() {
                                      selectedExpirationDate = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: subtitleColor),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.move_to_inbox_rounded, size: 18),
                  label: const Text('MOVE TO IN-HOUSE'),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final price = double.parse(priceController.text.trim());
                      final toBuyService = ToBuyService(baseUrl: ApiConstants.baseUrl);

                      showDialog(
                        context: dialogContext,
                        barrierDismissible: false,
                        builder: (context) => Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor))),
                      );

                      final success = await toBuyService.moveItemToHouse(
                        householdItemId: int.parse(item.id!),
                        householdId: householdId,
                        price: price,
                        expirationDate: selectedExpirationDate,
                      );
                      
                      if (dialogContext.mounted) Navigator.pop(dialogContext); 
                      if (dialogContext.mounted) Navigator.pop(dialogContext); 

                      if (parentContext.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(content: Text('${item.name} moved to in-house.'), duration: const Duration(seconds: 2)),
                          );
                          Future.delayed(const Duration(milliseconds: 100), () { 
                            if (parentContext.mounted) {
                              parentContext.read<ToBuyBloc>().add(LoadToBuyItems(householdId: householdId.toString()));
                              parentContext.read<InHouseBloc>().add(LoadHouseholdItems(householdId: householdId.toString()));
                            }
                          });
                        } else {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(content: Text('Failed to move item. Please try again.'), backgroundColor: Colors.red, duration: Duration(seconds: 3)),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, Item item) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final dialogBackgroundColor = isDarkMode ? const Color(0xFF2c2c2e) : Colors.white;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final errorColor = Colors.red[400]!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          title: Row(
            children: [
              Icon(Icons.delete_forever_outlined, color: errorColor, size: 26),
              const SizedBox(width: 10),
              Text('Delete Item', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Are you sure you want to permanently delete "${item.name}" from your shopping list?',
            style: TextStyle(color: subtitleColor, fontSize: 15),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('CANCEL', style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w500)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.delete_outline_rounded, size: 18),
              label: const Text('DELETE'),
              onPressed: () {
                Navigator.pop(dialogContext);
                _deleteItem(context, item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(BuildContext context, Item item) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete item - missing item ID.')));
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Authentication token not found');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/household-items/delete-household-item'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'householdItemId': int.parse(item.id!)}),
      );

      if (kDebugMode) {
        print('===== DELETE ITEM RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }
      if (!context.mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} has been deleted')));
        _loadToBuyItems();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete item')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting item: ${e.toString()}')));
    }
  }

  void _showUpdateItemDialog(BuildContext context, Item item) {
    final nameController = TextEditingController(text: item.name);
    final photoUrlController = TextEditingController(text: item.photoUrl ?? '');
    final priceController = TextEditingController(text: item.price?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate = item.expirationDate; 
    String? selectedCategory = item.category;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final dialogBackgroundColor = isDarkMode ? const Color(0xFF2c2c2e) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final inputFillColor = isDarkMode ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[100]!.withOpacity(0.7);

    final List<String> dialogCategories = [
      'Fruits & Vegetables', 'Dairy & Eggs', 'Meat & Seafood', 'Bakery & Bread',
      'Pantry Staples', 'Snacks', 'Beverages', 'Frozen Foods', 
      'Cleaning Supplies', 'Personal Care', 'Baby Items', 'Pet Supplies', 'Others',
    ];
    if (selectedCategory != null && !dialogCategories.contains(selectedCategory) && selectedCategory.isNotEmpty) {
        dialogCategories.add(selectedCategory);
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: dialogBackgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.edit_note_outlined, color: primaryColor, size: 26),
                  const SizedBox(width: 12),
                  Text('Edit Shopping Item', style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Item Name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.label_important_outline_rounded, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          filled: true, fillColor: inputFillColor,
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1.5), borderRadius: BorderRadius.circular(12.0)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Item name is required';
                          if (v.trim().length < 2) return 'Name must be at least 2 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.category_outlined, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          filled: true, fillColor: inputFillColor,
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1.5), borderRadius: BorderRadius.circular(12.0)),
                        ),
                        dropdownColor: dialogBackgroundColor,
                        style: TextStyle(color: textColor),
                        items: dialogCategories.map((String category) {
                          return DropdownMenuItem<String>(value: category, child: Text(category));
                        }).toList(),
                        onChanged: (String? newValue) {
                          setStateDialog(() {
                            selectedCategory = newValue;
                          });
                        },
                        validator: (v) => v == null || v.isEmpty ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price (Optional)',
                          hintText: '0.00',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.attach_money_rounded, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          hintStyle: TextStyle(color: subtitleColor?.withOpacity(0.7)),
                          filled: true, fillColor: inputFillColor,
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1.5), borderRadius: BorderRadius.circular(12.0)),
                        ),
                        validator: (v) {
                          if (v != null && v.trim().isNotEmpty) {
                            if (double.tryParse(v.trim()) == null) return 'Invalid price format';
                            if (double.parse(v.trim()) < 0) return 'Price cannot be negative';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: photoUrlController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Photo URL (Optional)',
                          hintText: 'https://example.com/image.png',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                          prefixIcon: Icon(Icons.link_rounded, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          hintStyle: TextStyle(color: subtitleColor?.withOpacity(0.7)),
                          filled: true, fillColor: inputFillColor,
                          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: primaryColor, width: 1.5), borderRadius: BorderRadius.circular(12.0)),
                        ),
                         validator: (v) {
                            if (v != null && v.trim().isNotEmpty) {
                                final uri = Uri.tryParse(v.trim());
                                if (uri == null || !uri.hasAbsolutePath || (!uri.isScheme('http') && !uri.isScheme('https'))) {
                                    return 'Please enter a valid URL';
                                }
                            }
                            return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              actions: [
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('CANCEL', style: TextStyle(color: subtitleColor, fontWeight: FontWeight.w500))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                  label: const Text('SAVE CHANGES'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext);
                      _updateItem(
                        context,
                        item,
                        name: nameController.text.trim(),
                        category: selectedCategory!,
                        price: priceController.text.trim().isNotEmpty ? double.parse(priceController.text.trim()) : null,
                        photoUrl: photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim(),
                        expirationDate: selectedExpirationDate,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, elevation:0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateItem(
    BuildContext context,
    Item item, {
    required String name,
    required String category,
    String? photoUrl,
    double? price,
    DateTime? expirationDate,
  }) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot update item - missing item ID.')));
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Authentication token not found');

      Map<String, dynamic> requestBody = {
        'householdItemId': int.parse(item.id!),
        'itemName': name,
        'category': category,
      };
      if (photoUrl != null && photoUrl.isNotEmpty) {
        requestBody['itemPhoto'] = photoUrl;
      } else {
        requestBody['itemPhoto'] = null; 
      }

      if (price != null) {
        requestBody['price'] = price;
      } else {
         requestBody['price'] = null; 
      }
      
      if (expirationDate != null) {
        requestBody['expirationDate'] = expirationDate.toIso8601String().split('T')[0];
      } else {
        // requestBody['expirationDate'] = null; 
      }


      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/household-items/edit-household-item'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('===== UPDATE ITEM RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
        print('Request Body: ${jsonEncode(requestBody)}');
      }
      if (!context.mounted) return;
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.name}" has been updated')));
        _loadToBuyItems(); 
        if (_currentView == ListViewMode.allHouseholds) {
          _loadAllHouseholdsItems(); 
        }
      } else {
         final errorData = jsonDecode(response.body);
         final message = errorData['message'] ?? 'Failed to update item';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating item: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }
}