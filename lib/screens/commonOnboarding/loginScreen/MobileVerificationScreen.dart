import 'dart:async';
import 'package:first_flutter/constants/colorConstant/color_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../user_screens/Profile/EditProfileProvider.dart';

class MobileVerificationDialog {
  static Future<bool?> show(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _MobileVerificationDialogContent(),
    );
  }
}

class _MobileVerificationDialogContent extends StatefulWidget {
  const _MobileVerificationDialogContent();

  @override
  State<_MobileVerificationDialogContent> createState() =>
      __MobileVerificationDialogContentState();
}

class __MobileVerificationDialogContentState
    extends State<_MobileVerificationDialogContent> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendCountdown = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_resendCountdown > 0) {
            _resendCountdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String _getOtpCode() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _clearOtp() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes[0].requestFocus();
  }

  Future<void> _handleVerify() async {
    final editProvider = context.read<EditProfileProvider>();
    final otp = _getOtpCode();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter complete 6-digit OTP'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    editProvider.clearMobileError();

    final verified = await editProvider.verifyMobileOtp(otp: otp);

    if (verified && mounted) {
      Navigator.pop(context, true);
    } else if (editProvider.mobileErrorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.mobileErrorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _clearOtp();
    }
  }

  /*
  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    final editProvider = context.read<EditProfileProvider>();
    editProvider.clearMobileError();

    final success = await editProvider.resendMobileOtp();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('OTP sent successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _startResendTimer();
      _clearOtp();
    } else if (editProvider.mobileErrorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(editProvider.mobileErrorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
*/

  @override
  Widget build(BuildContext context) {
    return Consumer<EditProfileProvider>(
      builder: (context, editProvider, child) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r),
          ),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: ColorConstant.white,
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header Icon
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: ColorConstant.moyoOrange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.phone_android,
                      size: 48.sp,
                      color: ColorConstant.moyoOrange,
                    ),
                  ),
                  SizedBox(height: 24.h),

                  // Title
                  Text(
                    'Verify Mobile Number',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: ColorConstant.black,
                      fontSize: 22.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),

                  // Subtitle
                  Text(
                    'Enter the 6-digit code sent to',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF7A7A7A),
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    editProvider.mobileController.text.trim(),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ColorConstant.moyoOrange,
                      fontSize: 16.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),

                  // OTP Input Fields
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      6,
                      (index) => _buildOtpField(index),
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // Verify Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: editProvider.isMobileOtpVerifying
                          ? null
                          : _handleVerify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorConstant.moyoOrange,
                        foregroundColor: ColorConstant.white,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: ColorConstant.moyoOrange
                            .withOpacity(0.6),
                      ),
                      child: editProvider.isMobileOtpVerifying
                          ? SizedBox(
                              height: 20.h,
                              width: 20.w,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.w,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ColorConstant.white,
                                ),
                              ),
                            )
                          : Text(
                              'Verify Mobile',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: ColorConstant.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16.sp,
                                  ),
                            ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Resend OTP Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive the code? ",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF7A7A7A),
                          fontSize: 14.sp,
                        ),
                      ),
                      if (_canResend)
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            'Resend',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ColorConstant.moyoOrange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14.sp,
                                  decoration: TextDecoration.underline,
                                ),
                          ),
                        )
                      else
                        Text(
                          'Resend in ${_resendCountdown}s',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey, fontSize: 14.sp),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Cancel Button
                  TextButton(
                    onPressed: editProvider.isMobileOtpVerifying
                        ? null
                        : () {
                            editProvider.resetMobileVerificationState();
                            Navigator.pop(context, false);
                          },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 40.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _otpControllers[index].text.isNotEmpty
              ? ColorConstant.moyoOrange
              : Colors.grey.shade300,
          width: 2.w,
        ),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: ColorConstant.black,
        ),
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _otpFocusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _otpFocusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }
}
