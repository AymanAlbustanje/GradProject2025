import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gradproject2025/data/Models/item_model.dart';
// Ensure this is present

class InHouseService {
  final String baseUrl;
  final String _defaultItemPhotoUrl = 'https://i.pinimg.com/736x/82/be/d4/82bed479344270067e3d2171379949b3.jpg';

  InHouseService({required this.baseUrl});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Fetch in-house items for a household
  Future<List<Item>> getHouseholdItems(String householdId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/household-items?householdId=$householdId&location=in_house'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('===== GET IN-HOUSE ITEMS RESPONSE (Household ID: $householdId) =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
        print('================================================================');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('items') && data['items'] is List) {
          final List<dynamic> itemsJson = data['items'];
          return itemsJson.map((itemJson) => Item.fromJson(itemJson)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch in-house items. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching in-house items: $e');
      }
      throw Exception('Failed to fetch in-house items: $e');
    }
  }

  // Add a new item (creates a global item and then a household item)
  // Corresponds to /api/items/create endpoint
  Future<bool> addItem({
    required String itemName, // Only keep the named parameter version
    String? itemPhoto,
    required int householdId,
    required double price,
    DateTime? expirationDate,
    String location = 'in_house',
  }) async {
    try {
      final token = await _getToken();
      if (kDebugMode) {
        print('Attempting to add item: $itemName, Photo: $itemPhoto, Price: $price, Expiry: $expirationDate, Location: $location, HouseholdID: $householdId');
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) print('Authentication token is missing for addItem.');
        return false;
      }

      String? formattedExpirationDate;
      if (expirationDate != null) {
        formattedExpirationDate = expirationDate.toIso8601String().split('T')[0]; // YYYY-MM-DD
      }

      // Use provided photo, or default if null/empty, or let backend handle default if itemPhoto is truly optional there
      final String photoToSubmit = (itemPhoto != null && itemPhoto.trim().isNotEmpty)
          ? itemPhoto.trim()
          : _defaultItemPhotoUrl; // Backend /api/items/create expects itemPhoto

      final response = await http.post(
        Uri.parse('$baseUrl/api/items/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itemName': itemName,
          'itemPhoto': photoToSubmit,
          'householdId': householdId, // Backend expects int
          'location': location,       // Backend expects 'in_house' for this flow
          'price': price,             // Backend expects float
          'expirationDate': formattedExpirationDate, // Backend expects date string or null
        }),
      );

      if (kDebugMode) {
        print('===== API RESPONSE (Add Item via Service /api/items/create) =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
        print('================================================================');
      }

      if (response.statusCode == 201) {
        return true;
      } else {
        if (kDebugMode) {
          try {
            final responseBody = jsonDecode(response.body);
            print('Failed to add item via service: ${responseBody['message']}');
          } catch (e) {
            print('Failed to add item via service, and response body is not valid JSON or has no message. Body: ${response.body}');
          }
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception when adding item via service: $e');
      }
      return false;
    }
  }

  // Placeholder for getItems if you have a global item list separate from household items
  // This was in your provided code, but its usage isn't clear from the current context.
  // If it's for the global search, that's handled directly in in_house_screen.dart.
  Future<List<Item>> getItems() async {
    // This method might not be needed if global search is done directly.
    // If it's meant to fetch all items from the global 'items' table,
    // ensure your backend has an endpoint like '/api/items/list' or similar.
    if (kDebugMode) {
      print("InHouseService.getItems() called - ensure backend endpoint exists and is correct if this is used.");
    }
    return []; // Placeholder
  }
}