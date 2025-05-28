// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, control_flow_in_finally
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/Logic/blocs/to_buy_bloc.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
import 'package:gradproject2025/data/DataSources/to_buy_service.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gradproject2025/data/DataSources/notification_service.dart';

class InHouseItemsWidget extends StatefulWidget {
  const InHouseItemsWidget({super.key});

  @override
  InHouseItemsWidgetState createState() => InHouseItemsWidgetState();
}

class InHouseItemsWidgetState extends State<InHouseItemsWidget> {
  String _selectedCategoryFilter = 'All';
  final NotificationService _notificationService = NotificationService();

  final List<String> _filterCategories = [
    'All',
    'Fruits & Vegetables',
    'Dairy & Eggs',
    'Meat & Seafood',
    'Canned & Jarred',
    'Dry Goods & Pasta',
    'Others',
  ];

  final List<String> _dialogCategories = [
    'Fruits & Vegetables',
    'Dairy & Eggs',
    'Meat & Seafood',
    'Canned & Jarred',
    'Dry Goods & Pasta',
    'Others',
  ];
  final String _defaultItemPhotoUrl = 'https://i.pinimg.com/736x/82/be/d4/82bed479344270067e3d2171379949b3.jpg';

  void _logApiResponse(http.Response response, {String? context}) {
    if (kDebugMode) {
      print('===== API RESPONSE ${context != null ? "($context)" : ""} =====');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('============================');
    }
  }

  // Future<String?> _scanBarcode(BuildContext context) async {
  //   return await Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => Scaffold(
  //         appBar: AppBar(
  //           title: const Text('Scan Barcode'),
  //           backgroundColor: Theme.of(context).colorScheme.primary,
  //           foregroundColor: Colors.white,
  //         ),
  //         body: MobileScanner(
  //           controller: MobileScannerController(
  //             detectionSpeed: DetectionSpeed.normal,
  //             facing: CameraFacing.back,
  //             torchEnabled: false,
  //           ),
  //           onDetect: (capture) {
  //             final List<Barcode> barcodes = capture.barcodes;
  //             for (final barcode in barcodes) {
  //               if (barcode.rawValue != null) {
  //                 Navigator.of(context).pop(barcode.rawValue);
  //                 break;
  //               }
  //             }
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void displayCreateAndAddItemForm(
    BuildContext parentDialogContext, // <<<< ADD THIS PARAMETER
    String itemNameFromSearch, {
    String? barcodeValue,
    String? initialPhotoUrl,
    Function(List<Map<String, dynamic>> foundItems)? onBarcodeFoundExistingItems,
  }) {
    if (kDebugMode) {
      print('--- displayCreateAndAddItemForm called ---');
      print('Received itemName: \'$itemNameFromSearch\'');
      print('Received initialPhotoUrl: \'$initialPhotoUrl\'');
      print('Received barcodeValue: \'$barcodeValue\'');
    }

    final TextEditingController itemNameController = TextEditingController(text: itemNameFromSearch);
    final TextEditingController priceController = TextEditingController();
    // final TextEditingController barcodeController = TextEditingController(text: barcodeValue ?? ''); // Not used in form fields directly, barcodeValue is used for submission
    final TextEditingController photoUrlController = TextEditingController(text: initialPhotoUrl ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    dynamic selectedHouseholdId;
    String? selectedCategoryDialog;

    // Use the context of InHouseItemsWidget to read from Bloc initially
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      selectedHouseholdId = currentHouseholdState.household.id;
    }

    showDialog(
      context: parentDialogContext, // <<<< USE THE PASSED CONTEXT HERE
      builder: (dialogItselfContext) { // This context is for the AlertDialog's builder
        final isDarkMode = Theme.of(dialogItselfContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogItselfContext).colorScheme.primary;
        final errorColor = Theme.of(dialogItselfContext).colorScheme.error;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            // Use blocContext from the widget's own context for BlocBuilder if needed for household list
            return BlocBuilder<HouseholdBloc, HouseholdState>(
              bloc: BlocProvider.of<HouseholdBloc>(context)..add(LoadHouseholds()),
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
                  content: SizedBox( // Constrain the width of the dialog content
                    width: MediaQuery.of(dialogItselfContext).size.width * 0.9,
                    child: SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image preview if URL is provided
                            if (initialPhotoUrl != null && initialPhotoUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Center(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      initialPhotoUrl,
                                      height: 150,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => 
                                          Container(
                                            height: 120,
                                            width: 120,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[200],
                                              borderRadius: BorderRadius.circular(8.0),
                                            ),
                                            child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                          ),
                                      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return SizedBox(
                                          height: 120,
                                          width: 120,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            
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
                              value: selectedCategoryDialog,
                              items: _dialogCategories.map((String category) {
                                return DropdownMenuItem<String>(value: category, child: Text(category));
                              }).toList(),
                              onChanged: (String? newValue) {
                                stfSetState(() {
                                  selectedCategoryDialog = newValue;
                                });
                              },
                              validator: (v) => v == null ? 'Please select a category' : null,
                            ),
                            if (selectedHouseholdId == null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(top: 16),
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
                                        style: TextStyle(color: errorColor),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              const SizedBox(height: 16),
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
                              controller: photoUrlController,
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
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: dialogItselfContext, // Use context from dialog builder
                                  initialDate: selectedExpirationDate ?? DateTime.now(),
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                                  builder: (pickerContext, child) {
                                    return Theme(
                                      data: Theme.of(pickerContext).copyWith(
                                        colorScheme: Theme.of(pickerContext).colorScheme.copyWith(
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
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogItselfContext), // Use dialogItselfContext to pop
                      style: TextButton.styleFrom(foregroundColor: subtitleColor),
                      child: const Text('CANCEL'),
                    ),
                    ElevatedButton(
                      onPressed: selectedHouseholdId != null && selectedCategoryDialog != null && householdState is! HouseholdLoading
                          ? () async {
                              if (formKey.currentState!.validate()) {
                                final String itemName = itemNameController.text.trim();
                                final String itemPhoto = photoUrlController.text.trim().isEmpty ? _defaultItemPhotoUrl : photoUrlController.text.trim();
                                final double price = double.parse(priceController.text.trim());
                                final String? currentBarcodeValue = barcodeValue; // Use the passed barcodeValue

                                bool success = false;
                                try {
                                  final prefs = await SharedPreferences.getInstance();
                                  final token = prefs.getString('token');
                                  if (token == null) throw Exception('Token not found');

                                  final Map<String, dynamic> requestData = {
                                    'itemName': itemName,
                                    'itemPhoto': itemPhoto,
                                    'householdId': selectedHouseholdId,
                                    'location': 'in_house',
                                    'price': price,
                                    'category': selectedCategoryDialog,
                                  };

                                  if (selectedExpirationDate != null) {
                                    requestData['expirationDate'] = selectedExpirationDate?.toIso8601String().split('T')[0];
                                  }
                                  if (currentBarcodeValue != null && currentBarcodeValue.isNotEmpty) {
                                    requestData['barcode'] = currentBarcodeValue;
                                  }

                                  final response = await http.post(
                                    Uri.parse('${ApiConstants.baseUrl}/api/items/create'),
                                    headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                                    body: jsonEncode(requestData),
                                  );
                                  _logApiResponse(response, context: 'Create and Add Item from InHouseItemsWidget');

                                  if (!mounted) return; // Check mounted for InHouseItemsWidgetState
                                  if (response.statusCode == 201) {
                                    final responseData = jsonDecode(response.body);
                                    final dynamic createdHouseholdItemId = responseData['household_item_id']; 
                                    final String? newItemName = responseData['item']?['item_name'] ?? itemName;

                                    if (selectedExpirationDate != null && createdHouseholdItemId != null) {
                                      final int? notificationId = int.tryParse(createdHouseholdItemId.toString());
                                      if (notificationId != null) {
                                        _notificationService.scheduleSimpleExpirationNotification(
                                          id: notificationId,
                                          itemName: newItemName!,
                                          expirationDate: selectedExpirationDate!,
                                        );
                                      }
                                    }
                                    success = true;
                                  } else {
                                    final errorData = jsonDecode(response.body);
                                    if (stfContext.mounted) { // Check mounted for StatefulBuilder's context
                                      ScaffoldMessenger.of(stfContext).showSnackBar(
                                        SnackBar(
                                          content: Text('Failed to create item: ${errorData['message'] ?? response.reasonPhrase}'),
                                        ),
                                      );
                                    }
                                  }
                                } catch (e) {
                                  if (stfContext.mounted) { // Check mounted for StatefulBuilder's context
                                    ScaffoldMessenger.of(stfContext).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
                                  }
                                }

                                if (success && dialogItselfContext.mounted) { // Check mounted for dialogItselfContext
                                  Navigator.pop(dialogItselfContext); // Pop the dialog
                                  // Show SnackBar using the original parentDialogContext or InHouseItemsWidget's context
                                  ScaffoldMessenger.of(parentDialogContext).showSnackBar(
                                    SnackBar(content: Text('$itemName created and added to your household!')),
                                  );
                                  final currentHState = BlocProvider.of<CurrentHouseholdBloc>(parentDialogContext).state;
                                  if (currentHState is CurrentHouseholdSet) {
                                    BlocProvider.of<InHouseBloc>(parentDialogContext).add(
                                          LoadHouseholdItems(householdId: currentHState.household.id.toString()),
                                        );
                                  }
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          alignment: Alignment.centerLeft,
          child: Text(
            'Your Home Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
        ),
        _buildCategoryFilter(isDarkMode),
        Expanded(
          child: BlocBuilder<InHouseBloc, ItemState>(
            builder: (context, state) {
              if (state is ItemLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is ItemLoaded) {
                final filteredItems = _selectedCategoryFilter == 'All'
                    ? state.items
                    : state.items.where((item) {
                        return item.category != null && item.category == _selectedCategoryFilter;
                      }).toList();

                return filteredItems.isEmpty
                    ? _buildEmptyState(isFiltered: _selectedCategoryFilter != 'All')
                    : _buildItemsList(filteredItems, isDarkMode, context);
              } else if (state is ItemError) {
                return Center(child: Text(state.error, style: const TextStyle(color: Colors.red, fontSize: 18)));
              }
              return _buildEmptyState();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterCategories.length,
        itemBuilder: (context, index) {
          final category = _filterCategories[index];
          final bool isSelected = category == _selectedCategoryFilter;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategoryFilter = category;
                  });
                }
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? (Theme.of(context).colorScheme.primary.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                    : (isDarkMode ? Colors.white70 : Colors.black87),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(
                  color: isSelected ? Theme.of(context).colorScheme.primary : (isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isFiltered ? 'No items in this category' : 'No items added yet!',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (!isFiltered)
            Text(
              'Add items using the + button or search above',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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
            side: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!, width: 0.5),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w500)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.expirationDate != null)
                  Text(
                    'Expires: ${DateFormat('MM/dd/yyyy').format(item.expirationDate!)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                if (item.category != null && item.category!.isNotEmpty)
                  Text('Category: ${item.category}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                item.photoUrl ?? _defaultItemPhotoUrl,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8.0)),
                  child: Icon(Icons.inventory_2_outlined, color: Colors.grey[700]),
                ),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_checkout_outlined, color: Colors.blueAccent),
                  tooltip: 'Move to Shopping List',
                  onPressed: () => _moveToBuy(context, item),
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
                      child: Row(children: [Icon(Icons.edit, size: 20), SizedBox(width: 8), Text('Edit')]),
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

  void _moveToBuy(BuildContext context, Item item) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot move item - missing item ID.')));
      return;
    }
    final int? itemIdInt = int.tryParse(item.id!);
    if (itemIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot move item - invalid item ID format.')));
      return;
    }
    await _notificationService.cancelNotification(itemIdInt); 

    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is! CurrentHouseholdSet) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a household first.')));
      return;
    }

    final householdId = currentHouseholdState.household.id;

    try {
      final toBuyService = ToBuyService(baseUrl: ApiConstants.baseUrl);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Moving item to shopping list...')));

      final success = await toBuyService.moveItemToBuy(householdItemId: item.id!, householdId: householdId);

      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} moved to shopping list.')));
        context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: householdId.toString()));
        context.read<ToBuyBloc>().add(LoadToBuyItems(householdId: householdId.toString()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to move item to shopping list.')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error moving item: ${e.toString()}')));
    }
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
            'Are you sure you want to delete "${item.name}" from your inventory?',
            style: TextStyle(color: textColor),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete item - missing item ID.')));
      return;
    }
    final int? itemIdInt = int.tryParse(item.id!);
    if (itemIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete item - invalid item ID format.')));
      return;
    }
    await _notificationService.cancelNotification(itemIdInt); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/household-items/delete-household-item'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'householdItemId': int.parse(item.id!)}),
      );

      _logApiResponse(response, context: 'Delete Item from InHouseItemsWidget');

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${item.name} has been deleted')));
        final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
        if (currentHouseholdState is CurrentHouseholdSet) {
          context.read<InHouseBloc>().add(
                LoadHouseholdItems(householdId: currentHouseholdState.household.id.toString()),
              );
        }
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
    final priceController = TextEditingController(text: item.price?.toString() ?? '');
    final photoUrlController = TextEditingController(text: item.photoUrl ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate = item.expirationDate;
    String? selectedCategory = item.category;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stfContext, stfSetState) { 
            return AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.edit, color: primaryColor, size: 24),
                  const SizedBox(width: 8),
                  Text('Update Item', style: TextStyle(color: textColor)),
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
                          return DropdownMenuItem<String>(value: category, child: Text(category));
                        }).toList(),
                        onChanged: (String? newValue) {
                          stfSetState(() { 
                            selectedCategory = newValue;
                          });
                        },
                        validator: (v) => v == null ? 'Please select a category' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        style: TextStyle(color: textColor),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.attach_money_outlined, color: primaryColor.withOpacity(0.8)),
                          labelStyle: TextStyle(color: subtitleColor),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Price is required';
                          if (double.tryParse(v.trim()) == null) return 'Invalid price';
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
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: dialogContext, 
                            initialDate: selectedExpirationDate ?? DateTime.now(),
                            firstDate: DateTime(2000), 
                            lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                             builder: (pickerContext, child) {
                                  return Theme(
                                    data: Theme.of(pickerContext).copyWith(
                                      colorScheme: Theme.of(pickerContext).colorScheme.copyWith(
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
                                selectedExpirationDate != null
                                    ? 'Expires: ${DateFormat.yMd().format(selectedExpirationDate!)}'
                                    : 'Set Expiration Date (Optional)',
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
                TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('CANCEL')),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate() && selectedCategory != null) { 
                      Navigator.pop(dialogContext);
                      _updateItem(
                        context, 
                        item,
                        name: nameController.text.trim(),
                        category: selectedCategory!,
                        price: double.parse(priceController.text.trim()),
                        photoUrl: photoUrlController.text.trim().isEmpty ? null : photoUrlController.text.trim(),
                        expirationDate: selectedExpirationDate,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
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
    required double price,
    String? photoUrl,
    DateTime? expirationDate,
  }) async {
    if (item.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot update item - missing item ID.')));
      return;
    }
    final int? itemIdInt = int.tryParse(item.id!);
    if (itemIdInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot update item - invalid item ID format.')));
      return;
    }
    await _notificationService.cancelNotification(itemIdInt); 

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      Map<String, dynamic> requestBody = {
        'householdItemId': int.parse(item.id!),
        'itemName': name,
        'category': category,
        'price': price,
      };

      if (photoUrl != null && photoUrl.isNotEmpty) { 
        requestBody['itemPhoto'] = photoUrl;
      } else if (photoUrl == null || photoUrl.isEmpty) { 
         requestBody['itemPhoto'] = _defaultItemPhotoUrl; 
      }


      if (expirationDate != null) {
        requestBody['expirationDate'] = expirationDate.toIso8601String().split('T')[0];
      } else {
        // Backend should handle null to clear the date
        requestBody['expirationDate'] = null; 
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/household-items/edit-household-item'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );

      _logApiResponse(response, context: 'Update Item from InHouseItemsWidget');

      if (!context.mounted) return;

      if (response.statusCode == 200) {
        if (expirationDate != null) {
          _notificationService.scheduleSimpleExpirationNotification(
            id: itemIdInt,
            itemName: name,
            expirationDate: expirationDate,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.name}" has been updated')));
        final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
        if (currentHouseholdState is CurrentHouseholdSet) {
          context.read<InHouseBloc>().add(
                LoadHouseholdItems(householdId: currentHouseholdState.household.id.toString()),
              );
        }
      } else {
        final errorData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update item: ${errorData['message'] ?? response.reasonPhrase}')));
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating item: ${e.toString()}')));
    }
  }
}