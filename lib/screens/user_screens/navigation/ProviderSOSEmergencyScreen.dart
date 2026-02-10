import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../../constants/colorConstant/color_constant.dart';
import 'EmergencyContactProvider.dart';
import 'SOSProvider.dart';

class ProviderSOSEmergencyScreen extends StatefulWidget {
  final String? serviceId;
  final String? userName;
  final String? userPhone;
  final String? address;
  final String? authToken;

  const ProviderSOSEmergencyScreen({
    super.key,
    this.serviceId,
    this.userName,
    this.userPhone,
    this.address,
    this.authToken,
  });

  @override
  State<ProviderSOSEmergencyScreen> createState() =>
      _ProviderSOSEmergencyScreenState();
}

class _ProviderSOSEmergencyScreenState extends State<ProviderSOSEmergencyScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  final String policeStationNumber = "100";
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _getCurrentLocation();

    // Pre-fetch contacts for faster access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EmergencyContactProvider>().fetchEmergencyContacts(
        baseUrl: base_url,
      );
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> _triggerSOSAndProceed(VoidCallback onSuccess) async {
    if (widget.serviceId == null) {
      _showErrorDialog('Missing authentication or service information');
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: ColorConstant.moyoOrange),
              SizedBox(height: 16.h),
              Text(
                'Triggering SOS...',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final sosProvider = context.read<SOSProvider>();

    // Use current location or default values
    String latitude = _currentPosition?.latitude.toString() ?? "24.5151";
    String longitude = _currentPosition?.longitude.toString() ?? "72.454";

    final success = await sosProvider.triggerSOS(
      serviceId: widget.serviceId!,
      latitude: latitude,
      longitude: longitude,
      message: "Emergency assistance required",
    );

    // Close loading dialog
    Navigator.pop(context);

    if (success) {
      // Proceed with the original action
      onSuccess();
    } else {
      _showErrorDialog(
        sosProvider.errorMessage ?? 'Failed to trigger SOS. Please try again.',
      );
    }
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorDialog('Unable to make call. Please dial $number manually.');
      }
    } catch (e) {
      _showErrorDialog('Error making call: ${e.toString()}');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48.sp),
              SizedBox(height: 16.h),
              Text(
                'Error',
                style: GoogleFonts.roboto(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                message,
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A7A7A),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorConstant.moyoOrange,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.roboto(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showContactsBottomSheet() {
    // Trigger SOS first, then show contacts
    _triggerSOSAndProceed(() {
      // Refresh contacts when opening sheet
      context.read<EmergencyContactProvider>().fetchEmergencyContacts(
        baseUrl: base_url,
      );

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Color(0xFFE6E6E6),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),

              // Header
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Customer Support',
                      style: GoogleFonts.roboto(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Color(0xFF7A7A7A)),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: Color(0xFFE6E6E6)),

              // Content with Consumer
              Expanded(
                child: Consumer<EmergencyContactProvider>(
                  builder: (context, provider, child) {
                    return _buildContactsList(provider);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildContactsList(EmergencyContactProvider provider) {
    if (provider.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ColorConstant.moyoOrange),
            SizedBox(height: 16.h),
            Text(
              'Loading contacts...',
              style: GoogleFonts.roboto(
                fontSize: 14.sp,
                color: Color(0xFF7A7A7A),
              ),
            ),
          ],
        ),
      );
    }

    if (provider.hasError) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64.sp,
                color: Colors.red.shade300,
              ),
              SizedBox(height: 16.h),
              Text(
                provider.errorMessage ?? 'An error occurred',
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  color: Color(0xFF7A7A7A),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  provider.fetchEmergencyContacts(
                    baseUrl: base_url,
                    forceRefresh: true,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.moyoOrange,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: GoogleFonts.roboto(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.emergencyContacts.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.contacts_outlined,
                size: 64.sp,
                color: Color(0xFFE6E6E6),
              ),
              SizedBox(height: 16.h),
              Text(
                'No emergency contacts available',
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  color: Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.all(20.w),
      itemCount: provider.emergencyContacts.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) {
        final contact = provider.emergencyContacts[index];
        return _buildContactListItem(contact);
      },
    );
  }

  Widget _buildContactListItem(EmergencyContact contact) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        _makeCall(contact.mobile);
      },
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ColorConstant.scaffoldGray,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Color(0xFFE6E6E6), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: ColorConstant.moyoOrangeFade,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.support_agent,
                color: ColorConstant.moyoOrange,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.title.isNotEmpty ? contact.title : 'Support',
                    style: GoogleFonts.roboto(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    contact.mobile.isNotEmpty ? contact.mobile : 'No number',
                    style: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: ColorConstant.moyoOrange,
                    ),
                  ),
                  if (contact.message.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      contact.message,
                      style: GoogleFonts.roboto(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF7A7A7A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.phone, color: ColorConstant.moyoGreen, size: 24.sp),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 32.h),
                    _buildSOSHeroSection(),
                    SizedBox(height: 40.h),
                    _buildEmergencyContactsSection(),
                    SizedBox(height: 32.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6E6), width: 1)),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: ColorConstant.scaffoldGray,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.arrow_back,
                color: Color(0xFF1D1B20),
                size: 24.sp,
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Text(
            'Emergency SOS',
            style: GoogleFonts.roboto(
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSOSHeroSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Container(
            width: 80.w,
            height: 80.w,
            decoration: BoxDecoration(
              color: Color(0xFFFFEBEE),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notification_important,
              size: 40.sp,
              color: Color(0xFFC4242E),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Need Emergency Help?',
            style: GoogleFonts.roboto(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B20),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            'Contact our support team or emergency services immediately',
            style: GoogleFonts.roboto(
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              color: Color(0xFF7A7A7A),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contacts',
            style: GoogleFonts.roboto(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1B20),
            ),
          ),
          SizedBox(height: 20.h),

          // Customer Support Card
          _buildContactCard(
            icon: Icons.support_agent,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ColorConstant.moyoOrange, Color(0xFFFF9F3A)],
            ),
            title: 'Customer Support',
            subtitle: '24/7 Available Support',
            description: 'Get immediate assistance from our support team',
            onTap: _showContactsBottomSheet,
          ),

          SizedBox(height: 16.h),

          // Police Station Card
          _buildContactCard(
            icon: Icons.local_police,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFC4242E), Color(0xFFE63946)],
            ),
            title: 'Police Station',
            subtitle: 'Emergency Helpline 100',
            description: 'Report immediate threats or critical emergencies',
            onTap: () =>
                _triggerSOSAndProceed(() => _makeCall(policeStationNumber)),
          ),

          // Service Info
          if (widget.userName != null ||
              widget.userPhone != null ||
              widget.address != null) ...[
            SizedBox(height: 32.h),
            _buildServiceInfoCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Gradient gradient,
    required String title,
    required String subtitle,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56.w,
                    height: 56.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(icon, size: 30.sp, color: Colors.white),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.roboto(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          style: GoogleFonts.roboto(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Text(
                description,
                style: GoogleFonts.roboto(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white.withOpacity(0.95),
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone,
                      color: gradient.colors.first,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      title == 'Customer Support'
                          ? 'View Contacts'
                          : 'Call Now',
                      style: GoogleFonts.roboto(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: gradient.colors.first,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceInfoCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: ColorConstant.scaffoldGray,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Color(0xFFE6E6E6), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: ColorConstant.moyoOrangeFade,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: ColorConstant.moyoOrange,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Service Information',
                style: GoogleFonts.roboto(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D1B20),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          if (widget.userName != null) ...[
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Provider Name',
              value: widget.userName!,
            ),
            SizedBox(height: 12.h),
          ],

          if (widget.userPhone != null) ...[
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone Number',
              value: widget.userPhone!,
            ),
            SizedBox(height: 12.h),
          ],

          if (widget.address != null) ...[
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: 'Service Location',
              value: widget.address!,
              isLast: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18.sp, color: ColorConstant.moyoOrange),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.roboto(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7A7A7A),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          SizedBox(height: 12.h),
          Divider(color: Color(0xFFE6E6E6), height: 1),
        ],
      ],
    );
  }
}
