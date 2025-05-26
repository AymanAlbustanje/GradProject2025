import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gradproject2025/data/Models/item_model.dart';

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
  Future<bool> addItem({
    required String itemName,
    String? itemPhoto,
    required int householdId,
    required double price,
    DateTime? expirationDate,
    required String category,
    String? barcode,
    String location = 'in_house',
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) print('Authentication token is missing for addItem.');
        return false;
      }

      // Format expiration date if provided
      String? formattedExpirationDate;
      if (expirationDate != null) {
        formattedExpirationDate = expirationDate.toIso8601String().split('T')[0]; // YYYY-MM-DD
      }

      // Use provided photo or default
      final String photoToSubmit = (itemPhoto != null && itemPhoto.trim().isNotEmpty)
          ? itemPhoto.trim()
          : _defaultItemPhotoUrl;

      final response = await http.post(
        Uri.parse('$baseUrl/api/items/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'itemName': itemName,
          'itemPhoto': photoToSubmit,
          'householdId': householdId,
          'location': location,
          'price': price,
          'expirationDate': formattedExpirationDate,
          'barcode': barcode,
          'category': category,
        }),
      );

      if (kDebugMode) {
        print('===== API RESPONSE (Add Item) =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      return response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) {
        print('Exception when adding item: $e');
      }
      return false;
    }
  }

  // For future implementation:
  // 1. deleteItem method to call the delete API
  // 2. updateItem method to call the update API

  Future<List<Item>> getItems() async {
    // This is a placeholder as mentioned in your code
    return [];
  }
}