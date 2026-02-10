import 'dart:convert';
// import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';
import 'package:first_flutter/baseControllers/APis.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../NATS Service/NatsService.dart';
import '../../SubCategory/SubcategoryResponse.dart';
import 'package:collection/collection.dart';

class SubcategoryService {
  static const String baseUrl = 'https://api.moyointernational.com/api';

  Future<SubcategoryResponse?> fetchSubcategories(int categoryId) async {
    print(categoryId);
    try {
      debugPrint("Service Id: $categoryId");
      final response = await http.get(
        Uri.parse('$baseUrl/user/moiz/$categoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(categoryId);
      print(response.body);
      debugPrint('Fetch Subcategories Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return SubcategoryResponse.fromJson(jsonData);
      } else {
        debugPrint(
          'Failed to load subcategories. Status code: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching subcategories: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchformula(int subCategoryId) async {
    print(subCategoryId);
    try {
      debugPrint("Service Id: $subCategoryId");
      final response = await http.get(
        Uri.parse('$base_url/api/admin/pricing-formula/$subCategoryId'),
        headers: {'Content-Type': 'application/json'},
      );

      print(response.body);
      debugPrint('Fetch formula Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        debugPrint(
          'Failed to load formula. Status code: ${response.statusCode}',
        );
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching formula: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchDiscountForFormula(
    int subCategoryId,
  ) async {
    print(subCategoryId);
    try {
      debugPrint("Service Id: $subCategoryId");
      final response = await http.get(
        Uri.parse(
          '$base_url/api/admin/subcategory-discount-slab/$subCategoryId',
        ),
        headers: {'Content-Type': 'application/json'},
      );

      print(response.body);
      debugPrint('Fetch subcategory-discount-slab Response: ${response.body}');
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData;
      } else {
        debugPrint(
          'Failed to load subcategory-discount-slab. Status code: ${response.statusCode}',
        );
        return {};
      }
    } catch (e) {
      debugPrint('Error fetching subcategory-discount-slab: $e');
      return {};
    }
  }

  Future<Map<String, dynamic>?> createService(
    Map<String, dynamic> serviceData, {
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$base_url/bid/api/service/create-service'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(serviceData),
      );

      debugPrint('Create Service Response: ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        return jsonData as Map<String, dynamic>;
      } else {
        debugPrint('Choose required Fields');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating service: $e');
      return null;
    }
  }
}

class UserInstantServiceProvider with ChangeNotifier {
  final SubcategoryService _service = SubcategoryService();
  final NatsService _natsService = NatsService();

  SubcategoryResponse? _subcategoryResponse;
  Subcategory? _selectedSubcategory;
  bool _isLoading = false;
  bool _isCreatingService = false;
  String? _error;

  // service mode ko non-null rakho
  String _selectedServiceMode = 'hrs';

  // form values
  final Map<String, dynamic> _formValues = {
    'duration_unit': 'hour',
    'tenure': 'one_time',
  };

  // Location data
  double? _latitude;
  double? _longitude;
  String? _location;

  // Schedule data
  DateTime? _startDate;
  DateTime? _endDate;
  int? _serviceDays;
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;

  Map<String, dynamic>? _formulaData; // pricing formula response
  Map<String, dynamic>? _discountData; // discount slabs response
  double? _calculatedBasePrice; // final calculated base after formula
  double _discountFactor = 1.0; // default 1.0

  // Getters
  Map<String, dynamic>? get formulaData => _formulaData;
  Map<String, dynamic>? get discountData => _discountData;
  double? get calculatedBasePrice => _calculatedBasePrice;
  double get discountFactor => _discountFactor;

  // map controller
  GoogleMapController? _mapController;

  // Getters
  SubcategoryResponse? get subcategoryResponse => _subcategoryResponse;

  Subcategory? get selectedSubcategory => _selectedSubcategory;

  bool get isLoading => _isLoading;

  bool get isCreatingService => _isCreatingService;

  String? get error => _error;

  String get selectedServiceMode => _selectedServiceMode;

  Map<String, dynamic> get formValues => _formValues;

  double? get latitude => _latitude;

  double? get longitude => _longitude;

  String? get location => _location;

  DateTime? get startDate => _startDate;

  DateTime? get endDate => _endDate;

  int? get serviceDays => _serviceDays;

  DateTime? get scheduleDate => _scheduleDate;

  TimeOfDay? get scheduleTime => _scheduleTime;

  GoogleMapController? get mapController => _mapController;

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  // ---------- Pricing / Budget ----------

  double? calculateBaseAmount() {
    if (_selectedSubcategory == null) return null;

    int quantity = 1;
    for (var field in _selectedSubcategory!.fields) {
      if (field.isCalculate) {
        final value = _formValues[field.fieldName];
        if (value != null) {
          quantity = int.tryParse(value.toString()) ?? 1;
        }
        break;
      }
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    if (billingType == 'time') {
      if (_selectedServiceMode == 'hrs') {
        final durationValue =
            int.tryParse(_formValues['duration_value']?.toString() ?? '1') ?? 1;
        final hourlyRate =
            double.tryParse(_selectedSubcategory!.hourlyRate) ?? 0.0;
        return quantity * durationValue * hourlyRate;
      } else {
        final dailyRate =
            double.tryParse(_selectedSubcategory!.dailyRate) ?? 0.0;
        return quantity * (_serviceDays ?? 1) * dailyRate;
      }
    } else if (billingType == 'project') {
      final hourlyRate =
          double.tryParse(_selectedSubcategory!.hourlyRate) ?? 0.0;
      return quantity * hourlyRate;
    }

    return null;
  }

  // Map<String, double>? getBudgetRange() {
  //   final baseAmount = calculateBaseAmount();
  //   if (baseAmount == null) return null;

  //   return {
  //     'min': baseAmount * 0.7,
  //     'max': baseAmount * 2.0,
  //     'base': baseAmount,
  //   };
  // }
  Map<String, double>? getBudgetRange() {
    final base = _calculatedBasePrice ?? calculateBaseAmount();
    if (base == null || base <= 0) return null;

    return {'min': base * 0.7, 'max': base * 1.8, 'base': base};
  }

  // String? validateBudget(String? budgetStr) {
  //   if (budgetStr == null || budgetStr.isEmpty) {
  //     return 'Please enter your budget';
  //   }

  //   final budget = double.tryParse(budgetStr);
  //   if (budget == null) {
  //     return 'Please enter a valid amount';
  //   }

  //   final paymentMethod = _formValues['payment_method'];
  //   if (paymentMethod == 'cash' && budget > 2000) {
  //     return 'Cash payment is limited to ₹2000';
  //   }

  //   final range = getBudgetRange();
  //   if (range != null) {
  //     if (budget < range['min']!) {
  //       return 'Minimum budget should be ₹${range['min']!.toStringAsFixed(0)} (30% down from base rate)';
  //     }
  //     if (budget > range['max']!) {
  //       return 'Maximum budget should be ₹${range['max']!.toStringAsFixed(0)} (100% up from base rate)';
  //     }
  //   }

  //   return null;
  // }

  String? validateBudget(String? budgetStr) {
    if (budgetStr == null || budgetStr.isEmpty) {
      return 'Please enter your budget';
    }

    final budget = double.tryParse(budgetStr);
    if (budget == null) {
      return 'Please enter a valid amount';
    }

    // Cash limit check
    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == 'cash' && budget > 2000) {
      return 'Cash payment is limited to ₹2000';
    }

    // NAYA: Dynamic calculated base price use karo
    final baseAmount =
        _calculatedBasePrice ??
        calculateBaseAmount(); // fallback rakha hai safety ke liye

    if (baseAmount != null && baseAmount > 0) {
      final minBudget = baseAmount * 0.7; // 70% of calculated base
      final maxBudget = baseAmount * 1.8; // ya 2.0 — tum decide karo

      if (budget < minBudget) {
        return 'Minimum budget should be ₹${minBudget.toStringAsFixed(0)}';
      }
      if (budget > maxBudget) {
        return 'Maximum budget should be ₹${maxBudget.toStringAsFixed(0)}';
      }
    }

    return null;
  }

  String getBudgetHint() {
    final range = getBudgetRange();
    if (range != null) {
      return 'Budget range: ₹${range['min']!.toStringAsFixed(0)} - ₹${range['max']!.toStringAsFixed(0)} (Base: ₹${range['base']!.toStringAsFixed(0)})';
    }

    if (_selectedSubcategory != null) {
      return 'Minimum Service Price is ₹${_selectedSubcategory!.hourlyRate}';
    }

    return 'Enter your budget';
  }

  // ---------- Location ----------

  Future<void> getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _error = 'Location permission denied';
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _error = 'Location permissions are permanently denied';
        notifyListeners();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await updateLocationFromMap(position.latitude, position.longitude);

      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            15,
          ),
        );
      }
    } catch (e) {
      _error = 'Error getting location: $e';
      debugPrint('Error getting current location: $e');
      notifyListeners();
    }
  }

  Future<void> updateLocationFromMap(double lat, double lon) async {
    try {
      _latitude = lat;
      _longitude = lon;

      final placemarks = await placemarkFromCoordinates(lat, lon);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        _location =
            '${place.street}, ${place.locality}, ${place.administrativeArea}';
      } else {
        _location =
            'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error getting address: $e');
      _location =
          'Lat: ${lat.toStringAsFixed(4)}, Lon: ${lon.toStringAsFixed(4)}';
      notifyListeners();
    }
  }

  void setLocation(double lat, double lon, String loc) {
    _latitude = lat;
    _longitude = lon;
    _location = loc;
    notifyListeners();
  }

  // 1. fetchSubcategories mein subcategoryId use karo (categoryId galat hai)
  Future<void> fetchSubcategories(int categoryId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _service.fetchSubcategories(categoryId);
      if (response != null) {
        _subcategoryResponse = response;
        _error = null;
      } else {
        _error = 'Failed to load subcategories';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSelectedSubcategory(Subcategory? subcategory) {
  _selectedSubcategory = subcategory;
  _formValues.clear();
  _formValues.addAll({'duration_unit': 'hour', 'tenure': 'one_time'});

  if (subcategory != null) {
    // ← Default select field set kar sakte ho (optional but UX ke liye acha)
    final firstCalculateField = subcategory.fields.firstWhereOrNull((f) => f.isCalculate && f.fieldType == 'select');
    if (firstCalculateField != null && firstCalculateField.options?.isNotEmpty == true) {
      _formValues[firstCalculateField.fieldName] = firstCalculateField.options!.first.label;
    }

    _fetchPricingFormulaAndDiscount(subcategory.id);
    recalculateBasePrice();
  }
  notifyListeners();
}

  // 3. setSelectedSubcategoryInitial mein bhi fetch + calculate (initial load ke liye)
  void setSelectedSubcategoryInitial(Subcategory? subcategory) {
    _selectedSubcategory = subcategory;

    _formValues
      ..clear()
      ..addAll({'duration_unit': 'hour', 'tenure': 'one_time'});

    if (subcategory != null) {
      if (subcategory.billingType.toLowerCase() == 'time') {
        _selectedServiceMode = 'hrs';
      }
      _fetchPricingFormulaAndDiscount(subcategory.id);
      recalculateBasePrice(); // ← yahan add karo
    }
    // No notifyListeners here (as per your comment)
  }

  // 4. _fetchPricingFormulaAndDiscount mein null check + recalculate
  Future<void> _fetchPricingFormulaAndDiscount(int? subcategoryId) async {
    if (subcategoryId == null) return;

    try {
      final formulaRes = await _service.fetchformula(subcategoryId);
      final discountRes = await _service.fetchDiscountForFormula(subcategoryId);

      _formulaData = formulaRes;
      _discountData = discountRes;

      // if (_discountData != null && _discountData!['success'] == true) {
      //   final slabs = _discountData!['slabs'] as List<dynamic>? ?? [];
      //   if (slabs.isNotEmpty) {
      //     _discountFactor = 1.0 - (slabs.first['discount_percent'] / 100);
      //   } else {
      //     _discountFactor = 1.0;
      //   }
      // } else {
      //   _discountFactor = 1.0;
      // }

      // Inside _fetchPricingFormulaAndDiscount or wherever you set _discountFactor

      if (_discountData != null && _discountData!['success'] == true) {
        final slabs = _discountData!['slabs'] as List<dynamic>? ?? [];

        if (slabs.isNotEmpty) {
          // ───────────────────────────────────────────────────────
          //  Most important: convert string → double safely
          // ───────────────────────────────────────────────────────
          final firstSlab = slabs.first as Map<String, dynamic>;
          final discountStr = firstSlab['discount_percent']?.toString() ?? '0';

          final discountPercent = double.tryParse(discountStr) ?? 0.0;

          _discountFactor = 1.0 - (discountPercent / 100);
        } else {
          _discountFactor = 1.0;
        }
      } else {
        _discountFactor = 1.0;
      }

      recalculateBasePrice(); // ← yahan bhi call
      notifyListeners();
    } catch (e) {
      debugPrint("Error loading formula/discount: $e");
      _discountFactor = 1.0;
      notifyListeners();
    }
  }

  void _updateDiscountFactorBasedOnDuration() {
    if (_discountData == null || _discountData!['success'] != true) {
      _discountFactor = 1.0;
      return;
    }

    final slabs = _discountData!['slabs'] as List<dynamic>? ?? [];
    if (slabs.isEmpty) {
      _discountFactor = 1.0;
      return;
    }

    // Current duration calculate karo (hours mein normalize)
    double currentDurationHours = 1.0;

    if (_selectedServiceMode == 'hrs') {
      currentDurationHours =
          double.tryParse(_formValues['duration_value']?.toString() ?? '1') ??
          1.0;
    } else if (_selectedServiceMode == 'day') {
      final days = _serviceDays ?? 1;
      currentDurationHours = days * 24.0; // ← 1 day = 24 hours assumption
      // Agar daily rate different logic use karta hai toh yeh adjust karna padega
    }

    double highestDiscountPercent = 0.0;

    for (final slabRaw in slabs) {
      final slab = slabRaw as Map<String, dynamic>;

      final minStr = slab['min_duration']?.toString() ?? '0';
      final maxStr = slab['max_duration']?.toString() ?? '999999';
      final discStr = slab['discount_percent']?.toString() ?? '0';

      final min = double.tryParse(minStr) ?? 0.0;
      final max = double.tryParse(maxStr) ?? 999999.0;
      final percent = double.tryParse(discStr) ?? 0.0;

      if (currentDurationHours >= min && currentDurationHours <= max) {
        if (percent > highestDiscountPercent) {
          highestDiscountPercent = percent;
        }
      }
    }

    _discountFactor = 1.0 - (highestDiscountPercent / 100.0);

    debugPrint(
      "Duration: ${currentDurationHours}h → Discount: ${highestDiscountPercent}% → Factor: $_discountFactor",
    );
  }

  // void recalculateBasePrice() {
  //   if (_selectedSubcategory == null) {
  //     _calculatedBasePrice = null;
  //     notifyListeners();
  //     return;
  //   }

  //   // Formula nahi hai ya success nahi → simple fallback
  //   if (_formulaData == null || _formulaData!['success'] != true) {
  //     _calculatedBasePrice = _simpleFallback();
  //     notifyListeners();
  //     return;
  //   }

  //   final formulaObj = _formulaData!;
  //   final formulaString =
  //       (formulaObj['data']['formula'] as String?)?.trim() ?? "";
  //   final requiredInputs = List<String>.from(
  //     formulaObj['data']['required_inputs'] ?? [],
  //   );

  //   if (formulaString.isEmpty) {
  //     _calculatedBasePrice = _simpleFallback();
  //     notifyListeners();
  //     return;
  //   }

  //   // ─── 1. Calculate field dhoondho ───────────────────────────────
  //   final calcField = _selectedSubcategory!.fields.firstWhereOrNull(
  //     (f) => f.isCalculate == true,
  //   );

  //   double basePrice = 0.0;
  //   double hourlyRate =
  //       double.tryParse(_selectedSubcategory!.hourlyRate ?? '0') ?? 0.0;

  //   if (calcField != null &&
  //       calcField.fieldType == 'select' &&
  //       calcField.options != null) {
  //     final selectedLabel = _formValues[calcField.fieldName] as String?;
  //     if (selectedLabel != null) {
  //       final opt = calcField.options!.firstWhereOrNull(
  //         (o) => o.label == selectedLabel,
  //       );
  //       if (opt != null) {
  //         basePrice = (opt.basePrice ?? opt.hourlyPrice ?? 0).toDouble();
  //         if (basePrice > 0) {
  //           hourlyRate = basePrice; // override hourly rate if base price found
  //         }
  //       }
  //     }
  //   }

  //   // Agar basePrice abhi bhi 0 → subcategory ka hourly rate
  //   if (basePrice <= 0) {
  //     basePrice = hourlyRate;
  //   }

  //   // ─── 2. Duration nikaalo ───────────────────────────────────────
  //   double durationHours = 1.0;
  //   if (_selectedServiceMode == 'hrs') {
  //     durationHours =
  //         double.tryParse(_formValues['duration_value']?.toString() ?? '1') ??
  //         1.0;
  //   } else if (_selectedServiceMode == 'day') {
  //     durationHours =
  //         (_serviceDays ?? 1).toDouble() *
  //         24.0; // adjust if daily logic different
  //   }

  //   // ─── 3. Gross amount (formula ke hisaab se) ───────────────────
  //   double grossAmount = basePrice + (hourlyRate * durationHours);

  //   // ─── 4. Discount apply (jo already update ho chuka hai) ────────
  //   double finalAmount = grossAmount * _discountFactor;

  //   _calculatedBasePrice = finalAmount.isFinite && finalAmount > 0
  //       ? finalAmount
  //       : null;

  //   debugPrint('''
  // Price Breakdown:
  // • Base: ₹${basePrice.toStringAsFixed(1)}
  // • Hourly Rate used: ₹${hourlyRate.toStringAsFixed(1)}
  // • Duration: ${durationHours.toStringAsFixed(1)} hrs
  // • Gross: ₹${grossAmount.toStringAsFixed(1)}
  // • Discount factor: ${_discountFactor.toStringAsFixed(3)}
  // • Final suggested: ₹${_calculatedBasePrice?.toStringAsFixed(0) ?? '—'}
  // ''');

  //   notifyListeners();
  // }

  double _evaluateSimpleMath(String expr) {
    // Agar brackets hain to recursively handle kar sakte ho, lekin abhi simple assume
    // production mein math_expressions package use karo (pub.dev)

    // Temporary: sirf + aur * wale cases handle kar rahe hain jo logs mein dikhe
    if (expr.contains('+')) {
      var parts = expr.split('+');
      double sum = 0;
      for (var p in parts) {
        sum += _parseTerm(p);
      }
      return sum;
    } else if (expr.contains('*')) {
      var parts = expr.split('*');
      double prod = 1;
      for (var p in parts) {
        prod *= _parseTerm(p);
      }
      return prod;
    }

    return _parseTerm(expr);
  }

  double _parseTerm(String term) {
    // number ya already replaced value
    return double.tryParse(term) ?? 0.0;
  }

  double? _simpleFallbackPrice() {
    if (_selectedSubcategory == null) return null;

    double rate = _selectedServiceMode == 'hrs'
        ? double.tryParse(_selectedSubcategory!.hourlyRate ?? '0') ?? 0.0
        : double.tryParse(_selectedSubcategory!.dailyRate ?? '0') ?? 0.0;

    double multiplier = _selectedServiceMode == 'hrs'
        ? double.tryParse(_formValues['duration_value']?.toString() ?? '1') ??
              1.0
        : (_serviceDays ?? 1).toDouble();

    return (rate * multiplier * _discountFactor).roundToDouble();
  }

  // double _getDurationInHours() {
  //   if (_selectedServiceMode == 'hrs') {
  //     return double.tryParse(
  //           _formValues['duration_value']?.toString() ?? '1',
  //         ) ??
  //         1.0;
  //   } else {
  //     // Daily mode → aap decide karo 8 ya 24
  //     // Abhi 8 working hours assume kar rahe hain (common in service apps)
  //     return (_serviceDays ?? 1).toDouble() * 8.0;
  //   }
  // }

  double? _getBasePrice() {
    final calcField = _selectedSubcategory!.fields.firstWhereOrNull(
      (f) => f.isCalculate == true && f.fieldType == 'select',
    );

    if (calcField == null) return null;

    final selected = _formValues[calcField.fieldName] as String?;
    if (selected == null) return null;

    final opt = calcField.options?.firstWhereOrNull((o) => o.label == selected);
    if (opt == null) return null;

    return (opt.basePrice ?? opt.hourlyPrice ?? 0).toDouble();
  }

//   void recalculateBasePrice() {
//     if (_selectedSubcategory == null) {
//       _calculatedBasePrice = null;
//       notifyListeners();
//       return;
//     }

//     // ─── 1. Formula aur required inputs nikaalo ────────────────────────────────
//     if (_formulaData == null || _formulaData!['success'] != true) {
//       _calculatedBasePrice = _simpleFallbackPrice();
//       notifyListeners();
//       return;
//     }

//     final formulaObj = _formulaData!;
//     String formula = (formulaObj['data']['formula'] as String?)?.trim() ?? "";

//     if (formula.isEmpty) {
//       _calculatedBasePrice = _simpleFallbackPrice();
//       notifyListeners();
//       return;
//     }

//     // Discount factor alag se nahi multiply karna — formula mein already * discount_factor likha hota hai
//     // isliye hum formula ko as-is evaluate karenge

//     // ─── 2. Variables ka map banao jo formula mein replace honge ───────────────
//     Map<String, double> variables = {
//       'base_price': _getBasePrice() ?? 0.0,
//       'hourly_rate':
//           double.tryParse(_selectedSubcategory!.hourlyRate ?? '0') ?? 0.0,
//       'duration': _getDurationInHours(),
//       'discount_factor': _discountFactor,
//     };

//     // Dynamic fields from form + subcategory fields
//     for (var field in _selectedSubcategory!.fields) {
//       final value = _formValues[field.fieldName];
//       if (value != null) {
//         // number field ya select ka base_price/hourly_price
//         if (field.fieldType == 'number') {
//           variables[field.fieldName] = double.tryParse(value.toString()) ?? 0.0;
//         } else if (field.fieldType == 'select' && field.options != null) {
//           final selectedLabel = value.toString();
//           final opt = field.options!.firstWhereOrNull(
//             (o) => o.label == selectedLabel,
//           );
//           if (opt != null) {
//             // formula mein base_price ya hourly_price use ho sakta hai
//             // lekin yahan field name se value daal rahe hain
//             variables[field.fieldName] = (opt.basePrice ?? opt.hourlyPrice ?? 0)
//                 .toDouble();
//           }
//         }
//       }
//     }

//     // ─── 3. Formula mein variables replace karo ────────────────────────────────
//     String expression = formula;

//     // Keywords ko replace karo (case insensitive banana better hai)
//     for (var entry in variables.entries) {
//       final key = entry.key;
//       final val = entry.value;
//       // simple replace (production mein better parser use kar sakte ho)
//       expression = expression.replaceAll(key, val.toStringAsFixed(6));
//     }

//     // discount_factor ko last mein replace (safety)
//     expression = expression.replaceAll(
//       'discount_factor',
//       _discountFactor.toStringAsFixed(6),
//     );

//     // Extra spaces hatao
//     expression = expression.replaceAll(RegExp(r'\s+'), '');

//     // ─── 4. Expression ko evaluate karo (safe math parser) ──────────────────────
//     try {
//       // Very basic evaluator — production ke liye package use karo (math_expressions ya expressions)
//       // yahan simple logic daal rahe hain jo common cases handle karega

//       // Pehle brackets handle (bahut basic)
//       double result = _evaluateSimpleMath(expression);

//       _calculatedBasePrice = result.isFinite && result > 0
//           ? result.roundToDouble()
//           : null;

//       debugPrint('''
// Calculated Price Breakdown:
// Formula: $formula
// After replace: $expression
// Result: ${_calculatedBasePrice?.toStringAsFixed(0) ?? "—"}
// Variables used: $variables
// ''');
//     } catch (e, stack) {
//       debugPrint("Formula evaluation failed: $e\n$stack");
//       _calculatedBasePrice = _simpleFallbackPrice();
//     }

//     notifyListeners();
//   }



// void recalculateBasePrice() {
//   if (_selectedSubcategory == null) {
//     _calculatedBasePrice = null;
//     notifyListeners();
//     return;
//   }

//   // Formula nahi hai → simple fallback
//   if (_formulaData == null || _formulaData!['success'] != true) {
//     _calculatedBasePrice = _simpleFallback();
//     notifyListeners();
//     return;
//   }

//   String formula = (_formulaData!['data']['formula'] as String?)?.trim() ?? "";
//   if (formula.isEmpty) {
//     _calculatedBasePrice = _simpleFallback();
//     notifyListeners();
//     return;
//   }

//   // ─── 1. Important variables collect karo ────────────────────────────────
//   Map<String, double> variables = {
//     'discount_factor': _discountFactor,
//     'duration': _getDurationInHours(),
//   };

//   // ─── 2. Calculate fields se base_price aur hourly_rate nikaalo ───────────
//   double finalBasePrice = 0.0;
//   double finalHourlyRate = double.tryParse(_selectedSubcategory!.hourlyRate ?? '0') ?? 0.0;

//   // Sab calculate fields check karo (multiple bhi ho sakte hain)
//   for (var field in _selectedSubcategory!.fields.where((f) => f.isCalculate == true)) {
//     final rawValue = _formValues[field.fieldName];
//     if (rawValue == null) continue;

//     final valueStr = rawValue.toString();

//     if (field.fieldType == 'select' && field.options != null) {
//       final option = field.options!.firstWhereOrNull((o) => o.label == valueStr);
//       if (option != null) {
//         // Breed select hone par hourly_price priority
//         if (option.hourlyPrice != null && option.hourlyPrice! > 0) {
//           finalHourlyRate = option.hourlyPrice!.toDouble();
//         }
//         // base_price bhi update kar sakte ho agar formula mein use ho
//         if (option.basePrice != null && option.basePrice! > 0) {
//           finalBasePrice = option.basePrice!.toDouble();
//         }

//         // Field name ko bhi variable mein daal do (jaise "Dog Breeds": 90.0)
//         variables[field.fieldName] = finalHourlyRate;
//       }
//     } 
//     else if (field.fieldType == 'number') {
//       final numValue = double.tryParse(valueStr) ?? 0.0;
//       variables[field.fieldName] = numValue;  // "No. of Dog": 3.0
//     }
//   }

//   // Agar koi breed select hua → finalHourlyRate update ho chuka hoga
//   // Fallback subcategory ka hourly rate
//   variables['hourly_rate'] = finalHourlyRate;
//   variables['base_price'] = finalBasePrice > 0 ? finalBasePrice : variables['hourly_rate']!;

//   // ─── 3. Formula string mein replace karo ────────────────────────────────
//   String expression = formula;

//   // Sab variables replace (exact match + space ignore version)
//   variables.forEach((key, value) {
//     // Original key (spaces ke saath)
//     expression = expression.replaceAll(key, value.toStringAsFixed(4));
    
//     // Space remove karke bhi try (safety ke liye)
//     String keyNoSpace = key.replaceAll(RegExp(r'\s+'), '');
//     expression = expression.replaceAll(keyNoSpace, value.toStringAsFixed(4));
//   });


//   expression = expression.replaceAll(RegExp(r'\s+'), ''); // clean spaces

//   // ─── 4. Evaluate expression (simple parser for now) ──────────────────────
//   try {
//     double result = _evaluateSimpleExpression(expression);

//     _calculatedBasePrice = result.isFinite && result > 0 ? result.roundToDouble() : null;

//     debugPrint('''
//     ────────────────────────────────
//     Formula: $formula
//     After replace: $expression
//     Variables: $variables
//     Final Price: ${_calculatedBasePrice?.toStringAsFixed(0) ?? '—'}
//     ────────────────────────────────
//     ''');
//   } catch (e, stack) {
//     debugPrint("Formula evaluation failed: $e\nExpression: $expression\n$stack");
//     _calculatedBasePrice = _simpleFallback();
//   }

//   notifyListeners();
// }




void recalculateBasePrice() {
  if (_selectedSubcategory == null) {
    _calculatedBasePrice = null;
    notifyListeners();
    return;
  }

  // ── 1. Formula handling (keep your existing formula code) ────────────────
  if (_formulaData != null && _formulaData!['success'] == true) {
    // your existing formula evaluation logic here...
    // If formula exists → use it and return early
    // (assuming you already have working formula path)
  }

  // ── 2. Fallback when no formula or formula fails ─────────────────────────
  Map<String, double> variables = {
    'duration': _getDurationInHours(),
    'discount_factor': _discountFactor,
  };

  double baseFixed = 0.0;           // one-time costs (added once)
  double ratePerHour = double.tryParse(
        _selectedSubcategory!.hourlyRate ?? '0',
      ) ??
      0.0;

  // ── Collect from ALL calculate fields ────────────────────────────────────
  for (var field in _selectedSubcategory!.fields.where((f) => f.isCalculate)) {
    final raw = _formValues[field.fieldName];
    if (raw == null) continue;

    final valStr = raw.toString().trim();

    if (field.fieldType == 'select' && field.options != null) {
      final opt = field.options!.firstWhereOrNull((o) => o.label == valStr);
      if (opt == null) continue;

      // Priority 1: hourly_price → used as rate
      if (opt.hourlyPrice != null && opt.hourlyPrice! > 0) {
        ratePerHour = opt.hourlyPrice!.toDouble();
      }

      // Priority 2: base_price → treated as fixed/additional cost
      if (opt.basePrice != null && opt.basePrice! > 0) {
        baseFixed += opt.basePrice!.toDouble(); // sum if multiple
      }

      // Also store the field value itself (important for formula)
      variables[field.fieldName.trim()] = opt.basePrice?.toDouble() ??
          opt.hourlyPrice?.toDouble() ??
          1.0;
    } 
    else if (field.fieldType == 'number') {
      final numVal = double.tryParse(valStr) ?? 0.0;
      if (numVal > 0) {
        // Most common: number fields are multipliers (people, animals, items...)
        variables[field.fieldName.trim()] = numVal;
      }
    }
  }

  // Final rate fallback
  variables['hourly_rate'] = ratePerHour;
  variables['base_price'] = baseFixed > 0 ? baseFixed : ratePerHour;

  // ── Simple fallback calculation when no formula ──────────────────────────
  double gross = ratePerHour * variables['duration']!;

  // Multiply by quantity-like fields (people, animals, etc.)
  for (var entry in variables.entries) {
    final keyLower = entry.key.toLowerCase();
    if (keyLower.contains('no. ') ||
        keyLower.contains('number') ||
        keyLower.contains('count') ||
        keyLower.contains('people') ||
        keyLower.contains('animal') ||
        keyLower.contains('cat') ||
        keyLower.contains('dog')) {
      if (entry.value > 1) {
        gross *= entry.value;
      }
    }
  }

  // Add fixed base costs
  gross += baseFixed;

  // Apply discount
  final discountPercent = _getHighestDiscountPercent();
  final finalAmount = gross * (1 - discountPercent / 100);

  _calculatedBasePrice = finalAmount.isFinite && finalAmount > 0
      ? finalAmount.roundToDouble()
      : null;

  debugPrint('''
  Fallback calculation:
  • Rate/hour: ₹$ratePerHour
  • Duration: ${variables['duration']} h
  • Quantity multiplier: ${variables.toString()}
  • Fixed base: ₹$baseFixed
  • Gross: ₹${gross.toStringAsFixed(0)}
  • Discount: ${discountPercent.toStringAsFixed(1)}%
  • Final: ₹${_calculatedBasePrice?.toStringAsFixed(0) ?? '—'}
  ''');

  notifyListeners();
}

// New helper: Highest discount percent nikaalne ka clean function
double _getHighestDiscountPercent() {
  if (_discountData == null || _discountData!['success'] != true) {
    return 0.0;
  }

  final slabs = _discountData!['slabs'] as List<dynamic>? ?? [];
  if (slabs.isEmpty) return 0.0;

  double currentHours = _getDurationInHours();

  double highestPercent = 0.0;

  for (var slabRaw in slabs) {
    final slab = slabRaw as Map<String, dynamic>;
    final min = double.tryParse(slab['min_duration']?.toString() ?? '0') ?? 0.0;
    final max = double.tryParse(slab['max_duration']?.toString() ?? '999999') ?? 999999.0;
    final percent = double.tryParse(slab['discount_percent']?.toString() ?? '0') ?? 0.0;

    if (currentHours >= min && currentHours <= max) {
      if (percent > highestPercent) {
        highestPercent = percent;
      }
    }
  }

  debugPrint("Duration: ${currentHours}h → Discount: ${highestPercent}%");

  return highestPercent;
}

// Gross ke liye fallback (discount ke bina)
double? _simpleFallbackWithoutDiscount() {
  double rate = double.tryParse(
        _selectedServiceMode == 'hrs' ? _selectedSubcategory!.hourlyRate : _selectedSubcategory!.dailyRate,
      ) ??
      0.0;

  double multiplier = _selectedServiceMode == 'hrs'
      ? (double.tryParse(_formValues['duration_value']?.toString() ?? '1') ?? 1.0)
      : (_serviceDays ?? 1).toDouble();

  return (rate * multiplier).roundToDouble();
}

// Tumhara _evaluateSimpleExpression same rahega (ya math_expressions package use kar lo)

// Helper: Duration in hours
double _getDurationInHours() {
  if (_selectedServiceMode == 'hrs') {
    return double.tryParse(_formValues['duration_value']?.toString() ?? '1') ?? 1.0;
  }
  // Daily mode → 8 working hours assume (service apps mein common)
  return (_serviceDays ?? 1).toDouble() * 8.0;
}

// Helper: Very basic math evaluator (production mein math_expressions package use karo)
double _evaluateSimpleExpression(String expr) {
  // Remove brackets if any (very basic, improve later)
  expr = expr.replaceAll('(', '').replaceAll(')', '');

  // Split by + first
  if (expr.contains('+')) {
    var parts = expr.split('+');
    double sum = 0.0;
    for (var part in parts) {
      sum += _parseProduct(part);
    }
    return sum;
  }
  return _parseProduct(expr);
}

double _parseProduct(String term) {
  if (term.contains('*')) {
    var factors = term.split('*');
    double prod = 1.0;
    for (var f in factors) {
      prod *= double.tryParse(f.trim()) ?? 0.0;
    }
    return prod;
  }
  return double.tryParse(term.trim()) ?? 0.0;
}

// Fallback jab formula fail ho
double? _simpleFallback() {
  double rate = double.tryParse(
    _selectedServiceMode == 'hrs' ? _selectedSubcategory!.hourlyRate : _selectedSubcategory!.dailyRate,
  ) ?? 0.0;

  double multiplier = _selectedServiceMode == 'hrs'
      ? (double.tryParse(_formValues['duration_value']?.toString() ?? '1') ?? 1.0)
      : (_serviceDays ?? 1).toDouble();

  return (rate * multiplier * _discountFactor).roundToDouble();
}

  // Simple fallback jab formula nahi milti
  // double? _simpleFallback() {
  //   if (_selectedSubcategory == null) return null;

  //   double rate =
  //       double.tryParse(
  //         _selectedServiceMode == 'hrs'
  //             ? _selectedSubcategory!.hourlyRate
  //             : _selectedSubcategory!.dailyRate,
  //       ) ??
  //       0.0;

  //   double multiplier = _selectedServiceMode == 'hrs'
  //       ? double.tryParse(_formValues['duration_value']?.toString() ?? '1') ??
  //             1.0
  //       : (_serviceDays ?? 1).toDouble();

  //   return (rate * multiplier) * _discountFactor;
  // }

  // void updateFormValue(String fieldName, dynamic value) {
  //   _formValues[fieldName] = value;

  //   // Duration related fields change hone par discount + price dono update
  //   if (fieldName == 'duration_value' || fieldName == 'duration_unit') {
  //     _updateDiscountFactorBasedOnDuration();
  //   }

  //   recalculateBasePrice();
  //   notifyListeners();
  // }

//   void updateFormValue(String fieldName, dynamic value) {
//   _formValues[fieldName] = value;

//   // ← Yahaan important line add karo
//   if (_selectedSubcategory != null) {
//     // Koi bhi field jo ispe depend karti hai → unko force update
//     notifyListeners();   // yeh already hai — lekin safe side ke liye
//   }

//   // Duration related special handling
//   if (fieldName == 'duration_value' || fieldName == 'duration_unit') {
//     _updateDiscountFactorBasedOnDuration();
//   }

//   recalculateBasePrice();
//   notifyListeners();   // do baar call karne se koi issue nahi
// }
void updateFormValue(String fieldName, dynamic value) {
  print("→ Updating $fieldName = $value");
  _formValues[fieldName] = value;
  notifyListeners();
  recalculateBasePrice();
}
  void _recalculateBasePrice() {
    if (_selectedSubcategory == null ||
        _formulaData == null ||
        _formulaData!['success'] != true) {
      _calculatedBasePrice = null;
      notifyListeners();
      return;
    }

    try {
      final formulaObj = _formulaData!;
      final formulaString =
          (formulaObj['data']['formula'] as String?)?.trim() ?? "";
      final requiredInputs = List<String>.from(
        formulaObj['data']['required_inputs'] ?? [],
      );

      if (formulaString.isEmpty) {
        _calculatedBasePrice = null;
        notifyListeners();
        return;
      }

      // ──────────────────────────────────────────────────────────────
      // Step 1: Base price find karo (jo field is_calculate: true hai usse)
      // Yeh wala code tumne abhi diya hai — yahin lagao
      // ──────────────────────────────────────────────────────────────
      // final Field? calcField = _selectedSubcategory!.fields.firstWhereOrNull(
      //   (f) => f.isCalculate == true,
      // );
      Field? calcField;
      try {
        calcField = _selectedSubcategory!.fields.firstWhere(
          (f) => f.isCalculate == true,
        );
      } catch (_) {
        calcField = null;
      }

      double basePrice = 0.0;

      if (calcField != null && calcField.fieldType == 'select') {
        final String? selectedLabel =
            _formValues[calcField.fieldName] as String?;

        if (selectedLabel != null) {
          final Option? selectedOpt = calcField.options?.firstWhere(
            (opt) => opt.label == selectedLabel,
          );

          if (selectedOpt != null) {
            basePrice = selectedOpt.basePrice ?? 0.0;
            if (basePrice == 0) {
              basePrice = selectedOpt.hourlyPrice ?? 0.0;
            }
          }
        }
      }

      // Fallback agar koi calculate field nahi mila ya value select nahi ki
      if (basePrice == 0) {
        basePrice =
            double.tryParse(_selectedSubcategory!.hourlyRate ?? '0') ?? 0.0;
      }

      // ──────────────────────────────────────────────────────────────
      // Step 2: Multipliers aur quantities collect karo
      // ──────────────────────────────────────────────────────────────
      double quantityMultiplier = 1.0; // jaise no of pets / no of people
      double durationMultiplier = 1.0; // hours ya days

      for (final input in requiredInputs) {
        final normalized = input.toLowerCase().trim();

        // No of pet / quantity wala input
        if (normalized.contains('no') &&
            (normalized.contains('pet') ||
                normalized.contains('people') ||
                normalized.contains('quantity'))) {
          final val = _formValues.values.firstWhere(
            (v) =>
                v is num ||
                (v is String && double.tryParse(v.toString()) != null),
            orElse: () => '1',
          );
          quantityMultiplier = double.tryParse(val.toString()) ?? 1.0;
        }
        // Duration related input
        else if (normalized.contains('duration')) {
          if (_selectedServiceMode == 'hrs') {
            durationMultiplier =
                double.tryParse(
                  _formValues['duration_value']?.toString() ?? '1',
                ) ??
                1.0;
          } else if (_selectedServiceMode == 'day') {
            durationMultiplier = (_serviceDays ?? 1).toDouble();
          }
        }
        // Agar formula mein aur koi specific input hai (jaise category, meal type), to yahan add kar sakte ho
      }

      // ──────────────────────────────────────────────────────────────
      // Step 3: Final calculation (simple version – base * quantity * duration)
      // ──────────────────────────────────────────────────────────────
      double result = basePrice * quantityMultiplier * durationMultiplier;

      // Step 4: Discount apply karo (jo pehle se calculate hua hai)
      result *= _discountFactor;

      // Final value set karo
      _calculatedBasePrice = result.isFinite && result > 0 ? result : null;
      debugPrint('Calculated base price: $_calculatedBasePrice');
      debugPrint('Selected calc field: ${calcField?.fieldName}');
      // debugPrint('Selected label: $selectedLabel');
      debugPrint('Form values: $_formValues');
    } catch (e, stack) {
      debugPrint("Base price calculation failed: $e");
      debugPrint("Stack: $stack");
      _calculatedBasePrice = null;
    }

    notifyListeners(); // ← UI ko update karne ke liye bahut zaroori
  }

  dynamic getFormValue(String fieldName) => _formValues[fieldName];

  void clearFormValues() {
    _formValues
      ..clear()
      ..addAll({'duration_unit': 'hour', 'tenure': 'one_time'});
    notifyListeners();
  }

  void setServiceMode(String mode) {
    if (_selectedServiceMode != mode) {
      _selectedServiceMode = mode;

      if (mode == 'hrs') {
        _serviceDays = null;
        _startDate = null;
        _endDate = null;
      } else {
        _scheduleDate = null;
        _scheduleTime = null;
      }

      // Mode change → duration reset → discount reset
      _updateDiscountFactorBasedOnDuration();
      recalculateBasePrice();
      notifyListeners();
    }
  }

  void setStartDate(DateTime date) {
    _startDate = DateTime(date.year, date.month, date.day);
    if (_serviceDays != null && _serviceDays! > 0) {
      _endDate = _startDate!.add(Duration(days: _serviceDays!));
    }
    notifyListeners();
  }

  void setScheduleDate(DateTime date) {
    _scheduleDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setEndDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_endDate != normalized) {
      _endDate = normalized;
      notifyListeners();
    }
  }

  void setServiceDays(int days) {
    if (days > 0 && _serviceDays != days) {
      _serviceDays = days;
      if (_startDate != null) {
        _endDate = _startDate!.add(Duration(days: days));
      }
      _updateDiscountFactorBasedOnDuration(); // ← yeh zaroori hai
      recalculateBasePrice();
      notifyListeners();
    }
  }

  void setScheduleTime(TimeOfDay time) {
    if (_scheduleTime != time) {
      _scheduleTime = time;
      notifyListeners();
    }
  }

  // In UserInstantServiceProvider.dart
  bool validateForm({String? serviceType}) {
    if (_selectedSubcategory == null) return false;

    // Sirf visible fields ko check karo
    for (var field in _selectedSubcategory!.fields) {
      bool isVisible = true;
      if (field.dependsOn != null &&
          field.dependsValues != null &&
          field.dependsValues!.isNotEmpty) {
        final parentValue = _formValues[field.dependsOn!]?.toString();
        isVisible = field.dependsValues!.contains(parentValue);
      }

      if (isVisible && field.isRequired) {
        final value = _formValues[field.fieldName];
        if (value == null || value.toString().isEmpty) {
          return false;
        }
      }
    }

    // Baaki checks same rakhna (location, budget, payment etc.)
    if (_latitude == null || _longitude == null || _location == null)
      return false;

    final budget = _formValues['budget'];
    if (validateBudget(budget?.toString()) != null) return false;

    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) return false;

    // time billing checks...
    // ...
    final billingType = _selectedSubcategory!.billingType.toLowerCase();
    if (billingType == 'time') {
      if (_selectedServiceMode.isEmpty) return false;

      if (_selectedServiceMode == 'hrs') {
        final durationValue = _formValues['duration_value'];
        if (durationValue == null || durationValue.toString().isEmpty) {
          return false;
        }

        final durationUnit = _formValues['duration_unit'];
        if (durationUnit == null || durationUnit.toString().isEmpty) {
          return false;
        }

        if (serviceType == 'later') {
          if (_scheduleDate == null || _scheduleTime == null) {
            return false;
          }
        }
      } else if (_selectedServiceMode == 'day') {
        if (_serviceDays == null || _serviceDays! <= 0) return false;
        if (_startDate == null || _endDate == null) return false;
      }

      final tenure = _formValues['tenure'];
      if (tenure == null || tenure.toString().isEmpty) return false;
    }

    return true;
  }

  String? getValidationError({String? serviceType}) {
    // if (_selectedSubcategory == null) return 'No subcategory selected';

    // for (var field in _selectedSubcategory!.fields) {
    //   if (field.isRequired) {
    //     final value = _formValues[field.fieldName];
    //     if (value == null || value.toString().isEmpty) {
    //       return 'Please fill ${field.fieldName}';
    //     }
    //   }
    // }

    if (_selectedSubcategory == null) return 'No subcategory selected';

    for (var field in _selectedSubcategory!.fields) {
      bool isVisible = true;
      if (field.dependsOn != null &&
          field.dependsValues != null &&
          field.dependsValues!.isNotEmpty) {
        final parentValue = _formValues[field.dependsOn!]?.toString();
        isVisible = field.dependsValues!.contains(parentValue);
      }

      if (isVisible && field.isRequired) {
        final value = _formValues[field.fieldName];
        if (value == null || value.toString().isEmpty) {
          return 'Please fill ${field.fieldName}';
        }
      }
    }

    if (_latitude == null || _longitude == null || _location == null) {
      return 'Please select service location';
    }

    final budget = _formValues['budget'];
    final budgetError = validateBudget(budget?.toString());
    if (budgetError != null) {
      return budgetError;
    }

    final paymentMethod = _formValues['payment_method'];
    if (paymentMethod == null || paymentMethod.toString().isEmpty) {
      return 'Please select a payment method';
    }

    final billingType = _selectedSubcategory!.billingType.toLowerCase();

    if (billingType == 'time') {
      if (_selectedServiceMode.isEmpty) {
        return 'Please select service mode (Hourly or Daily)';
      }

      if (_selectedServiceMode == 'hrs') {
        final durationValue = _formValues['duration_value'];
        if (durationValue == null || durationValue.toString().isEmpty) {
          return 'Please enter duration value';
        }

        final durationUnit = _formValues['duration_unit'];
        if (durationUnit == null || durationUnit.toString().isEmpty) {
          return 'Please select duration unit';
        }

        if (serviceType != 'instant') {
          if (_scheduleDate == null) {
            return 'Please select schedule date';
          }
          if (_scheduleTime == null) {
            return 'Please select schedule time';
          }
        }
      } else if (_selectedServiceMode == 'day') {
        if (_serviceDays == null || _serviceDays! <= 0) {
          return 'Please enter number of days';
        }
        if (_startDate == null) {
          return 'Please select start date';
        }
        if (_endDate == null) {
          return 'Please select end date';
        }
      }

      final tenure = _formValues['tenure'];
      if (tenure == null || tenure.toString().isEmpty) {
        return 'Please select tenure';
      }
    }

    return null;
  }

  // ---------- Token ----------

  Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_token');
    } catch (e) {
      debugPrint('Error getting token: $e');
      return null;
    }
  }

  // ---------- Create service ----------
  Future<Map<String, dynamic>> createService({
    required String categoryName,
    required String billingtype,
    required String subcategoryName,
    String? serviceType,
  }) async {
    if (!validateForm(serviceType: serviceType)) {
      _error = getValidationError(serviceType: serviceType);
      notifyListeners();
      return {
        'success': false,
        'serviceId': null,
        'latitude': null,
        'longitude': null,
      };
    }

    _isCreatingService = true;
    _error = null;
    notifyListeners();

    try {
      final dynamicFields = <String, dynamic>{};
      for (var field in _selectedSubcategory!.fields) {
        final value = _formValues[field.fieldName];
        if (value != null && value.toString().isNotEmpty) {
          if (field.fieldType == 'number') {
            dynamicFields[field.fieldName] =
                int.tryParse(value.toString()) ??
                double.tryParse(value.toString()) ??
                value;
          } else {
            dynamicFields[field.fieldName] = value.toString();
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = await getToken();

      if (token == null || token.isEmpty) {
        _error = 'Authentication token not found. Please login again.';
        _isCreatingService = false;
        notifyListeners();
        return {
          'success': false,
          'serviceId': null,
          'latitude': null,
          'longitude': null,
        };
      }

      final double budgetValue =
          double.tryParse(_formValues['budget'].toString()) ?? 0.0;
      final billingTypeNormalized = billingtype.toLowerCase();

      final serviceData = <String, dynamic>{
        "title": "$subcategoryName Service",
        "category": categoryName,
        "description": "Service request for $subcategoryName",
        "service": subcategoryName,
        "budget": budgetValue.toInt(),
        "max_budget": (budgetValue * 1.2).toInt(),
        "service_type": serviceType,
        "payment_method": 'postpaid',
        "payment_type": _formValues['payment_method'] ?? 'online',
        "latitude": _latitude ?? 22.7196,
        "longitude": _longitude ?? 75.8577,
        "location": _location ?? "Indore, Madhya Pradesh",
        "dynamic_fields": dynamicFields,
      };

      if (billingTypeNormalized == 'time') {
        serviceData["tenure"] = _formValues['tenure'] ?? 'one_time';

        if (_selectedServiceMode == 'hrs') {
          final durationValue =
              int.tryParse(_formValues['duration_value'].toString()) ?? 2;

          if (serviceType != 'instant') {
            final scheduleDate =
                '${_scheduleDate!.year}-${_scheduleDate!.month.toString().padLeft(2, '0')}-${_scheduleDate!.day.toString().padLeft(2, '0')}';

            final scheduleTime =
                '${_scheduleTime!.hour.toString().padLeft(2, '0')}:${_scheduleTime!.minute.toString().padLeft(2, '0')}';

            serviceData.addAll({
              "service_mode": "hrs",
              "duration_value": durationValue,
              "duration_unit": _formValues['duration_unit'] ?? 'hour',
              "schedule_date": scheduleDate,
              "schedule_time": scheduleTime,
            });
          } else {
            serviceData.addAll({
              "service_mode": "hrs",
              "duration_value": durationValue,
              "duration_unit": _formValues['duration_unit'] ?? 'hour',
            });
          }
        } else {
          final startDateStr =
              '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}';

          final endDateStr =
              '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}';

          serviceData.addAll({
            "service_mode": "day",
            "service_days": _serviceDays,
            "start_date": startDateStr,
            "end_date": endDateStr,
            "duration_value": null,
            "duration_unit": null,
          });
        }
      } else if (billingTypeNormalized == 'project') {
        serviceData.addAll({
          "service_mode": "task",
          "tenure": "task",
          "duration_value": null,
          "duration_unit": null,
          "service_days": null,
          "start_date": null,
          "end_date": null,
        });
      }

      debugPrint('Service Data: ${json.encode(serviceData)}');

      if (_natsService.isConnected) {
        try {
          final natsRequestPayload = {
            "user_id": userId ?? "unknown",
            "service_data": serviceData,
            "timestamp": DateTime.now().toIso8601String(),
          };

          _natsService.publish(
            'service.create.request',
            json.encode(natsRequestPayload),
          );
          debugPrint('📤 Published service creation request to NATS');
        } catch (e) {
          debugPrint('⚠️ Error publishing to NATS: $e');
        }
      } else {
        debugPrint('⚠️ NATS not connected, skipping publish');
      }

      print('hey abhishek this is serive created $serviceData');

      final response = await _service.createService(serviceData, token: token);
      final isSuccess = response != null && (response['success'] == true);

      if (isSuccess) {
        final serviceIdDynamic = response['service']?['id'];
        final serviceId = serviceIdDynamic != null
            ? serviceIdDynamic.toString()
            : "unknown";

        if (_natsService.isConnected) {
          try {
            final successPayload = {
              "service_id": serviceId,
              "user_id": userId ?? "unknown",
              "timestamp": DateTime.now().toIso8601String(),
            };

            _natsService.publish(
              'service.created.success',
              json.encode(successPayload),
            );
            debugPrint('✅ Published success to NATS');
          } catch (e) {
            debugPrint('⚠️ Error publishing success to NATS: $e');
          }
        }

        _isCreatingService = false;
        notifyListeners();
        return {
          'success': true,
          'serviceId': serviceId,
          'latitude': _latitude ?? 22.7196,
          'longitude': _longitude ?? 75.8577,
        };
      } else {
        _error = response?['message']?.toString() ?? 'Fields Are Required';

        if (_natsService.isConnected) {
          try {
            final failurePayload = {
              "user_id": userId ?? "unknown",
              "error": _error,
              "timestamp": DateTime.now().toIso8601String(),
            };

            _natsService.publish(
              'service.created.failure',
              json.encode(failurePayload),
            );
          } catch (e) {
            debugPrint('⚠️ Error publishing failure to NATS: $e');
          }
        }

        _isCreatingService = false;
        notifyListeners();
        return {
          'success': false,
          'serviceId': null,
          'latitude': null,
          'longitude': null,
        };
      }
    } catch (e) {
      _error = 'An error occurred: $e';
      debugPrint('❌ Error creating service: $e');

      if (_natsService.isConnected) {
        try {
          final errorPayload = {
            "error": e.toString(),
            "timestamp": DateTime.now().toIso8601String(),
          };

          _natsService.publish(
            'service.created.error',
            json.encode(errorPayload),
          );
        } catch (natsError) {
          debugPrint('⚠️ Error publishing error to NATS: $natsError');
        }
      }

      _isCreatingService = false;
      notifyListeners();
      return {
        'success': false,
        'serviceId': null,
        'latitude': null,
        'longitude': null,
      };
    }
  }

  void reset() {
    _subcategoryResponse = null;
    _selectedSubcategory = null;
    _isLoading = false;
    _isCreatingService = false;
    _error = null;
    _formValues
      ..clear()
      ..addAll({
        //'payment_method': 'online',
        'duration_unit': 'hour',
        'tenure': 'one_time',
      });
    _latitude = null;
    _longitude = null;
    _location = null;
    _scheduleDate = null;
    _scheduleTime = null;
    _startDate = null;
    _endDate = null;
    _serviceDays = null;
    _selectedServiceMode = 'hrs';
    notifyListeners();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
