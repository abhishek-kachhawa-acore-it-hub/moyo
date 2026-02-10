import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:first_flutter/widgets/button_large.dart';
import 'package:first_flutter/widgets/user_only_title_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../providers/provider_navigation_provider.dart';
import 'ProviderProfileProvider.dart';
import 'EditProviderProfileProvider.dart';

class EditProviderProfileScreen extends StatefulWidget {
  const EditProviderProfileScreen({super.key});

  @override
  State<EditProviderProfileScreen> createState() =>
      _EditProviderProfileScreenState();
}

class _EditProviderProfileScreenState extends State<EditProviderProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  late TextEditingController _aadhaarController;
  late TextEditingController _panController;

  File? _aadhaarImage;
  File? _panImage;
  bool _isActive = false;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _aadhaarController = TextEditingController();
    _panController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  void _loadProfileData() {
    final profileProvider = context.read<ProviderProfileProvider>();
    if (profileProvider.providerProfile != null) {
      setState(() {
        // Format Aadhaar with dashes if it exists
        String aadhaarNo = profileProvider.providerProfile?.adharNo ?? '';
        _aadhaarController.text = _formatAadhaar(aadhaarNo);
        _isActive = profileProvider.providerProfile?.isActive ?? false;
        _isRegistered = profileProvider.providerProfile?.isRegistered ?? false;
      });
    }
  }

  String _formatAadhaar(String value) {
    // Remove all non-digits
    String digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    // Add dash after every 4 digits
    String formatted = '';
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += '-';
      }
      formatted += digitsOnly[i];
    }
    return formatted;
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _panController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source, bool isAadhaar) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isAadhaar) {
            _aadhaarImage = File(pickedFile.path);
          } else {
            _panImage = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      _showErrorSnackBar('Error picking image: $e');
    }
  }

  void _showImagePickerDialog(bool isAadhaar) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Choose ${isAadhaar ? 'Aadhaar' : 'PAN'} Photo',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: Icon(
                    Icons.photo_camera,
                    color: ColorConstant.moyoOrange,
                  ),
                  title: Text('Camera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isAadhaar);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.photo_library,
                    color: ColorConstant.moyoOrange,
                  ),
                  title: Text('Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isAadhaar);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill all required fields correctly');
      return;
    }

    // Remove dashes from Aadhaar before sending
    String cleanAadhaar = _aadhaarController.text.replaceAll('-', '');

    print('=== Starting Profile Update ===');
    print('Aadhaar: $cleanAadhaar');
    print('PAN: ${_panController.text.trim()}');
    print('IsActive: $_isActive');
    print('IsRegistered: $_isRegistered');
    print('Has Aadhaar Image: ${_aadhaarImage != null}');
    print('Has PAN Image: ${_panImage != null}');

    final editProvider = context.read<EditProviderProfileProvider>();
    final profileProvider = context.read<ProviderProfileProvider>();

    final success = await editProvider.updateProviderProfile(
      adharNo: cleanAadhaar,
      panNo: _panController.text.trim(),
      isActive: _isActive,
      isRegistered: _isRegistered,
      aadhaarPhoto: _aadhaarImage,
      panPhoto: _panImage,
    );

    if (success) {
      _showSuccessSnackBar('Profile updated successfully!');

      // Update SharedPreferences with new registration status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_provider_registered', _isRegistered);

      // Reload the profile data to get updated info
      await profileProvider.loadProviderProfile();

      // Check if this was the first-time registration completion
      final wasRegistered =
          profileProvider.providerProfile?.isRegistered ?? false;

      if (mounted) {
        if (_isRegistered && !wasRegistered) {
          // User just completed registration for the first time
          // Navigate to ProviderCustomBottomNav
          Navigator.pushNamedAndRemoveUntil(
            context,
            "/ProviderCustomBottomNav",
            (route) => false, // Remove all previous routes
          );
          context.read<ProviderNavigationProvider>().currentIndex = 0;
        } else {
          // User is just editing their profile (already registered)
          // Just pop back to previous screen
          Navigator.pop(context, true);
        }
      }
    } else {
      print('=== Profile Update Failed ===');
      print('Error: ${editProvider.errorMessage}');
      _showErrorSnackBar(
        editProvider.errorMessage ?? 'Failed to update profile',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserOnlyTitleAppbar(title: "Edit Provider Profile"),
      backgroundColor: Color(0xFFF5F5F5),
      body: Consumer2<ProviderProfileProvider, EditProviderProfileProvider>(
        builder: (context, profileProvider, editProvider, child) {
          if (profileProvider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: ColorConstant.moyoOrange),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    _buildSectionTitle(context, "Document Information"),
                    _buildAadhaarTextField(),
                    _buildPANTextField(),

                    _buildSectionTitle(context, "Document Photos"),
                    _buildImagePicker(
                      label: "Aadhaar Photo",
                      image: _aadhaarImage,
                      existingImageUrl:
                          profileProvider.providerProfile?.aadhaarPhoto,
                      onTap: () => _showImagePickerDialog(true),
                    ),
                    _buildImagePicker(
                      label: "PAN Photo",
                      image: _panImage,
                      existingImageUrl: null,
                      onTap: () => _showImagePickerDialog(false),
                    ),

                    _buildSectionTitle(context, "Account Status"),
                    _buildSwitchTile(
                      title: "Active Status",
                      subtitle: "Set your account as active or inactive",
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      title: "Registration Status",
                      subtitle: "Mark your registration as complete",
                      value: _isRegistered,
                      onChanged: (value) {
                        setState(() {
                          _isRegistered = value;
                        });
                      },
                    ),

                    SizedBox(height: 20),
                    ButtonLarge(
                      isIcon: false,
                      label: editProvider.isLoading
                          ? "Saving..."
                          : "Save Changes",
                      backgroundColor: ColorConstant.moyoOrange,
                      labelColor: Colors.white,
                      onTap: editProvider.isLoading
                          ? () {} // Empty function instead of null
                          : _saveProfile,
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  Widget _buildAadhaarTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _aadhaarController,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(12),
          TextInputFormatter.withFunction((oldValue, newValue) {
            // Format the text with dashes
            String text = newValue.text;
            String formatted = _formatAadhaar(text);

            return TextEditingValue(
              text: formatted,
              selection: TextSelection.collapsed(offset: formatted.length),
            );
          }),
        ],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter Aadhaar number';
          }
          String digitsOnly = value.replaceAll('-', '');
          if (digitsOnly.length != 12) {
            return 'Aadhaar number must be exactly 12 digits';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: "Aadhaar Number",
          hintText: "1234-5678-9012",
          prefixIcon: Icon(Icons.credit_card, color: ColorConstant.moyoOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPANTextField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _panController,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [
          LengthLimitingTextInputFormatter(10),
          FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          TextInputFormatter.withFunction((oldValue, newValue) {
            return TextEditingValue(
              text: newValue.text.toUpperCase(),
              selection: newValue.selection,
            );
          }),
        ],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter PAN number';
          }
          // PAN format: 5 letters, 4 digits, 1 letter (e.g., ABCDE1234F)
          RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
          if (!panRegex.hasMatch(value.trim())) {
            return 'Invalid PAN format (e.g., ABCDE1234F)';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: "PAN Number",
          hintText: "ABCDE1234F",
          prefixIcon: Icon(Icons.badge, color: ColorConstant.moyoOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: ColorConstant.moyoOrange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String label,
    required File? image,
    required String? existingImageUrl,
    required VoidCallback onTap,
  }) {
    final bool hasNewImage = image != null;
    final bool hasExistingImage =
        existingImageUrl != null && existingImageUrl.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                TextButton.icon(
                  onPressed: onTap,
                  icon: Icon(Icons.add_photo_alternate, size: 20),
                  label: Text(hasNewImage ? 'Change' : 'Upload'),
                  style: TextButton.styleFrom(
                    foregroundColor: ColorConstant.moyoOrange,
                  ),
                ),
              ],
            ),
          ),
          if (hasNewImage || hasExistingImage)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: hasNewImage
                      ? Image.file(image, fit: BoxFit.cover)
                      : CachedNetworkImage(
                          imageUrl: existingImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: ColorConstant.moyoOrange,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.error_outline,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        value: value,
        activeColor: ColorConstant.moyoOrange,
        onChanged: onChanged,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}
