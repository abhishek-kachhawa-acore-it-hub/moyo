import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../provider_screens/StartWorkProvider.dart';

class EndWorkOTPDialog extends StatefulWidget {
  final String serviceId;

  const EndWorkOTPDialog({Key? key, required this.serviceId}) : super(key: key);

  @override
  State<EndWorkOTPDialog> createState() => _EndWorkOTPDialogState();
}

class _EndWorkOTPDialogState extends State<EndWorkOTPDialog> {
  late final List<TextEditingController> otpControllers;
  late final List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    otpControllers = List.generate(4, (index) => TextEditingController());
    focusNodes = List.generate(4, (index) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 600;

    // Responsive sizing
    final dialogPadding = isTablet ? 32.0 : (isSmallScreen ? 16.0 : 24.0);
    final titleFontSize = isTablet ? 28.0 : (isSmallScreen ? 20.0 : 24.0);
    final subtitleFontSize = isTablet ? 16.0 : (isSmallScreen ? 12.0 : 14.0);
    final otpBoxWidth = isTablet ? 65.0 : (isSmallScreen ? 45.0 : 55.0);
    final otpBoxHeight = isTablet ? 75.0 : (isSmallScreen ? 55.0 : 65.0);
    final otpFontSize = isTablet ? 36.0 : (isSmallScreen ? 24.0 : 28.0);
    final buttonFontSize = isTablet ? 16.0 : (isSmallScreen ? 13.0 : 14.0);
    final buttonPaddingH = isTablet ? 32.0 : (isSmallScreen ? 20.0 : 24.0);
    final buttonPaddingV = isTablet ? 12.0 : (isSmallScreen ? 8.0 : 10.0);

    return Consumer<StartWorkProvider>(
      builder: (context, startWorkProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isTablet ? 32.r : 28.r),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isTablet ? 500 : (isSmallScreen ? 280 : 400),
              maxHeight: screenHeight * 0.8,
            ),
            padding: EdgeInsets.all(dialogPadding),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'End Work OTP',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8.h : 12.h),
                  Text(
                    'Enter the 4-digit OTP to complete work',
                    style: TextStyle(
                      fontSize: subtitleFontSize,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isSmallScreen ? 24.h : 32.h),
                  // OTP Input Fields
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      final spacing = isSmallScreen ? 8.0 : (isTablet ? 16.0 : 12.0);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return Container(
                            width: otpBoxWidth,
                            height: otpBoxHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(
                                isTablet ? 20.r : (isSmallScreen ? 12.r : 16.r),
                              ),
                              border: Border.all(
                                color: startWorkProvider.errorMessage != null
                                    ? Colors.red
                                    : Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: focusNodes[index],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: TextStyle(
                                fontSize: otpFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                if (startWorkProvider.errorMessage != null) {
                                  startWorkProvider.clearError();
                                }

                                if (value.isNotEmpty && index < 3) {
                                  focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  if (startWorkProvider.errorMessage != null) ...[
                    SizedBox(height: isSmallScreen ? 12.h : 16.h),
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 8.w : 12.w),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: isSmallScreen ? 18.sp : 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              startWorkProvider.errorMessage!,
                              style: TextStyle(
                                color: Colors.red[700],
                                fontSize: isSmallScreen ? 11.sp : 13.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: isSmallScreen ? 24.h : 32.h),
                  // Buttons
                  Flex(
                    direction: isSmallScreen ? Axis.vertical : Axis.horizontal,
                    mainAxisAlignment: isSmallScreen
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.spaceBetween,
                    children: [
                      if (isSmallScreen) ...[
                        // Complete Work button first on small screens
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: startWorkProvider.isProcessing
                                ? null
                                : () async {
                              final otp = otpControllers
                                  .map((controller) => controller.text)
                                  .join();

                              if (otp.length != 4) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please enter complete OTP',
                                      style: TextStyle(fontSize: buttonFontSize - 2),
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final success = await startWorkProvider.endWork(
                                widget.serviceId,
                                otp,
                              );

                              if (success && mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: buttonPaddingH,
                                vertical: buttonPaddingV,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                            ),
                            child: startWorkProvider.isProcessing
                                ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Complete Work',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: startWorkProvider.isProcessing
                                ? null
                                : () {
                              startWorkProvider.reset();
                              Navigator.of(context).pop(null);
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: buttonFontSize,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Original layout for larger screens
                        TextButton(
                          onPressed: startWorkProvider.isProcessing
                              ? null
                              : () {
                            startWorkProvider.reset();
                            Navigator.of(context).pop(null);
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: startWorkProvider.isProcessing
                              ? null
                              : () async {
                            final otp = otpControllers
                                .map((controller) => controller.text)
                                .join();

                            if (otp.length != 4) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Please enter complete OTP',
                                    style: TextStyle(fontSize: buttonFontSize - 2),
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final success = await startWorkProvider.endWork(
                              widget.serviceId,
                              otp,
                            );

                            if (success && mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: buttonPaddingH,
                              vertical: buttonPaddingV,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                          child: startWorkProvider.isProcessing
                              ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Complete Work',
                            style: TextStyle(
                              fontSize: buttonFontSize,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}