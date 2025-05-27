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
  
  Future<double> getTotalMoneySpent(String householdId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/total_money_spent?householdId=$householdId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('===== GET TOTAL MONEY SPENT RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The backend sends {"message":"...", "totalMoneySpent": value}
        // Ensure the key matches what your backend sends.
        // If totalMoneySpent can be null from backend, handle it.
        final dynamic spentAmount = data['totalMoneySpent'];
        if (spentAmount is num) {
          return spentAmount.toDouble();
        } else if (spentAmount is String) {
          return double.tryParse(spentAmount) ?? 0.0;
        }
        return 0.0; // Default if null or not a number
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to load total money spent: ${errorData['message'] ?? response.reasonPhrase}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching total money spent: $e');
      }
      throw Exception('Failed to fetch total money spent: $e');
    }
  }
  Future<List<Map<String, dynamic>>> getBottomPurchasedItems(String householdId) async {
  try {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/statistics/purchase_counter-bottom?householdId=$householdId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      print('===== GET BOTTOM PURCHASED ITEMS RESPONSE =====');
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
      throw Exception('Failed to load least purchased items');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching least purchased items: $e');
    }
    throw Exception('Failed to fetch least purchased items: $e');
  }
}

Future<List<Map<String, dynamic>>> getBottomExpensiveItems(String householdId) async {
  try {
    final token = await _getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/api/statistics/total_purchase_price-bottom?householdId=$householdId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (kDebugMode) {
      print('===== GET BOTTOM EXPENSIVE ITEMS RESPONSE =====');
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
      throw Exception('Failed to load least expensive items');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching least expensive items: $e');
    }
    throw Exception('Failed to fetch least expensive items: $e');
  }
}
}