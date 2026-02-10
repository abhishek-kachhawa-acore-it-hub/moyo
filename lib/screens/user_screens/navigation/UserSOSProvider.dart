import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserSOSProvider extends ChangeNotifier {
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _sosToken;

  bool get isLoading => _isLoading;

  bool get hasError => _hasError;

  String? get errorMessage => _errorMessage;

  String? get sosToken => _sosToken;

  /// Trigger SOS API call for user
  Future<bool> triggerSOS({
    required String serviceId,
    required String latitude,
    required String longitude,
    String message = "Emergency assistance required",
  }) async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userAuthToken = prefs.getString('auth_token');
      final url = Uri.parse('$base_url/bid/api/admin/sos');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $userAuthToken',
        },
        body: jsonEncode({
          'service_id': serviceId,
          'latitude': latitude,
          'longitude': longitude,
          'message': message,
        }),
      );

      _isLoading = false;

      print(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Extract the provider_auth_token from response
        if (data['provider_auth_token'] != null) {
          _sosToken = data['provider_auth_token'];
        } else if (data['data'] != null &&
            data['data']['provider_auth_token'] != null) {
          _sosToken = data['data']['provider_auth_token'];
        }

        _hasError = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _hasError = true;
        _errorMessage = errorData['message'] ?? 'Failed to trigger SOS';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Network error: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Reset the provider state
  void reset() {
    _isLoading = false;
    _hasError = false;
    _errorMessage = null;
    _sosToken = null;
    notifyListeners();
  }
}
