import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class UserSearchProvider extends ChangeNotifier {
  List<UserSearchData> _users = [];
  bool _isLoading = false;
  String _error = '';
  String _searchKeyword = '';

  List<UserSearchData> get users => _users;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasResults => _users.isNotEmpty;
  String get searchKeyword => _searchKeyword;

  Future<void> searchUsers(String keyword) async {
    if (keyword.trim().isEmpty) {
      _users.clear();
      _error = '';
      _searchKeyword = '';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = '';
    _searchKeyword = keyword;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('https://api.moyointernational.com/api/user/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'keyword': keyword}),
      );

      if (response.statusCode == 200 || response.statusCode == 400) {
        final data = jsonDecode(response.body);

        // Null safety checks
        if (data != null && data['success'] == true) {
          final dataList = data['data'] as List?;
          if (dataList != null && dataList.isEmpty) {
            // Empty results - show "no service found"
            _users.clear();
            _error = 'No services found';
          } else if (dataList != null) {
            _users = dataList
                .map((user) => UserSearchData.fromJson(user))
                .where((user) => user != null)
                .cast<UserSearchData>()
                .toList();

            // If still empty after mapping, show no services
            if (_users.isEmpty) {
              _error = 'No services found';
            }
          } else {
            _users.clear();
            _error = 'No services found';
          }
        } else {
          _users.clear();
          _error = data?['message'] ?? 'Search failed';
        }
      } else {
        _users.clear();
        _error = 'Failed to search users (Status: ${response.statusCode})';
      }
    } catch (e) {
      _users.clear();
      _error = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _users.clear();
    _error = '';
    _searchKeyword = '';
    _isLoading = false;
    notifyListeners();
  }
}

class UserSearchData {
  final int id;
  final int categoryId;
  final String categoryName;
  final String name;
  final String billingType;
  final String hourlyRate;
  final String dailyRate;
  final String icon;

  UserSearchData({
    required this.id,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.billingType,
    required this.hourlyRate,
    required this.dailyRate,
    required this.icon,
  });

  factory UserSearchData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return UserSearchData(
      id: 0,
      categoryId: 0,
      categoryName: '',
      name: '',
      billingType: '',
      hourlyRate: '0.00',
      dailyRate: '0.00',
      icon: '',
    );

    return UserSearchData(
      id: json['id'] ?? 0,
      categoryId: json['category_id'] ?? 0,
      categoryName: json['category_name'] ?? '',
      name: json['name'] ?? '',
      billingType: json['billing_type'] ?? '',
      hourlyRate: json['hourly_rate']?.toString() ?? '0.00',
      dailyRate: json['daily_rate']?.toString() ?? '0.00',
      icon: json['icon'] ?? '',
    );
  }
}
