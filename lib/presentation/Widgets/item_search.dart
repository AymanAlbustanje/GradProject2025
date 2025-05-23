// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, control_flow_in_finally

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ItemSearchWidget extends StatefulWidget {
  const ItemSearchWidget({super.key});

  @override
  _ItemSearchWidgetState createState() => _ItemSearchWidgetState();
}

class _ItemSearchWidgetState extends State<ItemSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  final int _debounceTime = 500; // milliseconds
  final String _defaultItemPhotoUrl = 'https://i.pinimg.com/736x/82/be/d4/82bed479344270067e3d2171379949b3.jpg';

  final List<String> _categories = [
    'Fruits & Vegetables',
    'Dairy & Eggs',
    'Meat & Seafood',
    'Canned & Jarred',
    'Dry Goods & Pasta',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchText = _searchController.text.trim();

    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (searchText.isEmpty) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (searchText.length < 2) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    _debounceTimer = Timer(Duration(milliseconds: _debounceTime), () {
      final currentSearchText = _searchController.text.trim();
      if (currentSearchText == searchText && currentSearchText.length >= 2) {
        _searchItemsByName(currentSearchText);
      } else if (currentSearchText.isEmpty || currentSearchText.length < 2) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    });
  }

  Future<void> _searchItemsByName(String name) async {
    if (name.length < 2) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/items/search-name'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'name': name}),
      );
      _logApiResponse(response, context: 'Search Items By Name');

      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['items'] ?? [];
        });
      } else {
        setState(() {
          _searchResults = [];
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error searching items: ${response.reasonPhrase}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _logApiResponse(http.Response response, {String? context}) {
    if (kDebugMode) {
      print('===== API RESPONSE ${context != null ? "($context)" : ""} =====');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('============================');
    }
  }

  void _showAddToHouseholdForm(dynamic item) {
    final TextEditingController priceController = TextEditingController();
    // Photo URL controller is removed as the field will be hidden
    // final TextEditingController photoUrlController = TextEditingController(text: item['item_photo'] ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    dynamic selectedHouseholdId; // This will be populated from CurrentHouseholdBloc
    String? selectedCategory = item['category']; // Pre-fill category from item data

    // Get the currently selected household ID
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      selectedHouseholdId = currentHouseholdState.household.id;
    }
    // It's good practice to also load all households if you need to check for general existence
    // or display specific messages related to the overall household state.
    final householdBloc = BlocProvider.of<HouseholdBloc>(context);
    householdBloc.add(LoadHouseholds());


    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        return StatefulBuilder(builder: (stfContext, stfSetState) {
          return BlocBuilder<HouseholdBloc, HouseholdState>(
            // Use bloc instance from above to avoid creating a new one here
            bloc: householdBloc,
            builder: (blocContext, householdState) {
              // This check is for the general case where the user has NO households at all.
              bool noHouseholdsExistAtAll = householdState is HouseholdLoaded && householdState.myHouseholds.isEmpty;

              return AlertDialog(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                title: Row(
                  children: [
                    Icon(Icons.add_shopping_cart, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add ${item['item_name']} to Household',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: primaryColor.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  item['item_photo'] ?? _defaultItemPhotoUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: Icon(Icons.inventory_2_outlined, color: Colors.grey[700], size: 30),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['item_name'],
                                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (item['category'] != null)
                                      Text(
                                        'Category: ${item['category']}',
                                        style: TextStyle(color: subtitleColor, fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Display message if no household is selected or if no households exist at all.
                        if (selectedHouseholdId == null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16), // Add space if message is shown
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: errorColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: errorColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    noHouseholdsExistAtAll
                                      ? 'Create or join a household first to add items.'
                                      : 'No household is currently selected. Please select one from the main screen.',
                                    style: TextStyle(color: errorColor)
                                  )
                                ),
                              ],
                            ),
                          )
                        else if (householdState is HouseholdLoading) // Still show loading for initial household list fetch
                           const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        // Household selection DropdownButtonFormField is removed.

                        TextFormField(
                          controller: priceController,
                          style: TextStyle(color: textColor),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.attach_money_outlined, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Price is required';
                            if (double.tryParse(v.trim()) == null) return 'Invalid price';
                            if (double.parse(v.trim()) < 0) return 'Price cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        // Photo URL TextFormField is removed.

                         DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.category_outlined, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          value: selectedCategory, // Use pre-filled category
                          items: _categories.map((String category) { // Use the main _categories list
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            stfSetState(() {
                              selectedCategory = newValue;
                            });
                          },
                          validator: (v) => v == null ? 'Please select a category' : null,
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedExpirationDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                               builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme.copyWith(
                                          primary: primaryColor,
                                          onPrimary: Colors.white,
                                          surface: backgroundColor,
                                          onSurface: textColor,
                                        ),
                                    dialogBackgroundColor: backgroundColor,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              stfSetState(() {
                                selectedExpirationDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: subtitleColor ?? Colors.grey),
                              borderRadius: BorderRadius.circular(12.0),
                              color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedExpirationDate == null
                                      ? 'Select Expiration Date (Optional)'
                                      : 'Expires: ${DateFormat.yMd().format(selectedExpirationDate!)}',
                                  style: TextStyle(color: textColor),
                                ),
                                Icon(Icons.calendar_today_outlined, color: primaryColor.withOpacity(0.8)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(foregroundColor: subtitleColor),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: selectedHouseholdId != null &&
                               selectedCategory != null && // Ensure category is selected
                               !(householdState is HouseholdLoading)
                        ? () async {
                            if (formKey.currentState!.validate()) {
                              // final String itemName = item['item_name']; // Already available in 'item'
                              final int itemId = item['item_id'];
                              final double price = double.parse(priceController.text.trim());

                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('token');
                                if (token == null) throw Exception('Token not found');

                                final requestBody = {
                                    'householdId': selectedHouseholdId,
                                    'itemId': itemId,
                                    'location': 'in_house',
                                    'price': price,
                                    'expirationDate': selectedExpirationDate?.toIso8601String().split('T')[0],
                                    'category': selectedCategory,
                                  };

                                // Photo is part of the existing item, backend should handle it.
                                // If your backend specifically requires item_photo for add-existing,
                                // you can add it here from item['item_photo']
                                if (item['item_photo'] != null && item['item_photo'].toString().isNotEmpty) {
                                   requestBody['item_photo'] = item['item_photo'];
                                }


                                final response = await http.post(
                                  Uri.parse('${ApiConstants.baseUrl}/api/household-items/add-existing'),
                                  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                                  body: jsonEncode(requestBody),
                                );
                                _logApiResponse(response, context: 'Add Existing Item to Household (ItemSearch)');

                                if (!mounted) return;
                                if (response.statusCode == 201) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('${item['item_name']} added to your household!')),
                                  );
                                  final currentHState = context.read<CurrentHouseholdBloc>().state;
                                  if (currentHState is CurrentHouseholdSet) {
                                    context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: currentHState.household.id.toString()));
                                  }
                                } else {
                                  final errorData = jsonDecode(response.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to add item: ${errorData['message'] ?? response.reasonPhrase}')),
                                  );
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      disabledForegroundColor: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('ADD ITEM'),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  // This form is for creating a NEW item from search if it's not found
  void displayCreateAndAddItemForm(String itemNameFromSearch) {
    final TextEditingController itemNameController = TextEditingController(text: itemNameFromSearch);
    final TextEditingController priceController = TextEditingController();
    final TextEditingController photoUrlController = TextEditingController();
    final TextEditingController barcodeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    dynamic selectedHouseholdId; // Will be auto-selected
    String? selectedCategory;

    // Get current household ID
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      selectedHouseholdId = currentHouseholdState.household.id;
    }
    // Load all households for empty/loading states if needed
    final householdBloc = BlocProvider.of<HouseholdBloc>(context);
    householdBloc.add(LoadHouseholds());


    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        return StatefulBuilder(builder: (stfContext, stfSetState) {
          return BlocBuilder<HouseholdBloc, HouseholdState>(
            bloc: householdBloc,
            builder: (blocContext, householdState) {
              bool noHouseholdsExistAtAll = householdState is HouseholdLoaded && householdState.myHouseholds.isEmpty;

              return AlertDialog(
                backgroundColor: backgroundColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                title: Row(
                  children: [
                    Icon(Icons.add_box_outlined, color: primaryColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Create & Add New Item',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                        TextFormField(
                          controller: itemNameController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.label_outline, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Item name is required';
                            if (v.trim().length < 2) return 'Name must be at least 2 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                         DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.category_outlined, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          value: selectedCategory,
                          items: _categories.map((String category) { // Use the main _categories list
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            stfSetState(() {
                              selectedCategory = newValue;
                            });
                          },
                          validator: (v) => v == null ? 'Please select a category' : null,
                        ),
                        const SizedBox(height: 16),

                        if (selectedHouseholdId == null)
                           Container(
                            margin: const EdgeInsets.only(bottom:16.0),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: errorColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: errorColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: errorColor, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(
                                  noHouseholdsExistAtAll ? 'Create or join a household first to add items.' : 'No household is currently selected.',
                                  style: TextStyle(color: errorColor)
                                  )),
                              ],
                            ),
                          )
                        else if (householdState is HouseholdLoading)
                           const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        // Household selection dropdown removed

                        TextFormField(
                          controller: priceController,
                          style: TextStyle(color: textColor),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Price',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.attach_money_outlined, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Price is required';
                            if (double.tryParse(v.trim()) == null) return 'Invalid price';
                            if (double.parse(v.trim()) < 0) return 'Price cannot be negative';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: photoUrlController, // Photo URL is relevant for new items
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            labelText: 'Item Photo URL (Optional)',
                            hintText: 'e.g., https://example.com/image.jpg',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.link_outlined, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                           validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              final uri = Uri.tryParse(value.trim());
                              if (uri == null || !uri.isAbsolute || !(uri.scheme == 'http' || uri.scheme == 'https')) {
                                return 'Please enter a valid HTTP/HTTPS URL';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: barcodeController,
                          style: TextStyle(color: textColor),
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            labelText: 'Barcode (Optional)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.qr_code_scanner_outlined, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(height: 16),
                        InkWell(
                           onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedExpirationDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                               builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: Theme.of(context).colorScheme.copyWith(
                                          primary: primaryColor,
                                          onPrimary: Colors.white,
                                          surface: backgroundColor,
                                          onSurface: textColor,
                                        ),
                                    dialogBackgroundColor: backgroundColor,
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              stfSetState(() {
                                selectedExpirationDate = picked;
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: subtitleColor ?? Colors.grey),
                              borderRadius: BorderRadius.circular(12.0),
                              color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  selectedExpirationDate == null
                                      ? 'Select Expiration Date (Optional)'
                                      : 'Expires: ${DateFormat.yMd().format(selectedExpirationDate!)}',
                                  style: TextStyle(color: textColor),
                                ),
                                Icon(Icons.calendar_today_outlined, color: primaryColor.withOpacity(0.8)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(foregroundColor: subtitleColor),
                    child: const Text('CANCEL'),
                  ),
                  ElevatedButton(
                    onPressed: selectedHouseholdId != null &&
                               selectedCategory != null && // Ensure category is selected
                               !(householdState is HouseholdLoading)
                        ? () async {
                            if (formKey.currentState!.validate()) {
                              final String itemName = itemNameController.text.trim();
                              final String? photo = photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim();
                              final double price = double.parse(priceController.text.trim());
                              final String? barcode = barcodeController.text.trim().isEmpty ? null : barcodeController.text.trim();

                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('token');
                                if (token == null) throw Exception('Token not found');

                                final response = await http.post(
                                  Uri.parse('${ApiConstants.baseUrl}/api/items/create'), // Endpoint for creating a new item
                                  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                                  body: jsonEncode({
                                    'itemName': itemName,
                                    'itemPhoto': photo,
                                    'householdId': selectedHouseholdId, // Automatically selected household
                                    'location': 'in_house',
                                    'price': price,
                                    'expirationDate': selectedExpirationDate?.toIso8601String().split('T')[0],
                                    'barcode': barcode,
                                    'category': selectedCategory,
                                  }),
                                );
                                _logApiResponse(response, context: 'Create and Add Item (ItemSearch)');

                                if (!mounted) return;
                                if (response.statusCode == 201) {
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$itemName created and added to your household!')),
                                  );
                                  final currentHState = context.read<CurrentHouseholdBloc>().state;
                                  if (currentHState is CurrentHouseholdSet) {
                                    context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: currentHState.household.id.toString()));
                                  }
                                } else {
                                   final errorData = jsonDecode(response.body);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to create item: ${errorData['message'] ?? response.reasonPhrase}')),
                                  );
                                }
                              } catch (e) {
                                 if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        : null,
                     style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      disabledForegroundColor: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    child: const Text('CREATE & ADD'),
                  ),
                ],
              );
            },
          );
        });
      },
    );
  }

  Widget _buildDynamicSearchResultsWidget() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
    final cardColor = isDarkMode ? Colors.grey[800] : Colors.white;
    final primaryColor = Theme.of(context).colorScheme.primary;

    final Color itemForegroundColor = primaryColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final Color itemButtonBackgroundColor;
    if (primaryColor.computeLuminance() > 0.5) {
      itemButtonBackgroundColor = Color.alphaBlend(primaryColor.withOpacity(0.20), Colors.white);
    } else {
      itemButtonBackgroundColor = primaryColor.withOpacity(0.70);
    }

    if (_isSearching) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (_searchResults.isNotEmpty) {
      return Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final item = _searchResults[index];
            return Card(
              color: cardColor,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    item['item_photo'] ?? _defaultItemPhotoUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Icon(Icons.inventory_2_outlined, color: Colors.grey[700]),
                    ),
                  ),
                ),
                title: Text(item['item_name'] ?? 'Unknown Item', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                subtitle: item['category'] != null ? Text('Category: ${item['category']}', style: TextStyle(color: subtitleColor, fontSize: 12)) : null,
                trailing: ElevatedButton.icon(
                  icon: Icon(Icons.add_shopping_cart_outlined, size: 18, color: itemForegroundColor),
                  label: Text('Add', style: TextStyle(color: itemForegroundColor)),
                  onPressed: () {
                    _showAddToHouseholdForm(item); // This is the form we modified
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: itemButtonBackgroundColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: primaryColor.withOpacity(0.5)),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else if (_searchController.text.isNotEmpty && !_isSearching) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_outlined, size: 48, color: subtitleColor),
            const SizedBox(height: 12),
            Text(
              'No items found for "${_searchController.text}".',
              textAlign: TextAlign.center,
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'You can create it and add it to your household.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtitleColor, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add_circle_outline, color: itemForegroundColor),
              label: Text('Create "${_searchController.text}"', style: TextStyle(color: itemForegroundColor)),
              onPressed: () {
                displayCreateAndAddItemForm(_searchController.text); // This form is for new items
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final searchContainerBackgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final searchTextColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: searchContainerBackgroundColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(color: searchTextColor),
                  decoration: InputDecoration(
                    hintText: 'Search for items...',
                    hintStyle: TextStyle(color: searchTextColor.withOpacity(0.7)),
                    prefixIcon: Icon(Icons.search, color: searchTextColor),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide(color: primaryColor, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: searchTextColor),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                                _isSearching = false;
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                borderRadius: BorderRadius.circular(25.0),
                child: IconButton(
                  icon: Icon(Icons.qr_code_scanner_outlined, color: primaryColor),
                  tooltip: 'Scan Barcode',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barcode scanner coming soon!')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildDynamicSearchResultsWidget(),
        ),
      ],
    );
  }
}