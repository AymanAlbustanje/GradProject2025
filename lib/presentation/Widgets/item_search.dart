// ignore_for_file: deprecated_member_use, use_build_context_synchronously, avoid_print

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/data/DataSources/notification_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ItemSearchWidget extends StatefulWidget {
  const ItemSearchWidget({super.key});

  @override
  ItemSearchWidgetState createState() => ItemSearchWidgetState();
}

class ItemSearchWidgetState extends State<ItemSearchWidget> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  Timer? _debounce;
  String? _currentHouseholdId;
  final NotificationService _notificationService = NotificationService();
  final String _defaultItemPhotoUrl = 'https://i.pinimg.com/736x/82/be/d4/82bed479344270067e3d2171379949b3.jpg';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      _currentHouseholdId = currentHouseholdState.household.id?.toString();
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_searchController.text.trim().isNotEmpty) {
        _searchItems(_searchController.text.trim());
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _searchItems(String query) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        throw Exception('Token not found');
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/items/search-name'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'name': query}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['items'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to search items: ${response.reasonPhrase}')));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching items: ${e.toString()}')));
    }
  }

  Future<Map<String, dynamic>?> fetchProductInfoFromBarcode(String barcode) async {
    try {
      final response = await http.get(Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'));

      if (kDebugMode) {
        print('[ItemSearchWidget] OPEN FOOD FACTS API RESPONSE for $barcode: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['product'] != null) {
          final product = data['product'];
          final String productName = product['product_name'] ?? product['brands'] ?? '';
          final String imageUrl = product['image_front_url'] ?? '';
          return {'name': productName, 'photoUrl': imageUrl, 'barcode': barcode};
        } else {
          if (kDebugMode) print('[ItemSearchWidget] Product not found on OpenFoodFacts for barcode: $barcode');
          return null;
        }
      } else {
        if (kDebugMode) {
          print('[ItemSearchWidget] Failed to fetch product info from OpenFoodFacts: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('[ItemSearchWidget] Error fetching product info from OpenFoodFacts: $e');
      return null;
    }
  }

  Future<void> _startBarcodeScanning() async {
    String? scannedBarcode;
    if (!mounted) return;
    final BuildContext currentContext = context;

    try {
      scannedBarcode = await Navigator.of(currentContext).push(
        MaterialPageRoute(
          builder:
              (scannerContext) => Scaffold(
                appBar: AppBar(
                  title: const Text('Scan Barcode'),
                  backgroundColor: Theme.of(scannerContext).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                body: MobileScanner(
                  controller: MobileScannerController(
                    detectionSpeed: DetectionSpeed.normal,
                    facing: CameraFacing.back,
                    torchEnabled: false,
                  ),
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    for (final barcodeData in barcodes) {
                      if (barcodeData.rawValue != null) {
                        if (Navigator.of(scannerContext).canPop()) {
                          Navigator.of(scannerContext).pop(barcodeData.rawValue);
                        }
                        break;
                      }
                    }
                  },
                ),
              ),
        ),
      );
    } catch (e) {
      if (kDebugMode) print('[ItemSearchWidget] Error during barcode scanning: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(currentContext).showSnackBar(SnackBar(content: Text('Error scanning: ${e.toString()}')));
      return;
    }

    if (scannedBarcode == null || !mounted) {
      if (kDebugMode && scannedBarcode == null) {
        print('[ItemSearchWidget] Barcode scanning cancelled or returned null.');
      }
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(currentContext).showSnackBar(
      SnackBar(
        content: Text('Barcode detected: $scannedBarcode. Fetching info...'),
        duration: const Duration(seconds: 1),
      ),
    );

    final Map<String, dynamic>? offProductInfo = await fetchProductInfoFromBarcode(scannedBarcode);

    if (!mounted) return;

    await _searchByBarcode(scannedBarcode, offProductInfo: offProductInfo);
  }

  Future<void> _searchByBarcode(String barcode, {Map<String, dynamic>? offProductInfo}) async {
    if (!mounted) return;
    final BuildContext currentContext = context;

    setState(() {
      _isLoading = true;
      _searchResults = [];
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token not found');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/items/search-barcode'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'barcode': barcode}),
      );

      _logApiResponse(response, contextMsg: 'Search by Barcode (ItemSearchWidget)');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'];

        if (items.isNotEmpty) {
          setState(() {
            _searchResults = items;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) showAddToHouseholdFormPublic(items[0]);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _showCreateItemForm(
                offProductInfo?['name'] ?? '',
                barcodeValue: barcode,
                initialPhotoUrl: offProductInfo?['photoUrl'],
              );
            }
          });
        }
      } else {
        if (kDebugMode) {
          print('[ItemSearchWidget] Backend search for barcode $barcode failed: ${response.statusCode}');
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showCreateItemForm(
              offProductInfo?['name'] ?? '',
              barcodeValue: barcode,
              initialPhotoUrl: offProductInfo?['photoUrl'],
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(
        currentContext,
      ).showSnackBar(SnackBar(content: Text('Error searching by barcode: ${e.toString()}')));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showCreateItemForm(
            offProductInfo?['name'] ?? '',
            barcodeValue: barcode,
            initialPhotoUrl: offProductInfo?['photoUrl'],
          );
        }
      });
    }
  }

  void _logApiResponse(http.Response response, {String? contextMsg}) {
    if (kDebugMode) {
      print('===== API RESPONSE ${contextMsg != null ? "($contextMsg)" : ""} =====');
      print('Status code: ${response.statusCode}');
      print('Body: ${response.body}');
      print('============================');
    }
  }

  void showAddToHouseholdFormPublic(dynamic itemFromApi) {
    if (!mounted) {
      if (kDebugMode) print("[ItemSearchWidget] showAddToHouseholdFormPublic: Widget not mounted, aborting dialog.");
      return;
    }
    final Map<String, dynamic> mappedItem = {
      'id': itemFromApi['item_id'],
      'name': itemFromApi['item_name'],
      'photo_url': itemFromApi['item_photo'],
      'category': itemFromApi['category'],
    };
    _showAddToHouseholdForm(mappedItem);
  }

  void _showAddToHouseholdForm(dynamic item) {
    if (!mounted) {
      if (kDebugMode) print("[ItemSearchWidget] _showAddToHouseholdForm: Widget not mounted, aborting dialog.");
      return;
    }

    final TextEditingController priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;

    if (!(_currentHouseholdId != null && _currentHouseholdId!.isNotEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a household first')));
      }
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.add_shopping_cart, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('Add to Household', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                (item['photo_url'] != null && item['photo_url'].toString().isNotEmpty)
                                    ? Image.network(
                                      item['photo_url'],
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) => Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                          ),
                                    )
                                    : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                    ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['name'] ?? 'Unknown Item',
                                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['category'] ?? 'Uncategorized',
                                  style: TextStyle(color: subtitleColor, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('Item Price', style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Enter price',
                          prefixIcon: Icon(Icons.attach_money, color: primaryColor),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Please enter a price';
                          if (double.tryParse(value) == null) return 'Please enter a valid number';
                          if (double.parse(value) < 0) return 'Price must be a positive number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Expiration Date (Optional)',
                        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: stfContext,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 1825)),
                          );
                          if (picked != null) {
                            stfSetState(() {
                              selectedExpirationDate = picked;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedExpirationDate == null
                                    ? 'Select Date'
                                    : DateFormat('yyyy-MM-dd').format(selectedExpirationDate!),
                                style: TextStyle(color: textColor),
                              ),
                              Icon(Icons.calendar_today, color: primaryColor),
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
                  child: Text('CANCEL', style: TextStyle(color: primaryColor)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.pop(dialogContext);
                      if (!mounted) return;

                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('token');
                        if (token == null) throw Exception('Token not found');

                        final response = await http.post(
                          Uri.parse('${ApiConstants.baseUrl}/api/household-items/add-existing'),
                          headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
                          body: jsonEncode({
                            'householdId': int.parse(_currentHouseholdId!),
                            'itemId': item['id'],
                            'location': 'in_house',
                            'price': double.tryParse(priceController.text) ?? 0.0,
                            'expirationDate': selectedExpirationDate?.toIso8601String().split('T')[0],
                          }),
                        );

                        _logApiResponse(response, contextMsg: 'Add item to household response');

                        if (!mounted) return;

                        if (response.statusCode == 400) {
                          final responseData = jsonDecode(response.body);
                          if (responseData['message']?.contains('already exists in the household') == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${item['name'] ?? "Item"} already exists in this household'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                        }

                        if (response.statusCode == 201) {
                          final responseData = jsonDecode(response.body);
                          final dynamic householdItemId = responseData['household_item_id'];
                          final String itemNameValue = item['name'] ?? 'Item';

                          if (selectedExpirationDate != null && householdItemId != null) {
                            final int? notificationId = int.tryParse(householdItemId.toString());
                            if (notificationId != null) {
                              await _notificationService.scheduleSimpleExpirationNotification(
                                id: notificationId,
                                itemName: itemNameValue,
                                expirationDate: selectedExpirationDate!,
                              );
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${item['name'] ?? "Item"} added to household successfully')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Failed to add ${item['name'] ?? "Item"} to household. Status: ${response.statusCode}',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        // Show error message instead of success
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to add ${item['name'] ?? "Item"} to household: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('ADD ITEM'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCreateItemForm(String itemName, {String? barcodeValue, String? initialPhotoUrl}) {
    if (!mounted) {
      if (kDebugMode) print("[ItemSearchWidget] _showCreateItemForm: Widget not mounted, aborting dialog.");
      return;
    }

    // Unfocus current text field before showing the dialog
    FocusScope.of(context).unfocus();

    final BuildContext currentContext = context;

    if (kDebugMode) {
      print("[ItemSearchWidget] --- _showCreateItemForm called ---");
      print("[ItemSearchWidget] Received itemName: '$itemName'");
      print("[ItemSearchWidget] Received barcodeValue (for submission): '$barcodeValue'");
      print("[ItemSearchWidget] Received initialPhotoUrl: '$initialPhotoUrl'");
      print("[ItemSearchWidget] ------------------------------------");
    }

    final TextEditingController nameController = TextEditingController(text: itemName);
    final TextEditingController priceController = TextEditingController();
    final TextEditingController photoUrlController = TextEditingController(text: initialPhotoUrl ?? '');
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    String? selectedCategoryDialog;

    final List<String> dialogCategories = [
      'Fruits & Vegetables',
      'Dairy & Eggs',
      'Meat & Seafood',
      'Canned & Jarred',
      'Dry Goods & Pasta',
      'Others',
    ];

    showDialog(
      context: currentContext,
      builder: (dialogContext) {
        final isDarkMode = Theme.of(dialogContext).brightness == Brightness.dark;
        final primaryColor = Theme.of(dialogContext).colorScheme.primary;
        final backgroundColor = isDarkMode ? const Color(0xFF1F1F1F) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtitleColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

        final double dialogContentWidth = MediaQuery.of(dialogContext).size.width * 0.9;

        return StatefulBuilder(
          builder: (stfContext, stfSetState) {
            return AlertDialog(
              backgroundColor: backgroundColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
              title: Row(
                children: [
                  Icon(Icons.add_box_outlined, color: primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Create New Item',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                // Wrap content in SizedBox with a defined width
                width: dialogContentWidth,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Crucial for Column in SingleChildScrollView
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image preview if initialPhotoUrl is available
                        if (initialPhotoUrl != null && initialPhotoUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  initialPhotoUrl,
                                  height: 150, // Fixed height
                                  // No width: double.infinity here
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (ctx, err, st) => Container(
                                        height: 120,
                                        width: 120, // Finite width for error placeholder
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8.0),
                                        ),
                                        child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                      ),
                                  loadingBuilder: (
                                    BuildContext context,
                                    Widget child,
                                    ImageChunkEvent? loadingProgress,
                                  ) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 120,
                                      width: 120, // Finite width for loading placeholder
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
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
                          controller: nameController,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Item Name',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.label_outline, color: primaryColor.withOpacity(0.8)),
                            labelStyle: TextStyle(color: subtitleColor),
                            filled: true,
                            fillColor:
                                isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
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
                            fillColor:
                                isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
                          ),
                          dropdownColor: backgroundColor,
                          style: TextStyle(color: textColor),
                          value: selectedCategoryDialog,
                          items:
                              dialogCategories.map((String category) {
                                return DropdownMenuItem<String>(value: category, child: Text(category));
                              }).toList(),
                          onChanged: (String? newValue) {
                            stfSetState(() {
                              selectedCategoryDialog = newValue;
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
                            filled: true,
                            fillColor:
                                isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
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
                            fillColor:
                                isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
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
                              context: stfContext,
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
                                    dialogTheme: DialogThemeData(backgroundColor: backgroundColor),
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
                              color:
                                  isDarkMode ? Colors.grey[800]!.withOpacity(0.3) : Colors.grey[100]!.withOpacity(0.5),
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
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(foregroundColor: subtitleColor),
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      // Unfocus before submitting
                      FocusScope.of(currentContext).unfocus();

                      try {
                        await _createNewItem(
                          name: nameController.text.trim(),
                          category: selectedCategoryDialog ?? '',
                          barcode: barcodeValue?.trim().isNotEmpty == true ? barcodeValue!.trim() : null,
                          price: double.tryParse(priceController.text) ?? 0.0,
                          expirationDate: selectedExpirationDate,
                          itemPhoto: photoUrlController.text.trim().isNotEmpty ? photoUrlController.text.trim() : null,
                        );
                      } catch (e) {
                        if (kDebugMode) print("[ItemSearchWidget] Error in create item flow: $e");
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create item: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                      if (mounted && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                    }
                  },
                  child: const Text('CREATE & ADD'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Ensure keyboard is dismissed after dialog closes
      FocusScope.of(currentContext).unfocus();
    });
  }

  Future<void> _createNewItem({
    required String name,
    required String category,
    String? barcode,
    required double price,
    DateTime? expirationDate,
    String? itemPhoto,
  }) async {
    if (!mounted) return;

    // Unfocus at the beginning of the method
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) throw Exception('Token not found');

      if (!(_currentHouseholdId != null && _currentHouseholdId!.isNotEmpty)) {
        throw Exception('No household selected or household ID is missing');
      }

      final String photoToSubmit = (itemPhoto != null && itemPhoto.isNotEmpty) ? itemPhoto : _defaultItemPhotoUrl;

      // Create a base request object
      final Map<String, dynamic> requestData = {
        'itemName': name,
        'category': category,
        'householdId': int.parse(_currentHouseholdId!),
        'location': 'in_house',
        'price': price,
        'itemPhoto': photoToSubmit,
      };

      // Only add expirationDate if it's not null
      if (expirationDate != null) {
        requestData['expirationDate'] = expirationDate.toIso8601String().split('T')[0];
      }

      // Only add barcode if it's not null and not empty
      if (barcode != null && barcode.isNotEmpty) {
        requestData['barcode'] = barcode;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/items/create'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestData),
      );

      _logApiResponse(response, contextMsg: 'Create new item response (ItemSearchWidget)');

      if (!mounted) return;

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final dynamic householdItemId = responseData['household_item_id'];

        if (expirationDate != null && householdItemId != null) {
          final int? notificationId = int.tryParse(householdItemId.toString());
          if (notificationId != null) {
            await _notificationService.scheduleSimpleExpirationNotification(
              id: notificationId,
              itemName: name,
              expirationDate: expirationDate,
            );
            if (kDebugMode) {
              print('[ItemSearchWidget] Scheduled notification for new item $name with ID $notificationId');
            }
          }
        }

        // Clear search field and results to refresh the page
        setState(() {
          _searchController.clear();
          _searchResults = [];
        });

        // Use a post-frame callback to ensure unfocus happens after state update
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            FocusScope.of(context).unfocus();
          }
        });

        // Refresh the in-house items list
        if (mounted) {
          // Get the current household ID from the bloc
          final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
          if (currentHouseholdState is CurrentHouseholdSet) {
            // Refresh the InHouseBloc to update the items list
            context.read<InHouseBloc>().add(
              LoadHouseholdItems(householdId: currentHouseholdState.household.id.toString()),
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$name created and added successfully')));
      } else {
        final responseBody = jsonDecode(response.body);
        final errorMessage = responseBody['message'] ?? 'Failed to create item. Status: ${response.statusCode}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
      }
    } catch (e) {
      if (kDebugMode) print("[ItemSearchWidget] Error in _createNewItem: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating item: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Final unfocus attempt in case previous ones didn't work
        FocusScope.of(context).unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final searchBackgroundColor = isDarkMode ? const Color(0xFF333333) : const Color(0xFFF1F3F5);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final cardColor = isDarkMode ? const Color(0xFF262626) : Colors.white;

    return BlocListener<CurrentHouseholdBloc, CurrentHouseholdState>(
      listener: (context, state) {
        if (state is CurrentHouseholdSet) {
          if (mounted) {
            setState(() {
              _currentHouseholdId = state.household.id?.toString();
            });
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16.0),
              height: 48,
              decoration: BoxDecoration(
                color: searchBackgroundColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryColor, width: 1.5),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                    child: Icon(Icons.search, color: primaryColor, size: 20),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Search for items...',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.6), fontSize: 15),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    height: double.infinity,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.horizontal(right: Radius.circular(24)),
                        onTap: _startBarcodeScanning,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Icon(Icons.barcode_reader, color: primaryColor, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 16.0),
                child: Column(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Searching...', style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14)),
                  ],
                ),
              )
            else if (_searchController.text.isNotEmpty && _searchResults.isEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off_rounded, size: 56, color: primaryColor.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      'No items found',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    // Text(
                    //   'We couldn\'t find any items matching "${_searchController.text}"',
                    //   style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 14),
                    //   textAlign: TextAlign.center,
                    // ),
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Want to add this item to your inventory?',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Create New Item'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: () {
                                _showCreateItemForm(_searchController.text, initialPhotoUrl: null);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (_searchResults.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.21),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    shrinkWrap: true,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final item = _searchResults[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 1,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          leading: Hero(
                            tag: 'item_search_${item['item_id'] ?? item['id'] ?? index}',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  item['item_photo'] != null && item['item_photo'].toString().isNotEmpty
                                      ? Image.network(
                                        item['item_photo'],
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) => Container(
                                              width: 56,
                                              height: 56,
                                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                                size: 24,
                                              ),
                                            ),
                                      )
                                      : Container(
                                        width: 56,
                                        height: 56,
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                          size: 24,
                                        ),
                                      ),
                            ),
                          ),
                          title: Text(
                            item['item_name'] ?? 'Unknown Item',
                            style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 16),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item['category'] ?? 'Uncategorized',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => showAddToHouseholdFormPublic(item),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Icon(Icons.add_circle_outline, color: primaryColor, size: 24),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
