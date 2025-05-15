import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:gradproject2025/data/Models/item_model.dart';

class ItemsService {
  final String baseUrl;

  ItemsService({required this.baseUrl});

  // Get the authentication token from SharedPreferences
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // Add a new item to the database
  Future<bool> addItem(
    String itemName,
    String? itemPhoto,
    int householdId,
    double price,
    DateTime? expirationDate,
  ) async {
    try {
      final token = await _getToken();
      if (kDebugMode) {
        print('Adding item: $itemName with photo: $itemPhoto');
        print('Token: $token');
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Error: No authentication token found');
        }
        return false;
      }

      // Format the date to ISO format if it exists
      String? formattedDate;
      if (expirationDate != null) {
        formattedDate = expirationDate.toIso8601String().split('T')[0]; // Get YYYY-MM-DD format
      }

      // Make the API request with all required fields
      final response = await http.post(
        Uri.parse('$baseUrl/api/items/create'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({
          'itemName': itemName,
          'itemPhoto': itemPhoto,
          'householdId': householdId,
          'location': 'in_house', // Default as required by the backend
          'price': price,
          'expirationDate': formattedDate,
        }),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else {
        if (kDebugMode) {
          print('Failed to add item. Status: ${response.statusCode}, Error: ${response.body}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception when adding item: $e');
      }
      return false;
    }
  }

  // Get all items from the database
  Future<List<Item>> getItems() async {
    try {
      final token = await _getToken();
      if (kDebugMode) {
        print('Fetching items with token: $token');
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Error: No authentication token found');
        }
        return [];
      }

      // Use the correct endpoint - update this to match your backend API
      final response = await http.get(
        Uri.parse('$baseUrl/api/items/list'), // Use /list endpoint instead of just /items
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Item.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch items. Status: ${response.statusCode}, Error: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception when fetching items: $e');
      }
      return [];
    }
  }

  // Update an existing item
  Future<bool> updateItem(String itemId, String name, String? photoUrl) async {
    try {
      final token = await _getToken();
      if (kDebugMode) {
        print('Updating item $itemId: name=$name, photoUrl=$photoUrl');
        print('Token: $token');
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Error: No authentication token found');
        }
        return false;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/api/items/$itemId'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'name': name, 'photoUrl': photoUrl}),
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Exception when updating item: $e');
      }
      return false;
    }
  }

  // Delete an item
  Future<bool> deleteItem(String itemId) async {
    try {
      final token = await _getToken();
      if (kDebugMode) {
        print('Deleting item $itemId');
        print('Token: $token');
      }

      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Error: No authentication token found');
        }
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/api/items/$itemId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Exception when deleting item: $e');
      }
      return false;
    }
  }

  // Get a household items
  Future<List<Item>> getHouseholdItems(String householdId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) {
          print('Error: No authentication token found');
        }
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/items/household/$householdId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Item.fromJson(item)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to fetch items. Status: ${response.statusCode}, Error: ${response.body}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception when fetching household items: $e');
      }
      return [];
    }
  }

  Future<List<Item>> getToBuyItems(String householdId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/items/to-buy/$householdId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Item.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception when fetching to buy items: $e');
      }
      return [];
    }
  }
}
