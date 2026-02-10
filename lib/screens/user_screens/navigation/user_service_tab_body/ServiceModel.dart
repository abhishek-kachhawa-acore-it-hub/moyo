class ServiceResponse {
  final bool success;
  final int total;
  final List<ServiceModel> services;

  ServiceResponse({
    required this.success,
    required this.total,
    required this.services,
  });

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class ServiceModel {
  final String id;
  final String title;
  final String category;
  final String service;
  final String description;
  final String userId;
  final String budget;
  final String maxBudget;
  final String tenure;
  final String? scheduleDate;
  final String? scheduleTime;
  final String serviceType;
  final String location;
  final String latitude;
  final String longitude;
  final String serviceMode;
  final int? durationValue;
  final String? durationUnit;
  final int? serviceDays;
  final String? startDate;
  final String? endDate;
  final int extraTimeMinutes;
  final String? assignedProviderId;
  final String status;
  final String? reason;
  final String? startedAt;
  final String? arrivedAt;
  final String? endedAt;
  final String? confirmedAt;
  final String? startOtp;
  final String? endOtp;
  final String paymentMethod;
  final String paymentType;
  final String? finalAmount;
  final Map<String, dynamic>? dynamicFields;
  final String? cancelledBy;
  final String? cancelReason;
  final String? cancelledAt;
  final String createdAt;
  final String updatedAt;
  final bool isCalculate;
  final String totalBids;
  final List<BidModel> bids;
  final AssignedProvider? assignedProvider;
  final StatusDetails? statusDetails;
  final String createdAtFormatted;

  ServiceModel({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.userId,
    required this.budget,
    required this.maxBudget,
    required this.tenure,
    this.scheduleDate,
    this.scheduleTime,
    required this.serviceType,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.serviceMode,
    this.durationValue,
    this.durationUnit,
    this.serviceDays,
    this.startDate,
    this.endDate,
    required this.extraTimeMinutes,
    this.assignedProviderId,
    required this.status,
    this.reason,
    this.startedAt,
    this.arrivedAt,
    this.endedAt,
    this.confirmedAt,
    this.startOtp,
    this.endOtp,
    required this.paymentMethod,
    required this.paymentType,
    this.finalAmount,
    this.dynamicFields,
    this.cancelledBy,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.isCalculate,
    required this.totalBids,
    this.bids = const [],
    this.assignedProvider,
    this.statusDetails,
    required this.createdAtFormatted,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      category: json['category'] ?? '',
      service: json['service'] ?? '',
      description: json['description'] ?? '',
      userId: json['user_id']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '0',
      maxBudget: json['max_budget']?.toString() ?? '0',
      tenure: json['tenure'] ?? '',
      scheduleDate: json['schedule_date'],
      scheduleTime: json['schedule_time'],
      serviceType: json['service_type'] ?? '',
      location: json['location'] ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      serviceMode: json['service_mode'] ?? '',
      durationValue: json['duration_value'],
      durationUnit: json['duration_unit'],
      serviceDays: json['service_days'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      extraTimeMinutes: json['extra_time_minutes'] ?? 0,
      assignedProviderId: json['assigned_provider_id']?.toString(),
      status: json['status'] ?? '',
      reason: json['reason'],
      startedAt: json['started_at'],
      arrivedAt: json['arrived_at'],
      endedAt: json['ended_at'],
      confirmedAt: json['confirmed_at'],
      startOtp: json['start_otp'],
      endOtp: json['end_otp'],
      paymentMethod: json['payment_method'] ?? '',
      paymentType: json['payment_type'] ?? '',
      finalAmount: json['final_amount']?.toString(),
      dynamicFields: json['dynamic_fields'] as Map<String, dynamic>?,
      cancelledBy: json['cancelled_by'],
      cancelReason: json['cancel_reason'],
      cancelledAt: json['cancelled_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      isCalculate: json['is_calculate'] ?? false,
      totalBids: json['total_bids']?.toString() ?? '0',
      bids: (json['bids'] as List<dynamic>?)
          ?.map((e) => BidModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      assignedProvider: json['assigned_provider'] != null
          ? AssignedProvider.fromJson(json['assigned_provider'])
          : null,
      statusDetails: json['status_details'] != null
          ? StatusDetails.fromJson(json['status_details'])
          : null,
      createdAtFormatted: json['created_at_formatted'] ?? '',
    );
  }

  String getBidAmount() {
    if (bids.isNotEmpty) {
      return bids.first.amount.toString();
    }
    return budget;
  }
}

class BidModel {
  final int bidId;
  final int providerId;
  final double amount;
  final String notes;
  final String status;
  final String createdAt;

  BidModel({
    required this.bidId,
    required this.providerId,
    required this.amount,
    required this.notes,
    required this.status,
    required this.createdAt,
  });

  factory BidModel.fromJson(Map<String, dynamic> json) {
    return BidModel(
      bidId: json['bid_id'] ?? 0,
      providerId: json['provider_id'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bid_id': bidId,
      'provider_id': providerId,
      'amount': amount,
      'notes': notes,
      'status': status,
      'created_at': createdAt,
    };
  }
}

class AssignedProvider {
  final int id;
  final int userId;
  final String? education;
  final String? educationProof;
  final String? aadhaarPhoto;
  final String? adharNo;
  final bool isActive;
  final bool isRegistered;
  final bool isBlocked;
  final String createdAt;
  final String updatedAt;
  final String? panNo;
  final String? panPhoto;
  final String? deviceToken;
  final int workRadius;
  final bool notified;
  final bool declaration;
  final ProviderUser? user;

  AssignedProvider({
    required this.id,
    required this.userId,
    this.education,
    this.educationProof,
    this.aadhaarPhoto,
    this.adharNo,
    required this.isActive,
    required this.isRegistered,
    required this.isBlocked,
    required this.createdAt,
    required this.updatedAt,
    this.panNo,
    this.panPhoto,
    this.deviceToken,
    required this.workRadius,
    required this.notified,
    required this.declaration,
    this.user,
  });

  factory AssignedProvider.fromJson(Map<String, dynamic> json) {
    return AssignedProvider(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      education: json['education'],
      educationProof: json['education_proof'],
      aadhaarPhoto: json['aadhaar_photo'],
      adharNo: json['adhar_no'],
      isActive: json['isactive'] ?? false,
      isRegistered: json['isregistered'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      panNo: json['pan_no'],
      panPhoto: json['pan_photo'],
      deviceToken: json['device_token'],
      workRadius: json['work_radius'] ?? 0,
      notified: json['notified'] ?? false,
      declaration: json['declaration'] ?? false,
      user: json['user'] != null ? ProviderUser.fromJson(json['user']) : null,
    );
  }
}

class ProviderUser {
  final int id;
  final String firstname;
  final String lastname;
  final String username;
  final String email;
  final String mobile;
  final String gender;
  final int age;
  final String? image;
  final String? otp;
  final String? otpExpiresAt;
  final bool isRegister;
  final bool isProvider;
  final bool isBlocked;
  final String uid;
  final String? deviceToken;
  final String? emailOtp;
  final String referralCode;
  final String? referredBy;
  final double wallet;
  final int? count;
  final String? emailOtpExpiresAt;
  final bool emailVerified;
  final String createdAt;
  final String updatedAt;
  final String? primaryAddressId;
  final bool declaration;

  ProviderUser({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.username,
    required this.email,
    required this.mobile,
    required this.gender,
    required this.age,
    this.image,
    this.otp,
    this.otpExpiresAt,
    required this.isRegister,
    required this.isProvider,
    required this.isBlocked,
    required this.uid,
    this.deviceToken,
    this.emailOtp,
    required this.referralCode,
    this.referredBy,
    required this.wallet,
    this.count,
    this.emailOtpExpiresAt,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
    this.primaryAddressId,
    required this.declaration,
  });

  factory ProviderUser.fromJson(Map<String, dynamic> json) {
    return ProviderUser(
      id: json['id'] ?? 0,
      firstname: json['firstname'] ?? '',
      lastname: json['lastname'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      mobile: json['mobile'] ?? '',
      gender: json['gender'] ?? '',
      age: json['age'] ?? 0,
      image: json['image'],
      otp: json['otp'],
      otpExpiresAt: json['otp_expires_at'],
      isRegister: json['isregister'] ?? false,
      isProvider: json['is_provider'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      uid: json['uid'] ?? '',
      deviceToken: json['device_token'],
      emailOtp: json['email_otp'],
      referralCode: json['referral_code'] ?? '',
      referredBy: json['referred_by'],
      wallet: (json['wallet'] ?? 0).toDouble(),
      count: json['count'],
      emailOtpExpiresAt: json['email_otp_expires_at'],
      emailVerified: json['email_verified'] ?? false,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      primaryAddressId: json['primary_address_id']?.toString(),
      declaration: json['declaration'] ?? false,
    );
  }
}

class StatusDetails {
  final String label;
  final String description;
  final String color;

  StatusDetails({
    required this.label,
    required this.description,
    required this.color,
  });

  factory StatusDetails.fromJson(Map<String, dynamic> json) {
    return StatusDetails(
      label: json['label'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'description': description,
      'color': color,
    };
  }
}