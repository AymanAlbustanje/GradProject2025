import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gradproject2025/data/Models/item_model.dart';

class ToBuyService {
  final String baseUrl;

  ToBuyService({required this.baseUrl});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Item>> getToBuyItems(dynamic householdId) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    try {
      final String householdIdStr = householdId is int ? householdId.toString() : householdId;

      final response = await http.get(
        Uri.parse('$baseUrl/api/household-items?householdId=$householdIdStr&location=to_buy'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('===== GET TO BUY ITEMS RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('items') && data['items'] is List) {
          final List<dynamic> itemsJson = data['items'];
          return itemsJson.map((item) => Item.fromJson(item)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to fetch To Buy items. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching To Buy items: $e');
      }
      throw Exception('Failed to fetch To Buy items: $e');
    }
  }

  Future<bool> moveItemToBuy({required dynamic householdItemId, required dynamic householdId}) async {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    try {
      final int itemIdInt = householdItemId is String ? int.parse(householdItemId) : householdItemId;
      final int householdIdInt = householdId is String ? int.parse(householdId) : householdId;

      if (kDebugMode) {
        print('Moving item ID: $itemIdInt to shopping list, household ID: $householdIdInt');
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/household-items/move-to-buy'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'householdItemId': itemIdInt, 'householdId': householdIdInt}),
      );

      if (kDebugMode) {
        print('===== MOVE TO BUY RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('Error moving item to shopping list: $e');
      }
      throw Exception('Failed to move item to shopping list: $e');
    }
  }

  Future<bool> moveItemToHouse({
    required int householdItemId,
    required dynamic householdId,
    required double price,
    DateTime? expirationDate,
  }) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        if (kDebugMode) print('Authentication token is missing');
        return false;
      }

      final Map<String, dynamic> requestBody = {
        'householdItemId': householdItemId,
        'householdId': householdId,
        'price': price,
      };

      if (expirationDate != null) {
        requestBody['expirationDate'] = expirationDate.toIso8601String().split('T')[0];
      }

      final response = await http.patch(
        Uri.parse('$baseUrl/api/household-items/move-to-house'),
        headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        print('===== API RESPONSE (Move Item to House) =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('Error moving item to house: $e');
      return false;
    }
  }
}
