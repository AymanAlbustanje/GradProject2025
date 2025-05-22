import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsService {
  final String baseUrl;

  StatisticsService({required this.baseUrl});

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Map<String, dynamic>>> getTopPurchasedItems(String householdId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/purchase_counter-top?householdId=$householdId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('===== GET TOP PURCHASED ITEMS RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] is List) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
        return [];
      } else {
        throw Exception('Failed to load top purchased items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching top purchased items: $e');
      }
      throw Exception('Failed to fetch top purchased items: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopExpensiveItems(String householdId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/total_purchase_price-top?householdId=$householdId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('===== GET TOP EXPENSIVE ITEMS RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['items'] is List) {
          return List<Map<String, dynamic>>.from(data['items']);
        }
        return [];
      } else {
        throw Exception('Failed to load top expensive items');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching top expensive items: $e');
      }
      throw Exception('Failed to fetch top expensive items: $e');
    }
  }
}