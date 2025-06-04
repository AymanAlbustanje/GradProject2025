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

  Future<List<Map<String, dynamic>>> _fetchItemsStatistic(
    String householdId,
    String endpointSuffix,
    String errorContext,
  ) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found for $errorContext');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/$endpointSuffix?householdId=$householdId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('===== GET $errorContext RESPONSE =====');
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
        throw Exception('Failed to load $errorContext. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching $errorContext: $e');
      }
      throw Exception('Failed to fetch $errorContext: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopPurchasedItems(String householdId) async {
    return _fetchItemsStatistic(householdId, 'purchase_counter-top', 'top purchased items');
  }

  Future<List<Map<String, dynamic>>> getTopExpensiveItems(String householdId) async {
    return _fetchItemsStatistic(householdId, 'total_purchase_price-top', 'top expensive items');
  }

  Future<double> getTotalMoneySpent(String householdId) async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/statistics/total_money_spent?householdId=$householdId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (kDebugMode) {
        print('===== GET TOTAL MONEY SPENT RESPONSE =====');
        print('Status code: ${response.statusCode}');
        print('Body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dynamic spentAmount = data['totalMoneySpent'];
        if (spentAmount is num) {
          return spentAmount.toDouble();
        } else if (spentAmount is String) {
          return double.tryParse(spentAmount) ?? 0.0;
        }
        return 0.0;
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
    return _fetchItemsStatistic(householdId, 'purchase_counter-bottom', 'least purchased items');
  }

  Future<List<Map<String, dynamic>>> getBottomExpensiveItems(String householdId) async {
    return _fetchItemsStatistic(householdId, 'total_purchase_price-bottom', 'least expensive items');
  }
}
