// ignore_for_file: use_build_context_synchronously, deprecated_member_use, library_private_types_in_public_api, control_flow_in_finally

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gradproject2025/Logic/blocs/current_household_bloc.dart';
import 'package:gradproject2025/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// For date formatting

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
      if (_searchController.text.trim().isNotEmpty) {
        _searchItems(_searchController.text.trim());
      } else {
        if (mounted) {
          setState(() {
            _searchResults = [];
          });
        }
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
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': query}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to search items: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching items: ${e.toString()}')),
      );
    }
  }

  Future<void> _searchByBarcode(String barcode) async {
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
        Uri.parse('${ApiConstants.baseUrl}/api/items/search-barcode'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'barcode': barcode}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _searchResults = data['items'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _searchResults = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to find items by barcode: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _searchResults = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching by barcode: ${e.toString()}')),
      );
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
  
  void showAddToHouseholdFormPublic(dynamic item) {
    final Map<String, dynamic> mappedItem = {
      'item_id': item['item_id'] ?? item['id'], 
      'item_name': item['item_name'] ?? item['name'],
      'category': item['category'],
      'item_photo': item['item_photo'] ?? item['photoUrl'],
    };
    _showAddToHouseholdForm(mappedItem);
  }

  void _showAddToHouseholdForm(dynamic item) {
    final TextEditingController priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedExpirationDate;
    // Always set to 'in_house' without offering a choice
    const String selectedLocation = 'in_house';

    final currentHouseholdState = context.read<CurrentHouseholdBloc>().state;
    if (currentHouseholdState is CurrentHouseholdSet) {
      _currentHouseholdId = currentHouseholdState.household.id?.toString();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No household selected. Please select a household first.')),
      );
      return;
    }
    if (_currentHouseholdId == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Household ID is missing. Cannot add item.')),
      );
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
                  Icon(Icons.add_shopping_cart_outlined, color: primaryColor, size: 24),
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
                      // Add your form fields here
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
                    // Add your submit action here
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

  // New method to handle the barcode scanning
  Future<void> _startBarcodeScanning() async {
    final result = await Navigator.of(context).push(
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
                  Navigator.of(context).pop(barcode.rawValue);
                  break;
                }
              }
            },
          ),
        ),
      ),
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Searching by barcode...')),
      );
      await _searchByBarcode(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final searchBackgroundColor = isDarkMode ? Colors.grey[800] : Colors.grey[200];
    final textColor = isDarkMode ? Colors.white70 : Colors.black87;

    return BlocListener<CurrentHouseholdBloc, CurrentHouseholdState>(
      listener: (context, state) {
        if (state is CurrentHouseholdSet) {
          if (mounted) {
            setState(() {
              _currentHouseholdId = state.household.id?.toString();
            });
          }
        } else if (state is CurrentHouseholdInitial) { 
           if (mounted) {
            setState(() {
              _currentHouseholdId = null;
            });
          }
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Row containing search bar and barcode button
            Row(
              children: [
                // Search bar - expanded to take available width
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Search for items to add...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: primaryColor.withOpacity(0.7)),
                            onPressed: () {
                              _searchController.clear();
                              if (mounted) {
                                setState(() {
                                  _searchResults = [];
                                });
                              }
                            },
                          )
                        : null,
                      filled: true,
                      fillColor: searchBackgroundColor,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: Colors.grey[700]!.withOpacity(isDarkMode ? 0.5 : 0.2), width: 0.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide(color: primaryColor, width: 1),
                      ),
                    ),
                  ),
                ),
                
                // Separate circular barcode button
                Container(
                  margin: const EdgeInsets.only(left: 8.0),
                  child: Material(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(30),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _startBarcodeScanning,
                      child: Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.qr_code_scanner,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Rest of the content (loading indicator, search results, etc.) remains the same
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            if (_searchResults.isNotEmpty && !_isLoading)
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.25, 
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: item['item_photo'] != null && (item['item_photo'] as String).isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6.0),
                                child: Image.network(
                                  item['item_photo'],
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Icon(Icons.fastfood_outlined, color: primaryColor, size: 30),
                                ),
                              )
                            : Icon(Icons.fastfood_outlined, color: primaryColor, size: 30),
                        title: Text(item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(item['category'] ?? 'No category', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        trailing: IconButton(
                          icon: Icon(Icons.add_circle_outline, color: primaryColor, size: 28),
                          tooltip: 'Add to household',
                          onPressed: () {
                            if (_currentHouseholdId != null) {
                              _showAddToHouseholdForm(item);
                            } else {
                               ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select a household first from the Household screen.')),
                              );
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            if (_searchController.text.isNotEmpty && _searchResults.isEmpty && !_isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'No items found matching "${_searchController.text}".',
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}