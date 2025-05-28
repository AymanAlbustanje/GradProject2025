// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:convert';
import 'dart:math';

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
    // Use InHouseScreen's context when calling displayCreateAndAddItemForm
    final BuildContext screenContext = context;
    _inHouseItemsKey.currentState?.displayCreateAndAddItemForm(
      screenContext, // <<<< PASS SCREEN CONTEXT
      "", 
      onBarcodeFoundExistingItems: (List<Map<String, dynamic>> items) {
        if (items.isNotEmpty) {
          // Ensure ItemSearchWidgetState's context is used if showAddToHouseholdFormPublic needs it
          // or modify showAddToHouseholdFormPublic to also accept a context if it shows a dialog.
          _itemSearchWidgetKey.currentState?.showAddToHouseholdFormPublic(items[0]);
        } else {
          if (mounted) { // mounted refers to _InHouseScreenState
            ScaffoldMessenger.of(screenContext).showSnackBar(
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
            child: const Icon(Icons.barcode_reader, color: Colors.white),
          ),
        ],
      ),
    ),
  );
}

  // Add this function to your InHouseScreen class
Future<Map<String, dynamic>?> fetchProductInfoFromBarcode(String barcode) async {
  try {
    final response = await http.get(
      Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json'),
    );

    if (kDebugMode) {
      print('OPEN FOOD FACTS API RESPONSE: ${response.statusCode}');
      print('RESPONSE BODY: ${response.body.substring(0, min(500, response.body.length))}...');
    }

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // Check if the product was found
      if (data['status'] == 1 && data['product'] != null) {
        final product = data['product'];
        
        // Extract relevant information - handle null values gracefully
        final String productName = product['product_name'] ?? product['brands'] ?? '';
        final String imageUrl = product['image_front_url'] ?? '';
        
        // You can extract additional information if needed
        final Map<String, dynamic> productInfo = {
          'name': productName,
          'photoUrl': imageUrl,
          'barcode': barcode,
        };
        
        return productInfo;
      } else {
        if (kDebugMode) {
          print('Product not found for barcode: $barcode');
        }
        return null;
      }
    } else {
      if (kDebugMode) {
        print('Failed to fetch product info: ${response.statusCode}');
      }
      return null;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching product info: $e');
    }
    return null;
  }
}

Future<void> _scanBarcodeAndAddItem() async {
  String? barcode;
  final BuildContext screenContext = context; // Capture context before async operations

  try {
    barcode = await Navigator.of(screenContext).push(
      MaterialPageRoute(
        builder: (scannerContext) => Scaffold(
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
              for (final scannedBarcodeData in barcodes) {
                if (scannedBarcodeData.rawValue != null) {
                  Navigator.of(scannerContext).pop(scannedBarcodeData.rawValue); 
                  break;
                }
              }
            },
          ),
        ),
      ),
    );
  } catch (e) {
    if (kDebugMode) print('Error during barcode scanning: $e');
    if (!mounted) return; 
    ScaffoldMessenger.of(screenContext).showSnackBar(
      SnackBar(content: Text('Error scanning barcode: ${e.toString()}')),
    );
    return;
  }

  if (barcode == null || !mounted) {
    if (kDebugMode && barcode == null) print('Barcode scanning cancelled or returned null.');
    return;
  }
  
  // Optional: Short delay to allow scanner route to fully dismiss. Test if needed.
  // await Future.delayed(const Duration(milliseconds: 50));
  // if (!mounted) return;

  ScaffoldMessenger.of(screenContext).showSnackBar(
    SnackBar(content: Text('Processing barcode: $barcode'), duration: const Duration(seconds: 1)),
  );
  
  final productInfo = await fetchProductInfoFromBarcode(barcode);
  
  if (kDebugMode) print('Product info fetched for $barcode: $productInfo');
  if (!mounted) return;

  if (_inHouseItemsKey.currentState == null) {
      if (kDebugMode) print('_inHouseItemsKey.currentState is null. Cannot display form.');
      ScaffoldMessenger.of(screenContext).showSnackBar(
        const SnackBar(content: Text('Error: Could not prepare item form.')),
      );
      return;
  }
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (productInfo != null) {
        _inHouseItemsKey.currentState?.displayCreateAndAddItemForm(
          screenContext,
          productInfo['name'] ?? '', 
          barcodeValue: barcode,
          initialPhotoUrl: productInfo['photoUrl'],
        );
      } else {
        _inHouseItemsKey.currentState?.displayCreateAndAddItemForm(
          screenContext, 
          '', 
          barcodeValue: barcode,
        );
      }
    });
}
}
