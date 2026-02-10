import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_flutter/baseControllers/APis.dart';

class MySkillProvider extends ChangeNotifier {
  List<Skill> _skills = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Skill> get skills => _skills;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch all skills
  Future<void> fetchSkills() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await http.get(
        Uri.parse('$base_url/api/provider/skills'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic>? skillsJson = data['skills'];

        if (skillsJson != null) {
          _skills = skillsJson.map((json) => Skill.fromJson(json)).toList();
        } else {
          _errorMessage = 'No skills data found';
        }
      } else {
        _errorMessage = 'Failed to load skills: ${response.statusCode}';
      }
    } catch (e) {
      _errorMessage = 'Error: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update skill is_checked status
  Future<bool> updateSkillCheckedStatus(int skillId, bool isChecked) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not found';
        notifyListeners();
        return false;
      }

      final response = await http.put(
        Uri.parse('$base_url/api/provider/skill/check/$skillId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'is_checked': isChecked,
        }),
      );

      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          // Update the local skill object
          final index = _skills.indexWhere((skill) => skill.id == skillId);
          if (index != -1) {
            _skills[index] = Skill.fromJson(data['data']);
            notifyListeners();
          }
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Failed to update skill status';
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Failed to update: ${response.statusCode}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating skill: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  // Update skill details (for rejected skills)
  Future<bool> updateSkill({
    required int skillId,
    required String skillName,
    required String serviceName,
    required String experience,
    File? proofDocument,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      if (token == null || token.isEmpty) {
        _errorMessage = 'Authentication token not found';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$base_url/api/provider/update-skills'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add form fields
      request.fields['id'] = skillId.toString();
      request.fields['skill_name'] = skillName;
      request.fields['service_name'] = serviceName;
      request.fields['experience'] = experience;

      // Add file if provided
      if (proofDocument != null) {
        var stream = http.ByteStream(proofDocument.openRead());
        var length = await proofDocument.length();
        var multipartFile = http.MultipartFile(
          'proof_document',
          stream,
          length,
          filename: proofDocument.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Update Skill Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true || data['message'] != null) {
          // Refresh skills list to get updated data
          await fetchSkills();
          return true;
        } else {
          _errorMessage = data['message'] ?? 'Failed to update skill';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        _errorMessage = 'Failed to update: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error updating skill: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class Skill {
  final int? id;
  final String? skillName;
  final String? serviceName;
  final String? experience;
  final String? proofDocument;
  final String? status;
  final bool? isChecked;
  final String? createdAt;

  Skill({
    this.id,
    this.skillName,
    this.serviceName,
    this.experience,
    this.proofDocument,
    this.status,
    this.isChecked,
    this.createdAt,
  });

  factory Skill.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return Skill();
    }

    return Skill(
      id: json['id'] as int?,
      skillName: json['skill_name'] as String?,
      serviceName: json['service_name'] as String?,
      experience: json['experience'] as String?,
      proofDocument: json['proof_document'] as String?,
      status: json['status'] as String?,
      isChecked: json['is_checked'] as bool?,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill_name': skillName,
      'service_name': serviceName,
      'experience': experience,
      'proof_document': proofDocument,
      'status': status,
      'is_checked': isChecked,
      'created_at': createdAt,
    };
  }
}