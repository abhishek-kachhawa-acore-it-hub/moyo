class ProviderBidModel {
  final String id;
  final String title;
  final String category;
  final String service;
  final String description;
  final String userId;
  final double budget;
  final double maxBudget;
  final String tenure;
  final DateTime? scheduleDate; // ✅ CHANGED: Made nullable
  final String? scheduleTime; // ✅ CHANGED: Made nullable
  final String serviceType;
  final String location;
  final double latitude;
  final double longitude;
  final String serviceMode;
  final int? durationValue; // ✅ CHANGED: Made nullable
  final String? durationUnit; // ✅ CHANGED: Already nullable, kept as is
  final int? serviceDays; // ✅ CHANGED: Changed from String? to int?
  final DateTime? startDate;
  final DateTime? endDate;
  final int extraTimeMinutes;
  final String? assignedProviderId;
  final String status;
  final String? reason;
  final DateTime? startedAt;
  final DateTime? arrivedAt;
  final DateTime? endedAt;
  final DateTime? confirmedAt;
  final String? startOtp;
  final String? endOtp;
  final String paymentMethod;
  final String paymentType;
  final double? finalAmount;
  final Map<String, dynamic>? dynamicFields;
  final String? cancelledBy;
  final String? cancelReason;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime receivedAt;

  // ✅ NEW: Additional fields from API response
  final String? providerId; // ✅ NEW: Provider ID receiving this bid
  final double? distanceKm; // ✅ NEW: Distance in kilometers
  final int? timer; // ✅ NEW: Timer/expiration timestamp

  ProviderBidModel({
    required this.id,
    required this.title,
    required this.category,
    required this.service,
    required this.description,
    required this.userId,
    required this.budget,
    required this.maxBudget,
    required this.tenure,
    this.scheduleDate, // ✅ CHANGED: Now nullable
    this.scheduleTime, // ✅ CHANGED: Now nullable
    required this.serviceType,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.serviceMode,
    this.durationValue, // ✅ CHANGED: Now nullable
    this.durationUnit,
    this.serviceDays, // ✅ CHANGED: Now int? instead of String?
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
    DateTime? receivedAt,
    this.providerId, // ✅ NEW
    this.distanceKm, // ✅ NEW
    this.timer, // ✅ NEW
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory ProviderBidModel.fromJson(Map<String, dynamic> json) {
    // Handle nested service object
    final service = json['service'] ?? json;

    return ProviderBidModel(
      id: service['id']?.toString() ?? '0',
      title: service['title'] ?? 'Unknown Service',
      category: service['category'] ?? 'General',
      service: service['service'] ?? 'Service',
      description: service['description'] ?? '',
      userId: service['user_id']?.toString() ?? '0',
      budget: double.tryParse(service['budget']?.toString() ?? '0') ?? 0.0,
      maxBudget: double.tryParse(service['max_budget']?.toString() ?? '0') ?? 0.0,
      tenure: service['tenure'] ?? 'one_time',
      scheduleDate: service['schedule_date'] != null ? _parseDateTime(service['schedule_date']) : null, // ✅ CHANGED: Handle null
      scheduleTime: service['schedule_time'], // ✅ CHANGED: Already nullable
      serviceType: service['service_type'] ?? 'instant',
      location: service['location'] ?? 'Unknown Location',
      latitude: double.tryParse(service['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(service['longitude']?.toString() ?? '0') ?? 0.0,
      serviceMode: service['service_mode'] ?? 'hrs',
      durationValue: service['duration_value'] != null ? int.tryParse(service['duration_value'].toString()) : null, // ✅ CHANGED: Handle null
      durationUnit: service['duration_unit'],
      serviceDays: service['service_days'] != null ? int.tryParse(service['service_days'].toString()) : null, // ✅ CHANGED: Parse as int
      startDate: service['start_date'] != null ? _parseDateTime(service['start_date']) : null,
      endDate: service['end_date'] != null ? _parseDateTime(service['end_date']) : null,
      extraTimeMinutes: int.tryParse(service['extra_time_minutes']?.toString() ?? '0') ?? 0,
      assignedProviderId: service['assigned_provider_id']?.toString(),
      status: service['status'] ?? 'open',
      reason: service['reason'],
      startedAt: service['started_at'] != null ? _parseDateTime(service['started_at']) : null,
      arrivedAt: service['arrived_at'] != null ? _parseDateTime(service['arrived_at']) : null,
      endedAt: service['ended_at'] != null ? _parseDateTime(service['ended_at']) : null,
      confirmedAt: service['confirmed_at'] != null ? _parseDateTime(service['confirmed_at']) : null,
      startOtp: service['start_otp'],
      endOtp: service['end_otp'],
      paymentMethod: service['payment_method'] ?? 'prepaid',
      paymentType: service['payment_type'] ?? 'online',
      finalAmount: service['final_amount'] != null
          ? double.tryParse(service['final_amount'].toString())
          : null,
      dynamicFields: service['dynamic_fields'] is Map
          ? Map<String, dynamic>.from(service['dynamic_fields'])
          : null,
      cancelledBy: service['cancelled_by'],
      cancelReason: service['cancel_reason'],
      cancelledAt: service['cancelled_at'] != null ? _parseDateTime(service['cancelled_at']) : null,
      createdAt: _parseDateTime(service['created_at']),
      updatedAt: _parseDateTime(service['updated_at']),
      receivedAt: DateTime.now(),
      // ✅ NEW: Parse additional fields from root level of JSON
      providerId: json['provider_id']?.toString(),
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      timer: json['timer'] != null ? int.tryParse(json['timer'].toString()) : null,
    );
  }

  ProviderBidModel copyWith({
    String? id,
    String? title,
    String? category,
    String? service,
    String? description,
    String? userId,
    double? budget,
    double? maxBudget,
    String? tenure,
    DateTime? scheduleDate,
    String? scheduleTime,
    String? serviceType,
    String? location,
    double? latitude,
    double? longitude,
    String? serviceMode,
    int? durationValue,
    String? durationUnit,
    int? serviceDays, // ✅ CHANGED: Now int?
    DateTime? startDate,
    DateTime? endDate,
    int? extraTimeMinutes,
    String? assignedProviderId,
    String? status,
    String? reason,
    DateTime? startedAt,
    DateTime? arrivedAt,
    DateTime? endedAt,
    DateTime? confirmedAt,
    String? startOtp,
    String? endOtp,
    String? paymentMethod,
    String? paymentType,
    double? finalAmount,
    Map<String, dynamic>? dynamicFields,
    String? cancelledBy,
    String? cancelReason,
    DateTime? cancelledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? receivedAt,
    String? providerId, // ✅ NEW
    double? distanceKm, // ✅ NEW
    int? timer, // ✅ NEW
  }) {
    return ProviderBidModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      service: service ?? this.service,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      budget: budget ?? this.budget,
      maxBudget: maxBudget ?? this.maxBudget,
      tenure: tenure ?? this.tenure,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      scheduleTime: scheduleTime ?? this.scheduleTime,
      serviceType: serviceType ?? this.serviceType,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      serviceMode: serviceMode ?? this.serviceMode,
      durationValue: durationValue ?? this.durationValue,
      durationUnit: durationUnit ?? this.durationUnit,
      serviceDays: serviceDays ?? this.serviceDays,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      extraTimeMinutes: extraTimeMinutes ?? this.extraTimeMinutes,
      assignedProviderId: assignedProviderId ?? this.assignedProviderId,
      status: status ?? this.status,
      reason: reason ?? this.reason,
      startedAt: startedAt ?? this.startedAt,
      arrivedAt: arrivedAt ?? this.arrivedAt,
      endedAt: endedAt ?? this.endedAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      startOtp: startOtp ?? this.startOtp,
      endOtp: endOtp ?? this.endOtp,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentType: paymentType ?? this.paymentType,
      finalAmount: finalAmount ?? this.finalAmount,
      dynamicFields: dynamicFields ?? this.dynamicFields,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelReason: cancelReason ?? this.cancelReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receivedAt: receivedAt ?? this.receivedAt,
      providerId: providerId ?? this.providerId, // ✅ NEW
      distanceKm: distanceKm ?? this.distanceKm, // ✅ NEW
      timer: timer ?? this.timer, // ✅ NEW
    );
  }

  static DateTime _parseDateTime(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  String get formattedBudget => '₹${budget.toStringAsFixed(2)}';
  String get formattedMaxBudget => '₹${maxBudget.toStringAsFixed(2)}';

  String get durationDisplay {
    if (durationValue == null || durationValue == 0) return 'N/A';
    return '$durationValue ${durationUnit ?? 'unit'}${durationValue! > 1 ? 's' : ''}';
  }

  // ✅ NEW: Getter for formatted distance
  String get formattedDistance {
    if (distanceKm == null) return 'N/A';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} meters';
    }
    return '${distanceKm!.toStringAsFixed(2)} km';
  }

  // ✅ NEW: Getter for service days display
  String get serviceDaysDisplay {
    if (serviceDays == null) return 'N/A';
    return '$serviceDays day${serviceDays! > 1 ? 's' : ''}';
  }

  String get dynamicFieldsDisplay {
    if (dynamicFields == null || dynamicFields!.isEmpty) return '';
    return dynamicFields!.entries
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'service': service,
      'description': description,
      'user_id': userId,
      'budget': budget,
      'max_budget': maxBudget,
      'tenure': tenure,
      'schedule_date': scheduleDate?.toIso8601String(),
      'schedule_time': scheduleTime,
      'service_type': serviceType,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'service_mode': serviceMode,
      'duration_value': durationValue,
      'duration_unit': durationUnit,
      'service_days': serviceDays, // ✅ CHANGED: Now int instead of String
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'extra_time_minutes': extraTimeMinutes,
      'assigned_provider_id': assignedProviderId,
      'status': status,
      'payment_method': paymentMethod,
      'payment_type': paymentType,
      'final_amount': finalAmount,
      'dynamic_fields': dynamicFields,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'received_at': receivedAt.toIso8601String(),
      // ✅ NEW: Include new fields in JSON output
      'provider_id': providerId,
      'distance_km': distanceKm,
      'timer': timer,
    };
  }
}