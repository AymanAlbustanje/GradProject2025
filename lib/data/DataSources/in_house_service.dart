import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gradproject2025/data/Models/item_model.dart';

class InHouseService {
  final String baseUrl;
  static const String _defaultItemPhotoUrl = 'https://i.pinimg.com/736x/82/be/d4/82bed479344270067e3d2171379949b3.jpg';

  InHouseService({required this.baseUrl});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Item>> getHouseholdItems(String householdId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      if (kDebugMode) print('Authentication token not found for getHouseholdItems.');
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
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('items') && data['items'] is List) {
          final List<dynamic> itemsJson = data['items'];
          return itemsJson.map((itemJson) => Item.fromJson(itemJson)).toList();
        } else {
          if (kDebugMode) print('No "items" list found in response or it is not a list.');
          return [];
        }
      } else {
        if (kDebugMode) print('Failed to fetch in-house items. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to fetch in-house items. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching in-house items: $e');
      }
      throw Exception('Failed to fetch in-house items: $e');
    }
  }

  Future<String> addItem({
    required String itemName,
    String? itemPhoto,
    required String householdId,
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
        throw Exception('Authentication token not found');
      }

      String? formattedExpirationDate;
      if (expirationDate != null) {
        formattedExpirationDate = expirationDate.toIso8601String().split('T')[0];
      }

      final String photoToSubmit =
          (itemPhoto != null && itemPhoto.trim().isNotEmpty) ? itemPhoto.trim() : _defaultItemPhotoUrl;

      final Map<String, dynamic> requestBody = {
        'itemName': itemName,
        'itemPhoto': photoToSubmit,
        'householdId': householdId,
        'location': location,
        'price': price,
        'category': category,
      };

      if (formattedExpirationDate != null) {
        requestBody['expirationDate'] = formattedExpirationDate;
      }
      if (barcode != null && barcode.isNotEmpty) {
        requestBody['barcode'] = barcode;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/items/create'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('===== API RESPONSE (Add Item Service) =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final dynamic newHouseholdItemId = responseData['household_item_id'];
        if (newHouseholdItemId != null) {
          return newHouseholdItemId.toString();
        } else {
          if (kDebugMode) print("Error: 'household_item_id' not found in addItem response or is null.");
          throw Exception("'household_item_id' not found in response");
        }
      } else {
        if (kDebugMode) print('Failed to add item. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to add item. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception when adding item via service: $e');
      }
      throw Exception('Failed to add item: $e');
    }
  }

  Future<List<Item>> getItems() async {
    if (kDebugMode) {
      print('getItems() in InHouseService is a placeholder and was called.');
    }
    return [];
  }
}
