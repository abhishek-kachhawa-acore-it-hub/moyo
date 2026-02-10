class CompletedServiceResponse {
  final bool success;
  final int total;
  final List<UserCompleteServiceModel> services;

  CompletedServiceResponse({
    required this.success,
    required this.total,
    required this.services,
  });

  factory CompletedServiceResponse.fromJson(Map<String, dynamic> json) {
    return CompletedServiceResponse(
      success: json['success'] ?? false,
      total: json['total'] ?? 0,
      services: (json['services'] as List<dynamic>?)
          ?.map((e) => UserCompleteServiceModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
    );
  }
}

class UserCompleteServiceModel {
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
  final int durationValue;
  final String durationUnit;
  final String? serviceDays;
  final String? startDate;
  final String? endDate;
  final int extraTimeMinutes;
  final String assignedProviderId;
  final String status;
  final String? reason;
  final String? startedAt;
  final String? arrivedAt;
  final String? endedAt;
  final String? confirmedAt;
  final String startOtp;
  final String endOtp;
  final String paymentMethod;
  final String paymentType;
  final String? finalAmount;
  final Map<String, dynamic>? dynamicFields;
  final String? cancelledBy;
  final String? cancelReason;
  final String? cancelledAt;
  final String createdAt;
  final String updatedAt;
  final String totalBids;
  final List<Bid> bids;
  final Customer customer;
  final String createdAtFormatted;

  UserCompleteServiceModel({
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
    required this.durationValue,
    required this.durationUnit,
    this.serviceDays,
    this.startDate,
    this.endDate,
    required this.extraTimeMinutes,
    required this.assignedProviderId,
    required this.status,
    this.reason,
    this.startedAt,
    this.arrivedAt,
    this.endedAt,
    this.confirmedAt,
    required this.startOtp,
    required this.endOtp,
    required this.paymentMethod,
    required this.paymentType,
    this.finalAmount,
    this.dynamicFields,
    this.cancelledBy,
    this.cancelReason,
    this.cancelledAt,
    required this.createdAt,
    required this.updatedAt,
    required this.totalBids,
    required this.bids,
    required this.customer,
    required this.createdAtFormatted,
  });

  factory UserCompleteServiceModel.fromJson(Map<String, dynamic> json) {
    return UserCompleteServiceModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      budget: json['budget']?.toString() ?? '0',
      maxBudget: json['max_budget']?.toString() ?? '0',
      tenure: json['tenure']?.toString() ?? '',
      scheduleDate: json['schedule_date']?.toString(),
      scheduleTime: json['schedule_time']?.toString(),
      serviceType: json['service_type']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      serviceMode: json['service_mode']?.toString() ?? '',
      durationValue: json['duration_value'] ?? 0,
      durationUnit: json['duration_unit']?.toString() ?? '',
      serviceDays: json['service_days']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      extraTimeMinutes: json['extra_time_minutes'] ?? 0,
      assignedProviderId: json['assigned_provider_id']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      reason: json['reason']?.toString(),
      startedAt: json['started_at']?.toString(),
      arrivedAt: json['arrived_at']?.toString(),
      endedAt: json['ended_at']?.toString(),
      confirmedAt: json['confirmed_at']?.toString(),
      startOtp: json['start_otp']?.toString() ?? '',
      endOtp: json['end_otp']?.toString() ?? '',
      paymentMethod: json['payment_method']?.toString() ?? '',
      paymentType: json['payment_type']?.toString() ?? '',
      finalAmount: json['final_amount']?.toString(),
      dynamicFields: json['dynamic_fields'] as Map<String, dynamic>?,
      cancelledBy: json['cancelled_by']?.toString(),
      cancelReason: json['cancel_reason']?.toString(),
      cancelledAt: json['cancelled_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      totalBids: json['total_bids']?.toString() ?? '0',
      bids: (json['bids'] as List<dynamic>?)
          ?.map((e) => Bid.fromJson(e as Map<String, dynamic>))
          .toList() ??
          [],
      customer: Customer.fromJson(json['customer'] ?? {}),
      createdAtFormatted: json['created_at_formatted']?.toString() ?? '',
    );
  }
}

class Bid {
  final double amount;
  final int bidId;
  final String createdAt;

  Bid({
    required this.amount,
    required this.bidId,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      amount: (json['amount'] ?? 0).toDouble(),
      bidId: json['bid_id'] ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class Customer {
  final int id;
  final String? firstname;
  final String? lastname;
  final String? username;
  final String? email;
  final String mobile;
  final String? gender;
  final int? age;
  final String? image;
  final bool isregister;
  final bool isProvider;
  final bool isBlocked;
  final String referralCode;
  final double wallet;
  final bool emailVerified;
  final String createdAt;
  final String updatedAt;

  Customer({
    required this.id,
    this.firstname,
    this.lastname,
    this.username,
    this.email,
    required this.mobile,
    this.gender,
    this.age,
    this.image,
    required this.isregister,
    required this.isProvider,
    required this.isBlocked,
    required this.referralCode,
    required this.wallet,
    required this.emailVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      firstname: json['firstname']?.toString(),
      lastname: json['lastname']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      mobile: json['mobile']?.toString() ?? '',
      gender: json['gender']?.toString(),
      age: json['age'],
      image: json['image']?.toString(),
      isregister: json['isregister'] ?? false,
      isProvider: json['is_provider'] ?? false,
      isBlocked: json['is_blocked'] ?? false,
      referralCode: json['referral_code']?.toString() ?? '',
      wallet: (json['wallet'] ?? 0).toDouble(),
      emailVerified: json['email_verified'] ?? false,
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }
}