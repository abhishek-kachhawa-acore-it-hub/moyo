import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AvailabilityProvider extends ChangeNotifier {
  bool _isAvailable = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isAvailable => _isAvailable;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  // Initialize availability status from SharedPreferences
  Future<void> initializeAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isAvailable = prefs.getBool('provider_is_available') ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing availability: $e');
    }
  }

  // Toggle availability API call
  Future<void> toggleAvailability() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final providerAuthToken = prefs.getString('provider_auth_token');

      if (providerAuthToken == null || providerAuthToken.isEmpty) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }
      final response = await http
          .put(
            Uri.parse('$base_url/api/provider/toggle'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $providerAuthToken',
            },
          )
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData != null && responseData is Map<String, dynamic>) {
          _isAvailable = responseData['is_available'] ?? false;

          // Save to SharedPreferences
          await prefs.setBool('provider_is_available', _isAvailable);

          _errorMessage = null;
        } else {
          _errorMessage = 'Invalid response format';
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Unauthorized. Please login again.';
      } else {
        final responseData = json.decode(response.body);
        _errorMessage =
            responseData['message'] ?? 'Failed to toggle availability';
      }
    } catch (e) {
      _errorMessage = 'Network error: ${e.toString()}';
      debugPrint('Toggle availability error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Set availability without API call (for local state management)
  void setAvailability(bool value) {
    _isAvailable = value;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
