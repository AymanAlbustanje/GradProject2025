// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/Logic/blocs/to_buy_bloc.dart';
import 'package:gradproject2025/data/Models/household_model.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import 'package:gradproject2025/data/DataSources/in_house_service.dart';
import 'package:gradproject2025/data/DataSources/to_buy_service.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:intl/intl.dart';

class InHouseItemsWidget extends StatelessWidget {
  const InHouseItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      children: [
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
        Expanded(
          child: BlocBuilder<InHouseBloc, ItemState>(
            builder: (context, state) {
              if (state is ItemLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ItemLoaded) {
                final items = state.items;
                return items.isEmpty
                    ? _buildEmptyState()
                    : _buildItemsList(items, isDarkMode, context);
              } else if (state is ItemError) {
                return Center(
                  child: Text(
                    state.error, 
                    style: const TextStyle(color: Colors.red, fontSize: 18),
                  ),
                );
              }
              return const SizedBox.shrink(); // Should not happen if initialized
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

  Widget _buildItemsList(List<Item> items, bool isDarkMode, BuildContext context) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          elevation: 0.5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(
              color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
              width: 0.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: item.expirationDate != null
    ? Text(
        'Expires: ${DateFormat('MM/dd/yyyy').format(item.expirationDate!)}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      )
    : null,
            leading: item.photoUrl != null && item.photoUrl!.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      item.photoUrl!, 
                      width: 50, 
                      height: 50, 
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 40), 
                    ),
                  )
                : const Icon(Icons.inventory, size: 40), 
            trailing: IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: Colors.blue),
              tooltip: 'Move to To Buy',
              onPressed: () => _moveToBuy(context, item),
            ),
          ),
        );
      },
    );
  }

  // Removed _formatDate as DateFormat.yMd().format(date) or similar can be used directly
  // String _formatDate(DateTime date) {
  //   return '${date.month}/${date.day}/${date.year}';
  // }


  void _moveToBuy(BuildContext context, Item item) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot move item - missing item ID (household_item_id).')),
      );
      return;
    }
  
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is! CurrentHouseholdSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a household first.')),
      );
      return;
    }
  
    // householdId from CurrentHouseholdSet is dynamic, ToBuyService handles it
    final householdId = currentHouseholdState.household.id; 
  
    try {
      final toBuyService = ToBuyService(baseUrl: ApiConstants.baseUrl);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Moving item to shopping list...')),
      );
      
      final success = await toBuyService.moveItemToBuy(
        householdItemId: item.id!, 
        householdId: householdId,   
      );

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${item.name} moved to shopping list.')),
        );
        
        context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: householdId.toString()));
        context.read<ToBuyBloc>().add(LoadToBuyItems(householdId: householdId.toString()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to move item to shopping list.')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error moving item: ${e.toString()}')),
      );
    }
  }
}

void showAddItemDialog(BuildContext parentContext, InHouseService itemsService) {
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemPhotoController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  
  // Use ValueNotifier for reactive UI updates within the dialog for selectedExpirationDate
  final ValueNotifier<DateTime?> selectedExpirationDateNotifier = ValueNotifier(null);
  
  final householdBloc = BlocProvider.of<HouseholdBloc>(parentContext);
  if (householdBloc.state is! HouseholdLoaded && householdBloc.state is! HouseholdLoading) {
    householdBloc.add(LoadHouseholds());
  }
  
  showDialog(
    context: parentContext,
    builder: (dialogContext) {
      final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
      final primaryColor = Theme.of(dialogContext).colorScheme.primary;
      // final errorColor = Theme.of(dialogContext).colorScheme.error; // Not used directly here
      final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];
      
      // Use StatefulBuilder to manage the state of selectedHouseholdId within the dialog
      int? selectedHouseholdIdDialogState; 

      return BlocBuilder<HouseholdBloc, HouseholdState>(
        builder: (context, householdState) {
          List<Household> households = [];
          if (householdState is HouseholdLoaded) {
            households = householdState.myHouseholds;
            if (selectedHouseholdIdDialogState == null && households.isNotEmpty) {
              final currentHState = parentContext.read<CurrentHouseholdBloc>().state;
              if (currentHState is CurrentHouseholdSet) {
                final currentId = int.tryParse(currentHState.household.id.toString());
                if (households.any((h) => int.tryParse(h.id.toString()) == currentId)) {
                  selectedHouseholdIdDialogState = currentId;
                } else {
                  selectedHouseholdIdDialogState = int.tryParse(households.first.id.toString());
                }
              } else if (households.isNotEmpty) {
                selectedHouseholdIdDialogState = int.tryParse(households.first.id.toString());
              }
            }
          }
          
          return AlertDialog(
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
            title: Row(
              children: [
                Icon(Icons.add_shopping_cart, color: primaryColor, size: 24),
                const SizedBox(width: 12),
                Text('Add a New Item', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[ // Explicitly type the list
                    Text('Item Details', style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    
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
                        if (value == null || value.trim().isEmpty) return 'Please enter an item name';
                        if (value.trim().length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: itemPhotoController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        labelText: 'Photo URL (Optional)',
                        hintText: 'e.g., https://example.com/image.png',
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
                        if (value != null && value.trim().isNotEmpty) {
                          final uri = Uri.tryParse(value.trim());
                          if (uri == null || !uri.isAbsolute || !(uri.scheme == 'http' || uri.scheme == 'https')) {
                            return 'Please enter a valid HTTP/HTTPS URL';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    if (householdState is HouseholdLoading)
                      const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: CircularProgressIndicator()))
                    else if (households.isEmpty)
                      Padding( // Corrected: Added content for empty households
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'No households available. Please create a household first.',
                          style: TextStyle(color: subtitleColor),
                          textAlign: TextAlign.center,
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
                        value: selectedHouseholdIdDialogState,
                        items: households.map((household) {
                          return DropdownMenuItem<int>(
                            value: int.tryParse(household.id.toString()),
                            child: Text(household.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                           // This needs to be handled by StatefulBuilder if you want the dropdown to update visually
                           // For now, we're just setting the variable that will be used on submit.
                           // To make it visually update, wrap the DropdownButtonFormField in a StatefulBuilder
                           // and call setState of that builder.
                           selectedHouseholdIdDialogState = value;
                        },
                        validator: (value) {
                          if (value == null) return 'Please select a household';
                          return null;
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
                        prefixIcon: Icon(Icons.attach_money, color: primaryColor.withOpacity(0.8)),
                        labelStyle: TextStyle(color: subtitleColor),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: primaryColor, width: 2.0),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        filled: true,
                        fillColor: isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter a price';
                        final price = double.tryParse(value.trim());
                        if (price == null) return 'Please enter a valid number for price';
                        if (price < 0) return 'Price cannot be negative';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    ValueListenableBuilder<DateTime?>(
                      valueListenable: selectedExpirationDateNotifier,
                      builder: (context, selectedDate, child) {
                        return InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: dialogContext,
                              initialDate: selectedDate ?? DateTime.now(),
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
                              selectedExpirationDateNotifier.value = picked;
                            }
                          },
                          borderRadius: BorderRadius.circular(12.0),
                          child: Container( // Corrected: Added UI for date picker
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
                                  selectedDate == null
                                      ? 'Select Expiration Date (Optional)'
                                      : 'Expires: ${DateFormat.yMd().format(selectedDate)}',
                                  style: TextStyle(color: textColor),
                                ),
                                Icon(Icons.calendar_today_outlined, color: primaryColor.withOpacity(0.8)),
                              ],
                            ),
                          ),
                        );
                      }
                    ),
                  ], // Explicitly close the Column's children list
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
                onPressed: (householdState is HouseholdLoaded && households.isNotEmpty && selectedHouseholdIdDialogState != null)
                    ? () async {
                        if (formKey.currentState!.validate()) {
                          final itemName = itemNameController.text.trim();
                          final itemPhoto = itemPhotoController.text.trim().isEmpty
                              ? null 
                              : itemPhotoController.text.trim();
                          final price = double.parse(priceController.text.trim());

                          // Corrected: Call addItem with named arguments
                          final success = await itemsService.addItem(
  itemName: itemName,
  itemPhoto: itemPhoto,
  householdId: selectedHouseholdIdDialogState!,
  price: price,
  expirationDate: selectedExpirationDateNotifier.value,
  // location defaults to 'in_house' in the service
);

                          if (!parentContext.mounted) return;

                          if (success) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(content: Text('Item added successfully!')),
                            );
                            parentContext.read<InHouseBloc>().add(LoadHouseholdItems(householdId: selectedHouseholdIdDialogState.toString()));
                          } else {
                            ScaffoldMessenger.of(parentContext).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to add item. Please check details and try again.'),
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
  ).whenComplete(() {
    selectedExpirationDateNotifier.dispose(); // Dispose the notifier
  });
}