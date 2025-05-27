// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/Logic/blocs/in_house_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Fix import path - use just ONE, consistent with your project structure
import '../Widgets/item_search.dart';
import '../Widgets/in_house_items_widget.dart';

class InHouseScreen extends StatefulWidget {
  const InHouseScreen({super.key});

  @override
  _InHouseScreenState createState() => _InHouseScreenState();
}

class _InHouseScreenState extends State<InHouseScreen> {
  final GlobalKey<InHouseItemsWidgetState> _inHouseItemsKey = GlobalKey<InHouseItemsWidgetState>();
  final GlobalKey<ItemSearchWidgetState> _itemSearchWidgetKey = GlobalKey<ItemSearchWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
      if (currentHouseholdState is CurrentHouseholdSet) {
        if (currentHouseholdState.household.id != null) {
          context.read<InHouseBloc>().add(
                LoadHouseholdItems(householdId: currentHouseholdState.household.id.toString()),
              );
        }
      }
    });
  }

  void _triggerAddItemForm() {
    _inHouseItemsKey.currentState?.displayCreateAndAddItemForm(
      "", 
      onBarcodeFoundExistingItems: (List<Map<String, dynamic>> items) {
        if (items.isNotEmpty) {
          _itemSearchWidgetKey.currentState?.showAddToHouseholdFormPublic(items[0]);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No existing items found for the scanned barcode.')),
            );
          }
        }
      },
    );
  }

  @override
Widget build(BuildContext context) {
  final primaryColor = Theme.of(context).colorScheme.primary;

  return BlocListener<CurrentHouseholdBloc, CurrentHouseholdState>(
    listener: (context, state) {
      if (state is CurrentHouseholdSet) {
        if (state.household.id != null) {
          context.read<InHouseBloc>().add(LoadHouseholdItems(householdId: state.household.id.toString()));
        }
      }
    },
    child: Scaffold(
      body: Column(
        children: [
          ItemSearchWidget(key: _itemSearchWidgetKey), 
          Expanded(
            child: InHouseItemsWidget(key: _inHouseItemsKey),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: _triggerAddItemForm,
            tooltip: 'Add New Item',
            heroTag: 'addItemButton',
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 16), // Spacing between buttons
          FloatingActionButton(
            backgroundColor: primaryColor,
            onPressed: _scanBarcodeAndAddItem,
            tooltip: 'Scan Barcode & Add Item',
            heroTag: 'scanBarcodeButton',
            child: const Icon(Icons.qr_code_scanner, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

// Add this new method to scan barcode first
Future<void> _scanBarcodeAndAddItem() async {
  String? barcode;
  
  try {
    // Store a reference to the navigator before pushing the route
    final navigator = Navigator.of(context);
    
    barcode = await navigator.push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Scan Barcode'),
            backgroundColor: Theme.of(context).colorScheme.primary,
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
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // Get the navigator from the current context, not from a closure
                  Navigator.of(context).pop(barcode.rawValue);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error during barcode scanning: $e');
    }
    return;
  }

  // Add a mounted check before processing the result
  if (barcode != null && mounted) {
    // Allow camera resources to be released
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Continue with the rest of your code to process the barcode
    // (search by barcode, show dialogs, etc.)
    if (mounted) {  // Add another mounted check after the delay
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barcode detected: $barcode')),
      );
      
      // Rest of your barcode processing code...
    }
  }
    
    // Search for the item with this barcode
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Authentication token not found')),
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/items/search-barcode'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'barcode': barcode}),
      );

      if (kDebugMode) {
        print('BARCODE SEARCH RESPONSE: ${response.statusCode}');
        print('BARCODE SEARCH BODY: ${response.body}');
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final items = data['items'];
        
        if (items.isNotEmpty) {
          // Item exists - show the add to household form
          _itemSearchWidgetKey.currentState?.showAddToHouseholdFormPublic(items[0]);
        } else {
          // No item found - show create new item form with barcode pre-filled
          _inHouseItemsKey.currentState?.displayCreateAndAddItemForm('', 
            barcodeValue: barcode,
            onBarcodeFoundExistingItems: (items) {
              if (items.isNotEmpty) {
                _itemSearchWidgetKey.currentState?.showAddToHouseholdFormPublic(items[0]);
              }
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to find items by barcode: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching by barcode: ${e.toString()}')),
      );
    }
  }
}
