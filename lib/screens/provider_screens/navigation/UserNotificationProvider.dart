import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserNotificationProvider extends ChangeNotifier {
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String? _error;

  List<dynamic> get notifications => _notifications;

  bool get isLoading => _isLoading;

  String? get error => _error;

  // Fetch notifications list
  Future<void> fetchNotifications(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$base_url/bid/api/notifications/list'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['notifications'] != null) {
          _notifications = data['notifications'];
        } else {
          _notifications = [];
        }
      } else {
        _error = 'Failed to load notifications: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading notifications: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark single notification as read
  Future<bool> markAsRead(String token, int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse(
          '$base_url/bid/api/notifications/read/$notificationId',
        ),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print(response.body);
      if (response.statusCode == 200) {
        final index = _notifications.indexWhere(
              (n) => n['id'] == notificationId,
        );
        if (index != -1) {
          _notifications[index]['is_read'] = true;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read
  Future<bool> markAllAsRead(String token) async {
    try {
      final response = await http.put(
        Uri.parse('$base_url/bid/api/notifications/read-all'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Update all local notifications
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check if there are any unread notifications
  bool get hasUnreadNotifications {
    return _notifications.any((n) => !(n['is_read'] ?? false));
  }

  // Get count of unread notifications
  int get unreadCount {
    return _notifications.where((n) => !(n['is_read'] ?? false)).length;
  }
}
