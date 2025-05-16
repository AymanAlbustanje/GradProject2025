// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import 'package:gradproject2025/data/DataSources/in_house_service.dart';

class InHouseItemsWidget extends StatelessWidget {
  const InHouseItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
        // Section Divider
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          alignment: Alignment.centerLeft,
          child: Text(
            'Your In-House Items',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),

        // Section 2: In-House Items List
        Expanded(
          child: BlocBuilder<InHouseBloc, ItemState>(
            builder: (context, state) {
              if (state is ItemLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ItemLoaded) {
                final items = state.items;
                return items.isEmpty
                    ? _buildEmptyState()
                    : _buildItemsList(items, isDarkMode);
              } else if (state is ItemError) {
                return Center(
                  child: Text(
                    state.error, 
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, 
            size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No items added yet!', 
            style: TextStyle(
              fontSize: 18, 
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items using the + button',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(List<Item> items, bool isDarkMode) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 4.0),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: isDarkMode 
                  ? Colors.grey[800]! 
                  : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 8.0),
            title: Text(
              items[index].name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            leading: items[index].photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      items[index].photoUrl!, 
                      width: 50, 
                      height: 50, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 40),
                    ),
                  )
                : const Icon(Icons.inventory, size: 40),
          ),
        );
      },
    );
  }
}

// Add Item Dialog functionality
void showAddItemDialog(BuildContext parentContext, InHouseService itemsService) {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPhotoController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime? selectedExpirationDate;
  
  // Fetch the user's households to populate the dropdown
  final householdBloc = BlocProvider.of<HouseholdBloc>(parentContext);
  householdBloc.add(LoadHouseholds());
  
  showDialog(
    context: parentContext,
    builder: (context) {
      // Get the current theme mode for adaptive coloring
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final primaryColor = Theme.of(context).colorScheme.primary;
      final errorColor = Theme.of(context).colorScheme.error;
      final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
      
      return BlocBuilder<HouseholdBloc, HouseholdState>(
        builder: (context, householdState) {
          // Default household ID (will be overridden if households are loaded)
          int? selectedHouseholdId;
          
          // Get list of households if available
          List<Household> households = [];
          if (householdState is HouseholdLoaded) {
            households = householdState.myHouseholds;
            // Set default selected household if any exist
            if (households.isNotEmpty) {
              selectedHouseholdId = int.tryParse(households.first.id);
            }
          }
          
          return AlertDialog(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            title: Row(
              children: [
                Icon(Icons.add_shopping_cart, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Add a New Item',
                  style: TextStyle(
                    color: textColor, 
                    fontWeight: FontWeight.bold,
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
                    // Section label
                    Text(
                      'Item Details',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Item Name Field
                    TextFormField(
                      controller: itemNameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.shopping_bag_outlined, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an item name';
                        }
                        if (value.length < 3) {
                          return 'Name must be at least 3 characters';
                        }
                        // Check if name contains only letters, numbers and spaces
                        RegExp validPattern = RegExp(r'^[a-zA-Z0-9\s]{3,}$');
                        if (!validPattern.hasMatch(value)) {
                          return 'Name can only contain letters, numbers and spaces';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Photo URL Field
                    TextFormField(
                      controller: itemPhotoController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Photo URL (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.image_outlined, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.isAbsolute) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    // Household Selection Dropdown
                    if (householdState is HouseholdLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: CircularProgressIndicator(color: primaryColor),
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
                                'Create a household first',
                                style: TextStyle(color: errorColor),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      DropdownButtonFormField<int>(
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
                          fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                        ),
                        dropdownColor: backgroundColor,
                        style: TextStyle(color: textColor),
                        value: selectedHouseholdId,
                        items: households.map((household) {
                          return DropdownMenuItem<int>(
                            value: int.tryParse(household.id),
                            child: Text(household.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          selectedHouseholdId = value;
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a household';
                          }
                          return null;
                        },
                      ),
                    const SizedBox(height: 20),
                    
                    // Price Field
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
                        fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a price';
                        }
                        final price = double.tryParse(value);
                        if (price == null) {
                          return 'Please enter a valid number';
                        }
                        if (price < 0) {
                          return 'Price must be a positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Expiration Date Picker
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 1825)), // 5 years ahead
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
                          selectedExpirationDate = picked;
                          // Force rebuild to show the selected date
                          (context as Element).markNeedsBuild();
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
                                style: TextStyle(
                                  color: selectedExpirationDate == null ? subtitleColor : textColor,
                                ),
                              ),
                            ),
                            if (selectedExpirationDate != null)
                              IconButton(
                                icon: Icon(Icons.clear, color: subtitleColor, size: 18),
                                onPressed: () {
                                  selectedExpirationDate = null;
                                  (context as Element).markNeedsBuild();
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
                onPressed: () {
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: subtitleColor,
                ),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: householdState is HouseholdLoaded && households.isNotEmpty
                    ? () async {
                        if (formKey.currentState!.validate()) {
                          final itemName = itemNameController.text.trim();
                          final itemPhoto = itemPhotoController.text.trim().isEmpty
                              ? null
                              : itemPhotoController.text.trim();
                          final price = double.parse(priceController.text.trim());

                          // First, save to the database
                          final success = await itemsService.addItem(
                            itemName,
                            itemPhoto,
                            selectedHouseholdId!,
                            price,
                            selectedExpirationDate,
                          );

                          if (success) {
                            // If saving to DB was successful, update the local state
                            final newItem = Item(name: itemName, photoUrl: itemPhoto);
                            parentContext.read<InHouseBloc>().add(AddItem(item: newItem));

                            // Close the dialog and show a success message
                            Navigator.pop(context);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(content: Text('Item added successfully!')),
                            );
                          } else {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to save item to database.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    : null, // Disable button if no households available
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