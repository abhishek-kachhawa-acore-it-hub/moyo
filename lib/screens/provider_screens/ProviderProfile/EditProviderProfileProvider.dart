import 'dart:convert';
import 'dart:io';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class EditProviderProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> updateProviderProfile({
    required String adharNo,
    required String panNo,
    required bool isActive,
    required bool isRegistered,
    File? aadhaarPhoto,
    File? panPhoto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('=== Starting API Call ===');

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('provider_auth_token');

      print('Token exists: ${token != null && token.isNotEmpty}');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login again.');
      }

      final url = '$base_url/api/provider/update-profile';
      print('API URL: $url');

      // Create multipart request
      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      print('Headers added: ${request.headers}');

      // Add text fields
      request.fields['adhar_no'] = adharNo;
      request.fields['pan_no'] = panNo;
      request.fields['isactive'] = isActive.toString();
      request.fields['isregistered'] = isRegistered.toString();

      print('Fields added: ${request.fields}');

      // Add aadhaar photo if provided
      if (aadhaarPhoto != null) {
        print('Checking Aadhaar photo...');
        bool exists = await aadhaarPhoto.exists();
        print('Aadhaar photo exists: $exists');

        if (exists) {
          try {
            String fileName = path.basename(aadhaarPhoto.path);
            String extension = path.extension(aadhaarPhoto.path).toLowerCase();
            print('Aadhaar file: $fileName, Extension: $extension');

            MediaType? contentType;
            if (extension == '.jpg' || extension == '.jpeg') {
              contentType = MediaType('image', 'jpeg');
            } else if (extension == '.png') {
              contentType = MediaType('image', 'png');
            } else if (extension == '.gif') {
              contentType = MediaType('image', 'gif');
            } else if (extension == '.webp') {
              contentType = MediaType('image', 'webp');
            } else {
              // Default to jpeg if unknown
              contentType = MediaType('image', 'jpeg');
            }

            print('Content type: $contentType');

            var aadhaarBytes = await aadhaarPhoto.readAsBytes();
            print('Aadhaar bytes length: ${aadhaarBytes.length}');

            var aadhaarFile = http.MultipartFile.fromBytes(
              'aadhaar_photo',
              aadhaarBytes,
              filename: fileName,
              contentType: contentType,
            );
            request.files.add(aadhaarFile);
            print('Aadhaar photo added to request');
          } catch (e) {
            print('Error reading aadhaar photo: $e');
            throw Exception('Failed to read Aadhaar photo: $e');
          }
        } else {
          print('Aadhaar photo file does not exist at path: ${aadhaarPhoto.path}');
        }
      } else {
        print('No Aadhaar photo provided');
      }

      // Add PAN photo if provided
      if (panPhoto != null) {
        print('Checking PAN photo...');
        bool exists = await panPhoto.exists();
        print('PAN photo exists: $exists');

        if (exists) {
          try {
            String fileName = path.basename(panPhoto.path);
            String extension = path.extension(panPhoto.path).toLowerCase();
            print('PAN file: $fileName, Extension: $extension');

            MediaType? contentType;
            if (extension == '.jpg' || extension == '.jpeg') {
              contentType = MediaType('image', 'jpeg');
            } else if (extension == '.png') {
              contentType = MediaType('image', 'png');
            } else if (extension == '.gif') {
              contentType = MediaType('image', 'gif');
            } else if (extension == '.webp') {
              contentType = MediaType('image', 'webp');
            } else {
              // Default to jpeg if unknown
              contentType = MediaType('image', 'jpeg');
            }

            print('Content type: $contentType');

            var panBytes = await panPhoto.readAsBytes();
            print('PAN bytes length: ${panBytes.length}');

            var panFile = http.MultipartFile.fromBytes(
              'pan_photo',
              panBytes,
              filename: fileName,
              contentType: contentType,
            );
            request.files.add(panFile);
            print('PAN photo added to request');
          } catch (e) {
            print('Error reading pan photo: $e');
            throw Exception('Failed to read PAN photo: $e');
          }
        } else {
          print('PAN photo file does not exist at path: ${panPhoto.path}');
        }
      } else {
        print('No PAN photo provided');
      }

      print('Total files in request: ${request.files.length}');
      print('Sending request...');

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('=== API Response ===');
      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = json.decode(response.body);
          print('Parsed JSON: $jsonData');

          if (jsonData['message'] != null) {
            print('Success: ${jsonData['message']}');
            _errorMessage = null;
            _isLoading = false;
            notifyListeners();
            return true;
          } else {
            throw Exception('Unexpected response format: missing message field');
          }
        } catch (e) {
          print('Error parsing response: $e');
          throw Exception('Failed to parse server response: $e');
        }
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else if (response.statusCode == 400) {
        try {
          final jsonData = json.decode(response.body);
          throw Exception(jsonData['message'] ?? 'Bad request. Please check your input.');
        } catch (e) {
          throw Exception('Bad request. Please check your input.');
        }
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        try {
          final jsonData = json.decode(response.body);
          throw Exception(jsonData['message'] ?? 'Failed to update profile (Status: ${response.statusCode})');
        } catch (e) {
          throw Exception('Failed to update profile (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      print('=== Error ===');
      print('Error updating provider profile: $e');
      print('Stack trace: ${StackTrace.current}');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

class UpdateProfileResponse {
  final String message;
  final UpdateProfileResult result;

  UpdateProfileResponse({required this.message, required this.result});

  factory UpdateProfileResponse.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponse(
      message: json['message'] ?? '',
      result: UpdateProfileResult.fromJson(json['result'] ?? {}),
    );
  }
}

class UpdateProfileResult {
  final String? adharNo;
  final String? isActive;
  final String? isRegistered;
  final String? panNo;

  UpdateProfileResult({
    this.adharNo,
    this.isActive,
    this.isRegistered,
    this.panNo,
  });

  factory UpdateProfileResult.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResult(
      adharNo: json['adhar_no'],
      isActive: json['isactive'],
      isRegistered: json['isregistered'],
      panNo: json['pan_no'],
    );
  }
}