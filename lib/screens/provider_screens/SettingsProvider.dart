import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  int _maxSearchDistance = 21;  // Changed from double to int

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  int get maxSearchDistance => _maxSearchDistance;  // Changed return type

  // Set max search distance
  // Change line 14-17:
  void setMaxSearchDistance(int distance) {  // Changed parameter type
    _maxSearchDistance = distance;
    notifyListeners();
  }

  // Update work radius API call
  Future<bool> updateWorkRadius(int radius) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Get token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final url = Uri.parse('$base_url/api/provider/update-radius');

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'work_radius': radius}),  // Remove .toStringAsFixed(1)
      );

      print(radius.toStringAsFixed(1));
      _isLoading = false;

      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Success
        _maxSearchDistance = radius;

        // Save to SharedPreferences
        await prefs.setInt('maxSearchDistance', radius);  // Changed from setDouble to setInt

        notifyListeners();
        return true;
      } else {
        // Error response
        final responseData = jsonDecode(response.body);
        _errorMessage = responseData['message'] ?? 'Failed to update radius';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Load saved radius from SharedPreferences
  Future<void> loadSavedRadius() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _maxSearchDistance = prefs.getInt('maxSearchDistance') ?? 21;  // Changed from getDouble to getInt
      notifyListeners();
    } catch (e) {
      print('Error loading saved radius: $e');
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
