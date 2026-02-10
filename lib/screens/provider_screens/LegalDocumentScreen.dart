import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../constants/colorConstant/color_constant.dart';

// Model for Legal Document
class LegalDocument {
  final int id;
  final String type;
  final String role;
  final String title;
  final String content;
  final bool isActive;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  LegalDocument({
    required this.id,
    required this.type,
    required this.role,
    required this.title,
    required this.content,
    required this.isActive,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LegalDocument.fromJson(Map<String, dynamic> json) {
    return LegalDocument(
      id: json['id'],
      type: json['type'],
      role: json['role'],
      title: json['title'],
      content: json['content'],
      isActive: json['is_active'],
      version: json['version'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

// Provider for managing legal documents
class LegalDocumentProvider extends ChangeNotifier {
  LegalDocument? _document;
  bool _isLoading = false;
  String? _error;
  bool _isDocumentNotAvailable = false;

  LegalDocument? get document => _document;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isDocumentNotAvailable => _isDocumentNotAvailable;

  Future<void> fetchDocument(String type, String role) async {
    _isLoading = true;
    _error = null;
    _isDocumentNotAvailable = false;
    notifyListeners();
    print("$base_url/api/admin/legal/latest?type=$type&role=$role");
    try {
      final url = role.isNotEmpty
          ? '$base_url/api/admin/legal/latest?type=$type&role=$role'
          : '$base_url/api/admin/legal/by-type?type=terms';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['success'] == true && jsonData['data'] != null) {
          _document = LegalDocument.fromJson(jsonData['data']);
          _error = null;
          _isDocumentNotAvailable = false;
        } else {
          _error = 'Failed to load document';
          _isDocumentNotAvailable = false;
        }
      } else if (response.statusCode == 404) {
        // Handle 404 - Document not available
        final jsonData = json.decode(response.body);
        if (jsonData['message'] == 'Document not available') {
          _isDocumentNotAvailable = true;
          _error = null;
        } else {
          _error = 'Document not found';
          _isDocumentNotAvailable = true;
        }
      } else {
        _error = 'Server error: ${response.statusCode}';
        _isDocumentNotAvailable = false;
      }
    } catch (e) {
      _error = 'Network error: $e';
      _isDocumentNotAvailable = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearDocument() {
    _document = null;
    _error = null;
    _isLoading = false;
    _isDocumentNotAvailable = false;
    notifyListeners();
  }
}

// Legal Document Screen
class LegalDocumentScreen extends StatefulWidget {
  final String type; // privacy_policy, terms, code_of_conduct
  final List<String> roles; // ["user", "provider"]

  const LegalDocumentScreen({Key? key, required this.type, required this.roles})
    : super(key: key);

  @override
  State<LegalDocumentScreen> createState() => _LegalDocumentScreenState();
}

class _LegalDocumentScreenState extends State<LegalDocumentScreen> {
  late LegalDocumentProvider _provider;
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _provider = LegalDocumentProvider();
    _selectedRole = widget.roles.isNotEmpty ? widget.roles.first : null;
    if (_selectedRole != null) {
      _loadDocument();
    }
  }

  void _loadDocument() {
    if (_selectedRole != null) {
      _provider.fetchDocument(widget.type, _selectedRole!);
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case 'privacy_policy':
        return 'Privacy Policy';
      case 'terms':
        return 'Terms of Service';
      case 'code_of_conduct':
        return 'Code of Conduct';
      default:
        return 'Legal Document';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: ColorConstant.scaffoldGray,
          appBar: AppBar(
            backgroundColor: ColorConstant.appColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: ColorConstant.white,
                size: 24.sp,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _getTitle(),
              style: TextStyle(
                color: ColorConstant.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
          ),
          body: AnimatedBuilder(
            animation: _provider,
            builder: (context, child) {
              if (_provider.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: ColorConstant.moyoOrange,
                  ),
                );
              }

              // Handle 404 - Document not available
              if (_provider.isDocumentNotAvailable) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64.sp,
                          color: ColorConstant.black.withOpacity(0.4),
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'No Document Available',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.black,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'The requested document is not currently available.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: ColorConstant.black.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (_provider.error != null) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64.sp,
                          color: Colors.red,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          'Error loading document',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: ColorConstant.black,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          _provider.error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: ColorConstant.black.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: 24.h),
                        ElevatedButton(
                          onPressed: _loadDocument,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorConstant.moyoOrange,
                            padding: EdgeInsets.symmetric(
                              horizontal: 32.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: ColorConstant.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (_provider.document == null) {
                return Center(
                  child: Text(
                    'No document available',
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: ColorConstant.black.withOpacity(0.6),
                    ),
                  ),
                );
              }

              return Column(
                children: [
                  // Role Selector (if multiple roles)
                  if (widget.roles.length > 1)
                    Container(
                      margin: EdgeInsets.all(16.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: ColorConstant.white,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View as:',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: ColorConstant.black,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Wrap(
                              spacing: 8.w,
                              children: widget.roles.map((role) {
                                final isSelected = role == _selectedRole;
                                return ChoiceChip(
                                  label: Text(
                                    role.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? ColorConstant.white
                                          : ColorConstant.black,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: ColorConstant.moyoOrange,
                                  backgroundColor: ColorConstant.moyoOrangeFade,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _selectedRole = role;
                                      });
                                      _loadDocument();
                                    }
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Document Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16.w),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: ColorConstant.white,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Document Header
                            Text(
                              _provider.document!.title,
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: ColorConstant.black,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 14.sp,
                                  color: ColorConstant.black.withOpacity(0.6),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Version ${_provider.document!.version}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: ColorConstant.black.withOpacity(0.6),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Icon(
                                  Icons.calendar_today,
                                  size: 14.sp,
                                  color: ColorConstant.black.withOpacity(0.6),
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  'Updated: ${_formatDate(_provider.document!.updatedAt)}',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: ColorConstant.black.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.h),
                            Divider(
                              color: ColorConstant.black.withOpacity(0.1),
                            ),
                            SizedBox(height: 16.h),

                            // HTML Content
                            Html(
                              data: _provider.document!.content,
                              style: {
                                "body": Style(
                                  fontSize: FontSize(14.sp),
                                  lineHeight: LineHeight(1.6),
                                  color: ColorConstant.black,
                                ),
                                "h1": Style(
                                  fontSize: FontSize(20.sp),
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstant.black,
                                  margin: Margins.only(top: 16.h, bottom: 8.h),
                                ),
                                "h2": Style(
                                  fontSize: FontSize(18.sp),
                                  fontWeight: FontWeight.bold,
                                  color: ColorConstant.black,
                                  margin: Margins.only(top: 14.h, bottom: 6.h),
                                ),
                                "h3": Style(
                                  fontSize: FontSize(16.sp),
                                  fontWeight: FontWeight.w600,
                                  color: ColorConstant.black,
                                  margin: Margins.only(top: 12.h, bottom: 4.h),
                                ),
                                "p": Style(
                                  fontSize: FontSize(14.sp),
                                  color: ColorConstant.black,
                                  margin: Margins.only(bottom: 12.h),
                                ),
                                "ul": Style(
                                  margin: Margins.only(
                                    left: 16.w,
                                    bottom: 12.h,
                                  ),
                                ),
                                "ol": Style(
                                  margin: Margins.only(
                                    left: 16.w,
                                    bottom: 12.h,
                                  ),
                                ),
                                "li": Style(
                                  fontSize: FontSize(14.sp),
                                  color: ColorConstant.black,
                                  margin: Margins.only(bottom: 6.h),
                                ),
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }
}
