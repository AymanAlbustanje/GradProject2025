// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, control_flow_in_finally, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../Logic/blocs/in_house_bloc.dart';
import '../../Logic/blocs/current_household_bloc.dart';
import '../widgets/in_house_items_widget.dart';

class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key});

  @override
  _InHouseScreenState createState() => _InHouseScreenState();
}

class _InHouseScreenState extends State<InHouseScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  final int _debounceTime = 500; // milliseconds
  final String _defaultItemPhotoUrl = 'https://i.pinimg.com/736x/82/be/d4/82bed479344270067e3d2171379949b3.jpg';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Initial load of items for the currently selected household
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
      if (currentHouseholdState is CurrentHouseholdSet) {
        if (currentHouseholdState.household.id != null) {
          context
              .read<InHouseBloc>()
              .add(LoadHouseholdItems(householdId: currentHouseholdState.household.id.toString()));
        }
      } else {
        // Optionally, if no household is set initially, clear items or show a placeholder
        // For example, if you have a ClearHouseholdItems event:
        // context.read<InHouseBloc>().add(ClearHouseholdItems());
      }
    });
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
        _searchItems(currentSearchText);
      } else if (currentSearchText.isEmpty || currentSearchText.length < 2) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchItems(String keyword) async {
    if (keyword.length < 2) {
      if (!mounted) return;
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/items/search'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'keyword': keyword}),
      );
      _logApiResponse(response, context: 'Search Items');

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
    final TextEditingController photoUrlController = TextEditingController(); // New controller for photo URL
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    dynamic selectedHouseholdId;

    final householdBloc = BlocProvider.of<HouseholdBloc>(context);
    householdBloc.add(LoadHouseholds());

    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      selectedHouseholdId = currentHouseholdState.household.id;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        return BlocBuilder<HouseholdBloc, HouseholdState>(
          builder: (blocContext, householdState) {
            List<Household> households = [];
            if (householdState is HouseholdLoaded) {
              households = householdState.myHouseholds;
            }

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
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: primaryColor.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            if (item['item_photo'] != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  item['item_photo'],
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (c, e, s) => Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.error),
                                      ),
                                ),
                              )
                            else
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.inventory),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item['item_name'],
                                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (householdState is HouseholdLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (households.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: errorColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: errorColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Create a household first', style: TextStyle(color: errorColor))),
                            ],
                          ),
                        )
                      else
                        StatefulBuilder(
                          builder: (context, setDropdownState) {
                            return DropdownButtonFormField<dynamic>(
                              decoration: InputDecoration(
                                labelText: 'Select Household',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                prefixIcon: Icon(Icons.home_outlined, color: primaryColor.withOpacity(0.8)),
                                labelStyle: TextStyle(color: subtitleColor),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor, width: 2.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? Colors.grey[800]!.withOpacity(0.3)
                                        : Colors.grey[100]!.withOpacity(0.5),
                              ),
                              dropdownColor: backgroundColor,
                              style: TextStyle(color: textColor),
                              value: selectedHouseholdId,
                              items:
                                  households
                                      .map((h) => DropdownMenuItem<dynamic>(value: h.id, child: Text(h.name)))
                                      .toList(),
                              onChanged: (value) => setDropdownState(() => selectedHouseholdId = value),
                              validator: (v) => v == null ? 'Please select a household' : null,
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: priceController,
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.money, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter a price';
                          final p = double.tryParse(v);
                          if (p == null) return 'Please enter a valid number';
                          if (p < 0) return 'Price must be a positive number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField( // New TextFormField for Photo URL
                        controller: photoUrlController,
                        style: TextStyle(color: textColor),
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'Photo URL (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.link, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (Uri.tryParse(v)?.hasAbsolutePath != true) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 1825)),
                            builder:
                                (c, child) => Theme(
                                  data: Theme.of(c).copyWith(
                                    colorScheme: Theme.of(c).colorScheme.copyWith(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      surface: backgroundColor,
                                      onSurface: textColor,
                                    ),
                                    dialogBackgroundColor: backgroundColor,
                                  ),
                                  child: child!,
                                ),
                          );
                          if (picked != null && mounted) {
                            selectedExpirationDate = picked;
                            (blocContext as Element).markNeedsBuild();
                          }
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12.0),
                            color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryColor.withOpacity(0.8), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedExpirationDate == null
                                      ? 'Expiration Date (Optional)'
                                      : 'Expires on: ${selectedExpirationDate!.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(color: selectedExpirationDate == null ? subtitleColor : textColor),
                                ),
                              ),
                              if (selectedExpirationDate != null)
                                IconButton(
                                  icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                                  onPressed: () {
                                    selectedExpirationDate = null;
                                    (blocContext as Element).markNeedsBuild();
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: subtitleColor),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed:
                      householdState is HouseholdLoaded && households.isNotEmpty
                          ? () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('token');
                                if (token == null) throw Exception('Auth token not found');

                                String finalItemPhotoUrl = photoUrlController.text.trim();
                                if (finalItemPhotoUrl.isEmpty) {
                                  finalItemPhotoUrl = item['item_photo'] ?? _defaultItemPhotoUrl;
                                }

                                final Map<String, dynamic> requestBody = {
                                  'householdId': selectedHouseholdId,
                                  'itemId': item['item_id'],
                                  'location': 'in_house',
                                  'price': double.parse(priceController.text.trim()),
                                  'itemPhoto': finalItemPhotoUrl, // Use the determined photo URL
                                };
                                if (selectedExpirationDate != null) {
                                  requestBody['expirationDate'] =
                                      selectedExpirationDate!.toIso8601String().split('T')[0];
                                }

                                final response = await http.post(
                                  Uri.parse('${ApiConstants.baseUrl}/api/household-items/add-existing'),
                                  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                                  body: jsonEncode(requestBody),
                                );
                                _logApiResponse(response, context: 'Add Item to Household');
                                if (!mounted) return;
                                if (response.statusCode == 201) {
                                  context.read<InHouseBloc>().add(
                                    LoadHouseholdItems(householdId: selectedHouseholdId.toString()),
                                  );
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Item added to household!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  final responseBody = jsonDecode(response.body);
                                  final message = responseBody['message'] ?? 'Failed to add item to household';
                                  throw Exception(message);
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
                                    backgroundColor: Colors.red,
                                  ),
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
      },
    );
  }

  void _showCreateAndAddItemForm(String itemNameFromSearch) {
    final TextEditingController itemNameController = TextEditingController(text: itemNameFromSearch);
    final TextEditingController priceController = TextEditingController();
    final TextEditingController photoUrlController = TextEditingController(); // New controller for photo URL
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    dynamic selectedHouseholdId;

    final householdBloc = BlocProvider.of<HouseholdBloc>(context);
    householdBloc.add(LoadHouseholds());

    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      selectedHouseholdId = currentHouseholdState.household.id;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final errorColor = Theme.of(dialogContext).colorScheme.error;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        return BlocBuilder<HouseholdBloc, HouseholdState>(
          builder: (blocContext, householdState) {
            List<Household> households = [];
            if (householdState is HouseholdLoaded) {
              households = householdState.myHouseholds;
            }

            return AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.add_circle_outline, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create & Add New Item',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
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
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Please enter item name' : null,
                      ),
                      const SizedBox(height: 20),
                      if (householdState is HouseholdLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (households.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: errorColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: errorColor.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: errorColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Create a household first to add items',
                                  style: TextStyle(color: errorColor),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        StatefulBuilder(
                          builder: (context, setDropdownState) {
                            return DropdownButtonFormField<dynamic>(
                              decoration: InputDecoration(
                                labelText: 'Select Household to Add To',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                                prefixIcon: Icon(Icons.home_outlined, color: primaryColor.withOpacity(0.8)),
                                labelStyle: TextStyle(color: subtitleColor),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: primaryColor, width: 2.0),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                filled: true,
                                fillColor:
                                    isDarkMode
                                        ? Colors.grey[800]!.withOpacity(0.3)
                                        : Colors.grey[100]!.withOpacity(0.5),
                              ),
                              dropdownColor: backgroundColor,
                              style: TextStyle(color: textColor),
                              value: selectedHouseholdId,
                              items:
                                  households
                                      .map((h) => DropdownMenuItem<dynamic>(value: h.id, child: Text(h.name)))
                                      .toList(),
                              onChanged: (value) => setDropdownState(() => selectedHouseholdId = value),
                              validator: (v) => v == null ? 'Please select a household' : null,
                            );
                          },
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: priceController,
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.money, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Please enter a price';
                          final p = double.tryParse(v);
                          if (p == null) return 'Please enter a valid number';
                          if (p < 0) return 'Price must be a positive number';
                          return null;
                        },
                      ),
                       const SizedBox(height: 16),
                      TextFormField( // New TextFormField for Photo URL
                        controller: photoUrlController,
                        style: TextStyle(color: textColor),
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: 'Photo URL (Optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.link, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                        ),
                        validator: (v) {
                          if (v != null && v.isNotEmpty) {
                            if (Uri.tryParse(v)?.hasAbsolutePath != true) {
                              return 'Please enter a valid URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 1825)),
                            builder:
                                (c, child) => Theme(
                                  data: Theme.of(c).copyWith(
                                    colorScheme: Theme.of(c).colorScheme.copyWith(
                                      primary: primaryColor,
                                      onPrimary: Colors.white,
                                      surface: backgroundColor,
                                      onSurface: textColor,
                                    ),
                                    dialogBackgroundColor: backgroundColor,
                                  ),
                                  child: child!,
                                ),
                          );
                          if (picked != null && mounted) {
                            selectedExpirationDate = picked;
                            (blocContext as Element).markNeedsBuild();
                          }
                        },
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[400]!),
                            borderRadius: BorderRadius.circular(12.0),
                            color: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: primaryColor.withOpacity(0.8), size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedExpirationDate == null
                                      ? 'Expiration Date (Optional)'
                                      : 'Expires on: ${selectedExpirationDate!.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(color: selectedExpirationDate == null ? subtitleColor : textColor),
                                ),
                              ),
                              if (selectedExpirationDate != null)
                                IconButton(
                                  icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                                  onPressed: () {
                                    selectedExpirationDate = null;
                                    (blocContext as Element).markNeedsBuild();
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: subtitleColor),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed:
                      householdState is HouseholdLoaded && households.isNotEmpty
                          ? () async {
                            if (formKey.currentState!.validate()) {
                              try {
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('token');
                                if (token == null) throw Exception('Auth token not found');

                                String finalItemPhotoUrl = photoUrlController.text.trim();
                                if (finalItemPhotoUrl.isEmpty) {
                                  finalItemPhotoUrl = _defaultItemPhotoUrl; // Use default for new items
                                }

                                final Map<String, dynamic> requestBody = {
                                  'itemName': itemNameController.text.trim(),
                                  'itemPhoto': finalItemPhotoUrl, 
                                  'householdId': selectedHouseholdId,
                                  'location': 'in_house', 
                                  'price': double.parse(priceController.text.trim()),
                                };
                                if (selectedExpirationDate != null) {
                                  requestBody['expirationDate'] =
                                      selectedExpirationDate!.toIso8601String().split('T')[0];
                                }

                                final response = await http.post(
                                  Uri.parse('${ApiConstants.baseUrl}/api/items/create'),
                                  headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                                  body: jsonEncode(requestBody),
                                );
                                _logApiResponse(response, context: 'Create Item and Add to Household');

                                if (!mounted) return;

                                if (response.statusCode == 201) {
                                  final currentBlocHouseholdState = context.read<CurrentHouseholdBloc>().state;
                                  if (currentBlocHouseholdState is CurrentHouseholdSet) {
                                    context.read<InHouseBloc>().add(
                                      LoadHouseholdItems(
                                        householdId: currentBlocHouseholdState.household.id.toString(),
                                      ),
                                    );
                                  } else if (selectedHouseholdId != null) {
                                    context.read<InHouseBloc>().add(
                                      LoadHouseholdItems(householdId: selectedHouseholdId.toString()),
                                    );
                                  }
                                  Navigator.pop(dialogContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Item created and added!'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } else {
                                  final responseBody = jsonDecode(response.body);
                                  String errorMessage = responseBody['message'] ?? 'Failed to create and add item.';
                                  if (responseBody['errors'] != null && responseBody['errors'] is List) {
                                    final errors = responseBody['errors'] as List;
                                    if (errors.isNotEmpty && errors.first['message'] != null) {
                                      errorMessage = errors.first['message'];
                                    }
                                  }
                                  throw Exception(errorMessage);
                                }
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceFirst("Exception: ", "")}'),
                                    backgroundColor: Colors.red,
                                  ),
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
      },
    );
  }

  Widget _buildDynamicSearchResultsWidget() {
    if (_isSearching) {
      return Padding(
        key: const ValueKey('searching_state'),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 10),
              Text('Searching...', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
        ),
      );
    } else if (_searchResults.isNotEmpty) {
      return Container(
        key: const ValueKey('results_found_state'),
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          itemCount: _searchResults.length,
          itemBuilder: (context, index) {
            final item = _searchResults[index];
            return ListTile(
              leading:
                  item['item_photo'] != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(6.0),
                        child: Image.network(
                          item['item_photo'],
                          width: 45,
                          height: 45,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 35),
                        ),
                      )
                      : const Icon(Icons.inventory, size: 35),
              title: Text(item['item_name'], style: const TextStyle(fontWeight: FontWeight.w500)),
              trailing: ElevatedButton.icon(
                onPressed: () => _showAddToHouseholdForm(item),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Padding(
        key: const ValueKey('no_results_state'),
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 40, color: Colors.grey[500]),
              const SizedBox(height: 8),
              Text(
                'No items found for "${_searchController.text}"',
                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Create This Item'),
                onPressed: () => _showCreateAndAddItemForm(_searchController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final searchContainerBackgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return BlocListener<CurrentHouseholdBloc, CurrentHouseholdState>(
      listener: (context, state) {
        if (state is CurrentHouseholdSet) {
          if (state.household.id != null) {
            context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: state.household.id.toString()));
          } else {
            // Optionally clear items if household ID becomes null
            // context.read<InHouseBloc>().add(ClearHouseholdItems());
          }
        } else if (state is CurrentHouseholdNotSet) {
          // Optionally clear items when no household is selected
          // context.read<InHouseBloc>().add(ClearHouseholdItems());
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('In-House Items')),
        body: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: searchContainerBackgroundColor,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2, offset: const Offset(0, 1)),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onSubmitted: (value) {
                                if (value.trim().length >= 2) {
                                  _searchItems(value.trim());
                                }
                              },
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, size: 22),
                                suffixIcon:
                                    _searchController.text.isNotEmpty
                                        ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            // Optionally, also clear search results immediately
                                            setState(() {
                                              _searchResults = [];
                                              _isSearching = false;
                                              _debounceTimer?.cancel();
                                            });
                                          },
                                        )
                                        : null,
                                hintText: 'Search for items...',
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.fastOutSlowIn,
                    child:
                        _searchController.text.isNotEmpty
                            ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Results for "${_searchController.text}"',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                            fontSize: 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.close, size: 16),
                                        label: const Text('Close'),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _searchResults = [];
                                            _isSearching = false;
                                            _debounceTimer?.cancel();
                                          });
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          foregroundColor: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (Widget child, Animation<double> animation) {
                                    return FadeTransition(
                                      opacity: animation,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.0, 0.03),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _buildDynamicSearchResultsWidget(),
                                ),
                              ],
                            )
                            : const SizedBox.shrink(key: ValueKey('no_search_active_results_area')),
                  ),
                ],
              ),
            ),
            Expanded(child: InHouseItemsWidget()), // This widget displays items from InHouseBloc
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: primaryColor,
          onPressed: () {
            // Pass an empty string or a default name if needed by the form
            _showCreateAndAddItemForm(""); 
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}