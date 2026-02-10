import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class EmergencyContact {
  final int id;
  final String title;
  final String email;
  final String mobile;
  final String message;
  final bool isActive;

  EmergencyContact({
    required this.id,
    required this.title,
    required this.email,
    required this.mobile,
    required this.message,
    required this.isActive,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      message: json['message'] ?? '',
      isActive: json['is_active'] ?? false,
    );
  }
}

enum ContactLoadingState { idle, loading, success, error }

class EmergencyContactProvider with ChangeNotifier {
  List<EmergencyContact> _emergencyContacts = [];
  ContactLoadingState _loadingState = ContactLoadingState.idle;
  String? _errorMessage;
  Timer? _debounceTimer;

  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  ContactLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _loadingState == ContactLoadingState.loading;
  bool get hasError => _loadingState == ContactLoadingState.error;

  // Cache management
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(minutes: 5);

  bool get _shouldRefetch {
    if (_lastFetchTime == null) return true;
    return DateTime.now().difference(_lastFetchTime!) > _cacheDuration;
  }

  Future<void> fetchEmergencyContacts({
    required String baseUrl,
    bool forceRefresh = false,
  }) async {
    // Return cached data if available and not expired
    if (!forceRefresh &&
        _emergencyContacts.isNotEmpty &&
        !_shouldRefetch &&
        _loadingState == ContactLoadingState.success) {
      return;
    }

    // Debounce multiple simultaneous calls
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer?.cancel();
    }

    _debounceTimer = Timer(Duration(milliseconds: 300), () async {
      await _performFetch(baseUrl);
    });
  }

  Future<void> _performFetch(String baseUrl) async {
    _loadingState = ContactLoadingState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/bid/api/admin/contacts/active'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      )
          .timeout(
        Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Request timed out'),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        if (jsonData['success'] == true && jsonData['data'] != null) {
          _emergencyContacts = (jsonData['data'] as List)
              .map((contact) => EmergencyContact.fromJson(contact))
              .where((contact) => contact.isActive)
              .toList();

          _lastFetchTime = DateTime.now();
          _loadingState = ContactLoadingState.success;
          _errorMessage = null;
        } else {
          throw Exception('Invalid response format');
        }
      } else if (response.statusCode == 404) {
        _errorMessage = 'Emergency contacts not found';
        _loadingState = ContactLoadingState.error;
      } else if (response.statusCode >= 500) {
        _errorMessage = 'Server error. Please try again later';
        _loadingState = ContactLoadingState.error;
      } else {
        _errorMessage = 'Failed to load contacts (${response.statusCode})';
        _loadingState = ContactLoadingState.error;
      }
    } on TimeoutException {
      _errorMessage = 'Request timed out. Check your internet connection';
      _loadingState = ContactLoadingState.error;
    } on http.ClientException {
      _errorMessage = 'Network error. Please check your connection';
      _loadingState = ContactLoadingState.error;
    } catch (e) {
      _errorMessage = 'Failed to load emergency contacts';
      _loadingState = ContactLoadingState.error;
      debugPrint('Error fetching contacts: $e');
    }

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    if (_loadingState == ContactLoadingState.error) {
      _loadingState = ContactLoadingState.idle;
    }
    notifyListeners();
  }

  void reset() {
    _emergencyContacts = [];
    _loadingState = ContactLoadingState.idle;
    _errorMessage = null;
    _lastFetchTime = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}