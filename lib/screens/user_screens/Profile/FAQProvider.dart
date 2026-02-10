// providers/faq_provider.dart

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FAQ {
  final String id;
  final String question;
  final String answer;
  final String category;
  final bool isActive;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  FAQ({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.isActive,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromJson(Map<String, dynamic> json) {
    return FAQ(
      id: json['id'] ?? '',
      question: json['question'] ?? '',
      answer: json['answer'] ?? '',
      category: json['category'] ?? '',
      isActive: json['is_active'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}

class FAQProvider with ChangeNotifier {
  List<FAQ> _faqs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _expandedFaqId; // Changed to use FAQ ID instead of index

  List<FAQ> get faqs => _faqs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if a specific FAQ is expanded
  bool isExpanded(String faqId) => _expandedFaqId == faqId;

  Future<void> loadFAQs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://api.moyointernational.com/api/faq'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true && jsonResponse['data'] != null) {
          final List<dynamic> faqList = jsonResponse['data'];
          _faqs = faqList
              .map((faqJson) => FAQ.fromJson(faqJson))
              .where((faq) => faq.isActive) // Only show active FAQs
              .toList();

          // Sort by sortOrder
          _faqs.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

          _errorMessage = null;
        } else {
          _errorMessage = 'Invalid response format';
          _faqs = [];
        }
      } else {
        _errorMessage = 'Failed to load FAQs: ${response.statusCode}';
        _faqs = [];
      }
    } catch (e) {
      _errorMessage = 'Error loading FAQs: ${e.toString()}';
      _faqs = [];
      if (kDebugMode) {
        print('FAQ Error: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleExpanded(String faqId) {
    // If clicking the same FAQ, close it. Otherwise, open the new one
    if (_expandedFaqId == faqId) {
      _expandedFaqId = null;
    } else {
      _expandedFaqId = faqId;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}