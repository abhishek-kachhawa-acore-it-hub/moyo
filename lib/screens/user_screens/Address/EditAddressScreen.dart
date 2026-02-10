import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../../constants/colorConstant/color_constant.dart';
import '../User Instant Service/UserLocationPickerScreen.dart';

class EditAddressScreen extends StatefulWidget {
  final int addressId;
  final Map<String, dynamic> addressData;

  const EditAddressScreen({
    Key? key,
    required this.addressId,
    required this.addressData,
  }) : super(key: key);

  @override
  State<EditAddressScreen> createState() => _EditAddressScreenState();
}

class _EditAddressScreenState extends State<EditAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  // Address type
  String _addressType = 'home';
  bool _isDefault = false;
  bool _isLoading = false;

  // Store selected location
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    _addressType = widget.addressData['type'] ?? 'home';
    _addressLine1Controller.text = widget.addressData['address_line1'] ?? '';
    _addressLine2Controller.text = widget.addressData['address_line2'] ?? '';
    _landmarkController.text = widget.addressData['landmark'] ?? '';
    _cityController.text = widget.addressData['city'] ?? '';
    _stateController.text = widget.addressData['state'] ?? '';
    _pincodeController.text = widget.addressData['pincode'] ?? '';
    _countryController.text = widget.addressData['country'] ?? '';

    // Parse latitude and longitude
    final latitude = widget.addressData['latitude'];
    final longitude = widget.addressData['longitude'];

    if (latitude != null) {
      _selectedLatitude = double.tryParse(latitude.toString());
      _latitudeController.text = _selectedLatitude?.toStringAsFixed(6) ?? '';
    }

    if (longitude != null) {
      _selectedLongitude = double.tryParse(longitude.toString());
      _longitudeController.text = _selectedLongitude?.toStringAsFixed(6) ?? '';
    }

    _isDefault = widget.addressData['is_default'] ?? false;
  }

  @override
  void dispose() {
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Validation Methods
  String? _validateAddressLine1(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address line 1 is required';
    }
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    if (value.trim().length > 200) {
      return 'Address must not exceed 200 characters';
    }
    return null;
  }

  String? _validateAddressLine2(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 200) {
        return 'Address must not exceed 200 characters';
      }
    }
    return null;
  }

  String? _validateLandmark(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      if (value.trim().length > 100) {
        return 'Landmark must not exceed 100 characters';
      }
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'City name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'City name must not exceed 50 characters';
    }
    final cityRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!cityRegex.hasMatch(value.trim())) {
      return 'City name can only contain letters';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length < 2) {
      return 'State name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'State name must not exceed 50 characters';
    }
    final stateRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!stateRegex.hasMatch(value.trim())) {
      return 'State name can only contain letters';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Pincode is required';
    }
    final cleanedValue = value.trim().replaceAll(' ', '');

    if (!RegExp(r'^\d+$').hasMatch(cleanedValue)) {
      return 'Pincode must contain only numbers';
    }

    if (cleanedValue.length < 4) {
      return 'Pincode must be at least 4 digits';
    }
    if (cleanedValue.length > 10) {
      return 'Pincode must not exceed 10 digits';
    }
    return null;
  }

  String? _validateCountry(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Country is required';
    }
    if (value.trim().length < 2) {
      return 'Country name must be at least 2 characters';
    }
    if (value.trim().length > 50) {
      return 'Country name must not exceed 50 characters';
    }
    final countryRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!countryRegex.hasMatch(value.trim())) {
      return 'Country name can only contain letters';
    }
    return null;
  }

  String? _validateLocation() {
    if (_selectedLatitude == null || _selectedLongitude == null) {
      return 'Please select location on map';
    }
    return null;
  }

  Future<String?> _getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      print('Error getting auth token: $e');
      return null;
    }
  }

  // Open map to select location
  Future<void> _openMapPicker() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserLocationPickerScreen(
            initialLatitude: _selectedLatitude,
            initialLongitude: _selectedLongitude,
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        setState(() {
          _selectedLatitude = result['latitude'] as double?;
          _selectedLongitude = result['longitude'] as double?;

          // Update latitude/longitude fields
          if (_selectedLatitude != null) {
            _latitudeController.text = _selectedLatitude!.toStringAsFixed(6);
          }
          if (_selectedLongitude != null) {
            _longitudeController.text = _selectedLongitude!.toStringAsFixed(6);
          }

          // Optionally update address line 1 with the returned address
          final address = result['address'] as String?;
          if (address != null && address.isNotEmpty) {
            // Show dialog to ask if user wants to update address
            _showAddressUpdateDialog(address);
          }
        });

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location updated successfully'),
              backgroundColor: ColorConstant.moyoGreen,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error opening map picker: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening map: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showAddressUpdateDialog(String address) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Address?'),
        content: Text('Do you want to update address line 1 with:\n\n"$address"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() {
        _addressLine1Controller.text = address;
      });
    }
  }

  Future<void> _updateAddress() async {
    // Validate location first
    final locationError = _validateLocation();
    if (locationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(locationError),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix all errors before submitting'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final token = await _getAuthToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication required. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$base_url/api/user/addresses/${widget.addressId}');

      final body = {
        'type': _addressType,
        'address_line1': _addressLine1Controller.text.trim(),
        'address_line2': _addressLine2Controller.text.trim(),
        'landmark': _landmarkController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'pincode': _pincodeController.text.trim().replaceAll(' ', ''),
        'country': _countryController.text.trim(),
        'latitude': _selectedLatitude ?? 0.0,
        'longitude': _selectedLongitude ?? 0.0,
        'is_default': _isDefault,
      };

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['status'] == true) {
          // Success
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['message'] ?? 'Address updated successfully',
                ),
                backgroundColor: ColorConstant.moyoGreen,
              ),
            );
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to update address',
          );
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update address');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteAddress() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final token = await _getAuthToken();

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication required. Please login again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse('$base_url/api/user/addresses/${widget.addressId}');

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await http.delete(url, headers: headers);

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['status'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  responseData['message'] ?? 'Address deleted successfully',
                ),
                backgroundColor: ColorConstant.moyoGreen,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          throw Exception(
            responseData['message'] ?? 'Failed to delete address',
          );
        }
      } else {
        throw Exception(responseData['message'] ?? 'Failed to delete address');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: ColorConstant.moyoOrange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ColorConstant.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Address',
          style: TextStyle(
            color: ColorConstant.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: ColorConstant.white),
            onPressed: _isLoading ? null : _deleteAddress,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ColorConstant.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Home'),
                      value: 'home',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value ?? 'home';
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Office'),
                      value: 'office',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value ?? 'office';
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Other'),
                      value: 'other',
                      groupValue: _addressType,
                      activeColor: ColorConstant.moyoOrange,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) {
                        setState(() {
                          _addressType = value ?? 'other';
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Map Location Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ColorConstant.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedLatitude == null || _selectedLongitude == null
                        ? Colors.red.withOpacity(0.5)
                        : ColorConstant.moyoOrange.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: _selectedLatitude == null || _selectedLongitude == null
                              ? Colors.red
                              : ColorConstant.moyoOrange,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedLatitude != null && _selectedLongitude != null
                                ? 'Location Selected'
                                : 'Select Location on Map *',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _selectedLatitude == null || _selectedLongitude == null
                                  ? Colors.red
                                  : ColorConstant.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedLatitude != null && _selectedLongitude != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, '
                            'Long: ${_selectedLongitude!.toStringAsFixed(6)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _openMapPicker,
                        icon: Icon(
                          _selectedLatitude != null && _selectedLongitude != null
                              ? Icons.edit_location
                              : Icons.map,
                          size: 20,
                        ),
                        label: Text(
                          _selectedLatitude != null && _selectedLongitude != null
                              ? 'Change Location'
                              : 'Open Map',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: ColorConstant.moyoOrange,
                          side: BorderSide(color: ColorConstant.moyoOrange),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Address Line 1',
                controller: _addressLine1Controller,
                hint: 'Enter address line 1',
                validator: _validateAddressLine1,
                maxLength: 200,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Address Line 2',
                controller: _addressLine2Controller,
                hint: 'Enter address line 2 (Optional)',
                validator: _validateAddressLine2,
                maxLength: 200,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                label: 'Landmark',
                controller: _landmarkController,
                hint: 'Enter landmark (Optional)',
                validator: _validateLandmark,
                maxLength: 100,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'City',
                      controller: _cityController,
                      hint: 'Enter city',
                      validator: _validateCity,
                      maxLength: 50,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'State',
                      controller: _stateController,
                      hint: 'Enter state',
                      validator: _validateState,
                      maxLength: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Pincode',
                      controller: _pincodeController,
                      hint: 'Enter pincode',
                      keyboardType: TextInputType.number,
                      validator: _validatePincode,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Country',
                      controller: _countryController,
                      hint: 'Enter country',
                      validator: _validateCountry,
                      maxLength: 50,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Latitude',
                      controller: _latitudeController,
                      hint: 'Auto-filled',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      label: 'Longitude',
                      controller: _longitudeController,
                      hint: 'Auto-filled',
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              CheckboxListTile(
                title: const Text('Set as default address'),
                value: _isDefault,
                activeColor: ColorConstant.moyoOrange,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() {
                    _isDefault = value ?? false;
                  });
                },
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.moyoOrange,
                    disabledBackgroundColor: ColorConstant.moyoOrange.withOpacity(0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: ColorConstant.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Update Address',
                    style: TextStyle(
                      color: ColorConstant.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: ColorConstant.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: readOnly ? Colors.grey[100] : ColorConstant.white,
            counterText: maxLength != null ? '' : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: ColorConstant.moyoOrange,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}