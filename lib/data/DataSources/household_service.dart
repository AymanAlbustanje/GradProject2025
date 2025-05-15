import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:gradproject2025/data/Models/household_model.dart';

class HouseholdService {
  final String baseUrl;

  HouseholdService({required this.baseUrl});

  // Helper method to get the auth token
  Future<Map<String, String>> _getAuthHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Household>> getMyHouseholds() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/households'),
        headers: headers,
      );
      
      if (kDebugMode) {
        print('GET Households Response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> households = responseData['households'];
        return households.map((json) => Household.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load households: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting households: $e');
      }
      throw Exception('Failed to load households: $e');
    }
  }

  Future<void> createHousehold(String name) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/households/create'),
        headers: headers,
        body: json.encode({'name': name}),
      );
      
      if (kDebugMode) {
        print('Create Household Response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      if (response.statusCode != 201) {
        throw Exception('Failed to create household: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating household: $e');
      }
      throw Exception('Failed to create household: $e');
    }
  }

  Future<void> joinHousehold(String inviteCode) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/households/join'),
        headers: headers,
        body: json.encode({'inviteCode': inviteCode}),
      );
      
      if (kDebugMode) {
        print('Join Household Response: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
      
      if (response.statusCode != 200) {
        throw Exception('Failed to join household: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error joining household: $e');
      }
      throw Exception('Failed to join household: $e');
    }
  }
}