// ignore_for_file: deprecated_member_use

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

class ToBuyScreen extends StatefulWidget {
  const ToBuyScreen({super.key});

  @override
  State<ToBuyScreen> createState() => _ToBuyScreenState();
}

class _ToBuyScreenState extends State<ToBuyScreen> {
  @override
  void initState() {
    super.initState();
    _loadToBuyItems();
  }

  void _loadToBuyItems() {
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      // Ensure householdId is a String before passing to the event
      final String householdIdStr = currentHouseholdState.household.id.toString();
      context.read<ToBuyBloc>().add(LoadToBuyItems(householdId: householdIdStr));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Shopping List',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
              ],
            ),
          ),

          // To Buy Items List
          Expanded(
            child: BlocConsumer<ToBuyBloc, ToBuyState>(
              listener: (context, state) {
                // Listen for state changes to handle errors if needed
                if (state is ToBuyError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: ${state.error}'), backgroundColor: Colors.red));
                }
              },
              builder: (context, state) {
                if (state is ToBuyLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ToBuyLoaded) {
                  final items = state.items;
                  return items.isEmpty ? _buildEmptyState() : _buildItemsList(items, isDarkMode);
                } else if (state is ToBuyError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${state.error}',
                          style: const TextStyle(color: Colors.red, fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _loadToBuyItems,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Your shopping list is empty', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Items moved from In-House will appear here', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<Item> items, bool isDarkMode) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!, width: 0.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 15.0),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            leading:
                item.photoUrl != null && item.photoUrl!.isNotEmpty
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        item.photoUrl!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.shopping_bag, size: 40),
                      ),
                    )
                    : const Icon(Icons.shopping_bag, size: 40),
            trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    IconButton(
      icon: const Icon(Icons.home_outlined, color: Colors.green),
      tooltip: 'Move to In-House',
      onPressed: () => _showMoveToHouseDialog(context, item),
    ),
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        if (value == 'update') {
          _showUpdateItemDialog(context, item);
        } else if (value == 'delete') {
          _showDeleteConfirmDialog(context, item);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'update',
          child: Row(
            children: [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text('Update'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red, size: 20),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    ),
  ],
),
          ),
        );
      },
    );
  }

  void _showMoveToHouseDialog(BuildContext context, Item item) {
    // Check if item ID is available
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot move item - missing item ID.')));
      return;
    }

    // Get current household
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is! CurrentHouseholdSet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a household first.')));
      return;
    }

    final householdId = currentHouseholdState.household.id;
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    // Store reference to the parent/screen context
    final parentContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.home, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Move ${item.name} to In-House',
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
                      Text(
                        'Purchased Item Details',
                        style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),

                      // Price field
                      TextFormField(
                        controller: priceController,
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.attach_money, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primaryColor, width: 2.0),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
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

                      // Expiration date
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 1825)), // 5 years
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
                            setState(() {
                              selectedExpirationDate = picked;
                            });
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
                                      : 'Expires on: ${DateFormat.yMd().format(selectedExpirationDate!)}',
                                  style: TextStyle(color: selectedExpirationDate == null ? subtitleColor : textColor),
                                ),
                              ),
                              if (selectedExpirationDate != null)
                                IconButton(
                                  icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                                  onPressed: () {
                                    setState(() {
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
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: subtitleColor),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final price = double.parse(priceController.text.trim());
                      final toBuyService = ToBuyService(baseUrl: ApiConstants.baseUrl);

                      // Show loading indicator
                      showDialog(
                        context: dialogContext,
                        barrierDismissible: false,
                        builder:
                            (context) => Center(
                              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(primaryColor)),
                            ),
                      );

                      final success = await toBuyService.moveItemToHouse(
                        householdItemId: int.parse(item.id!),
                        householdId: householdId,
                        price: price,
                        expirationDate: selectedExpirationDate,
                      );

                      // Close the loading indicator dialog
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      // Close the main dialog
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }

                      // Only show one snackbar and refresh if successful
                      if (parentContext.mounted) {
                        if (success) {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} moved to in-house.'),
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          // Use a simpler approach with the parent context
                          Future.delayed(const Duration(milliseconds: 300), () {
                            if (parentContext.mounted) {
                              // Force immediate refresh with the parent context
                              parentContext.read<ToBuyBloc>().add(LoadToBuyItems(householdId: householdId.toString()));
                              parentContext.read<InHouseBloc>().add(
                                LoadHouseholdItems(householdId: householdId.toString()),
                              );
                            }
                          });
                        } else {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to move item to in-house. Please try again.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: const Text('MOVE TO IN-HOUSE'),
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
  final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
  
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        title: Row(
          children: [
            Icon(Icons.delete, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text('Delete Item', style: TextStyle(color: textColor)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${item.name}" from your shopping list?',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteItem(context, item);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      );
    },
  );
}

Future<void> _deleteItem(BuildContext context, Item item) async {
  if (item.id == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot delete item - missing item ID.')),
    );
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/household-items/delete-household-item'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'householdItemId': int.parse(item.id!)}),
    );

    if (kDebugMode) {
      print('===== DELETE ITEM RESPONSE =====');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');
    }

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} has been deleted')),
      );
      
      _loadToBuyItems(); // Reload the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete item')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error deleting item: ${e.toString()}')),
    );
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
  final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
  final textColor = isDarkMode ? Colors.white : Colors.black87;
  final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

  final List<String> _dialogCategories = [
    'Fruits & Vegetables',
    'Dairy & Eggs',
    'Meat & Seafood',
    'Canned & Jarred',
    'Dry Goods & Pasta',
    'Others',
  ];
  
  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            title: Row(
              children: [
                Icon(Icons.edit, color: primaryColor, size: 24),
                const SizedBox(width: 8),
                Text('Update Shopping Item', style: TextStyle(color: textColor)),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.label_outline, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Item name is required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.category_outlined, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                      ),
                      dropdownColor: backgroundColor,
                      style: TextStyle(color: textColor),
                      items: _dialogCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Added Price field
                    TextFormField(
                      controller: priceController,
                      style: TextStyle(color: textColor),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.attach_money_outlined, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                      ),
                      validator: (v) {
                        if (v != null && v.trim().isNotEmpty) {
                          if (double.tryParse(v.trim()) == null) return 'Invalid price';
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.photo_outlined, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Added Expiration Date picker
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: selectedExpirationDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedExpirationDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, color: primaryColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                selectedExpirationDate != null
                                    ? 'Expires: ${DateFormat('MM/dd/yyyy').format(selectedExpirationDate!)}'
                                    : 'Set Expiration Date (Optional)',
                                style: TextStyle(color: textColor),
                              ),
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
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('UPDATE'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot update item - missing item ID.')),
    );
    return;
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    // Prepare request body
    Map<String, dynamic> requestBody = {
      'householdItemId': int.parse(item.id!),
      'itemName': name,
      'category': category,
    };

    if (photoUrl != null) {
      requestBody['itemPhoto'] = photoUrl;
    }
    
    if (price != null) {
      requestBody['price'] = price;
    }

    if (expirationDate != null) {
      requestBody['expirationDate'] = expirationDate.toIso8601String().split('T')[0];
    }

    final response = await http.post(
      Uri.parse('${ApiConstants.baseUrl}/api/household-items/edit-household-item'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(requestBody),
    );

    if (kDebugMode) {
      print('===== UPDATE ITEM RESPONSE =====');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');
    }

    if (!context.mounted) return;

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} has been updated')),
      );
      
      _loadToBuyItems(); // Reload the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update item')),
      );
    }
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error updating item: ${e.toString()}')),
    );
  }
}
}
