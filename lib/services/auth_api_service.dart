import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';

class AuthApiService {
  final http.Client _client;

  AuthApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Send OTP to user email or mobile
  /// Endpoint: POST /api/v1/auth/otp/send
  Future<Map<String, dynamic>> sendOtp({
    required String email,
    String otpFor = 'COUNSELLOR_REGISTRATION',
  }) async {
    String sanitizedOtpFor = otpFor.toUpperCase().trim();
    if (sanitizedOtpFor == 'REGISTERATION' || sanitizedOtpFor == 'REGISTRATION') {
      sanitizedOtpFor = 'COUNSELLOR_REGISTRATION';
    } else if (sanitizedOtpFor != 'LOGIN' &&
        sanitizedOtpFor != 'CUSTOMER_REGISTRATION' &&
        sanitizedOtpFor != 'COUNSELLOR_REGISTRATION') {
      sanitizedOtpFor = 'COUNSELLOR_REGISTRATION';
    }

    final url =
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.otpSendEndpoint}');
    final payload = {
      'email': email,
      'otpFor': sanitizedOtpFor,
    };

    debugPrint('🐛 [API Request] POST $url');
    debugPrint('🐛 [API Payload] ${jsonEncode(payload)}');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('🐛 [API Response ${response.statusCode}] ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint(
            '🐛 [API Success] OTP sent successfully to $email ($otpFor)');
        return responseData;
      } else {
        final message = responseData['message'] ?? 'Failed to send OTP';
        debugPrint('🐛 [API Error Response] $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] sendOtp: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error while sending OTP: $e');
    }
  }

  /// Verify OTP for user email
  /// Endpoint: POST /api/v1/auth/otp/verify
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
    String otpFor = 'COUNSELLOR_REGISTRATION',
  }) async {
    String sanitizedOtpFor = otpFor.toUpperCase().trim();
    if (sanitizedOtpFor == 'REGISTERATION' || sanitizedOtpFor == 'REGISTRATION') {
      sanitizedOtpFor = 'COUNSELLOR_REGISTRATION';
    } else if (sanitizedOtpFor != 'LOGIN' &&
        sanitizedOtpFor != 'CUSTOMER_REGISTRATION' &&
        sanitizedOtpFor != 'COUNSELLOR_REGISTRATION') {
      sanitizedOtpFor = 'COUNSELLOR_REGISTRATION';
    }

    final url = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.otpVerifyEndpoint}');
    final payload = {
      'email': email,
      'otp': otp,
      'otpFor': sanitizedOtpFor,
    };

    debugPrint('🐛 [API Request] POST $url');
    debugPrint('🐛 [API Payload] ${jsonEncode(payload)}');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('🐛 [API Response ${response.statusCode}] ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint('🐛 [API Success] OTP verified successfully for $email');
        return responseData;
      } else {
        final message = responseData['message'] ?? 'Invalid or expired OTP';
        debugPrint('🐛 [API Error Response] $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] verifyOtp: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error while verifying OTP: $e');
    }
  }

  /// Register Counsellor
  /// Endpoint: POST /api/v1/auth/register/counsellor
  Future<Map<String, dynamic>> registerCounsellor({
    required String email,
    required String phone,
    required String password,
    required String fullName,
    required String qualification,
    required int experienceYears,
    required String govtIdType,
    required String govtIdNumber,
    required String emailOtp,
    required String phoneOtp,
  }) async {
    final url =
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.registerCounsellorEndpoint}');
    final body = {
      'email': email,
      'phone': phone,
      'password': password,
      'fullName': fullName,
      'qualification': qualification,
      'experienceYears': experienceYears,
      'govtIdType': govtIdType,
      'govtIdNumber': govtIdNumber,
      'emailOtp': emailOtp,
      'phoneOtp': phoneOtp,
    };

    debugPrint('🐛 [API Request] POST $url');
    debugPrint('🐛 [API Payload] ${jsonEncode(body)}');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      debugPrint('🐛 [API Response ${response.statusCode}] ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (responseData['success'] == true) {
          debugPrint('🐛 [API Success] Counsellor registered successfully!');
          return responseData;
        } else {
          final message = responseData['message'] ?? 'Registration failed';
          debugPrint('🐛 [API Error Response] $message');
          throw Exception(message);
        }
      } else {
        final message = responseData['message'] ?? 'Registration failed';
        debugPrint('🐛 [API Error Response ${response.statusCode}] $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] registerCounsellor: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error during registration: $e');
    }
  }

  /// Login Counsellor/User
  /// Endpoint: POST /api/v1/auth/login
  Future<Map<String, dynamic>> loginCounsellor({
    required String email,
    required String password,
    String? deviceToken,
    String platform = 'ANDROID',
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.loginEndpoint}');
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (deviceToken != null && deviceToken.isNotEmpty) {
      payload['deviceToken'] = deviceToken;
      payload['platform'] = platform;
    }

    debugPrint('🐛 [Auth] LOGIN REQUEST URL: $url');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('🐛 [Auth] LOGIN HTTP STATUS: ${response.statusCode}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      final bool success = responseData['success'] == true;
      debugPrint('🐛 [Auth] PARSED SUCCESS: $success');

      if ((response.statusCode == 200 || response.statusCode == 201) && success) {
        final data = responseData['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(responseData['data'])
            : <String, dynamic>{};

        final token = data['token']?.toString() ?? responseData['token']?.toString();
        final user = data['user'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['user'])
            : <String, dynamic>{};

        final role = user['role']?.toString().toUpperCase() ?? '';

        debugPrint('🐛 [Auth] PARSED USER: id=${user['id']}, email=${user['email']}, role=${user['role']}');
        debugPrint('🐛 [Auth] PARSED ROLE: $role');
        debugPrint('🐛 [Auth] TOKEN RECEIVED: ${token != null && token.isNotEmpty ? "[PRESENT]" : "[MISSING]"}');

        if (token == null || token.isEmpty) {
          throw Exception('Authentication token missing in response');
        }

        if (role != 'COUNSELLOR') {
          throw Exception('Access denied. Account role is "$role", required: "COUNSELLOR"');
        }

        return {
          'token': token,
          'user': user,
          'data': data,
        };
      } else {
        final message = responseData['message'] ?? 'Login failed';
        debugPrint('🐛 [Auth Error ${response.statusCode}] $message');
        if (response.statusCode == 401) {
          throw Exception(message.toString().isNotEmpty ? message : 'Invalid email or password.');
        } else if (response.statusCode == 403) {
          throw Exception('Access forbidden. Please check your credentials or account status.');
        } else if (response.statusCode == 404) {
          throw Exception('Authentication service not found.');
        } else {
          throw Exception(message);
        }
      }
    } catch (e) {
      debugPrint('🐛 [Auth Exception] loginCounsellor: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error during login: $e');
    }
  }

  /// Get Current Counsellor Profile
  /// Endpoint: GET /api/v1/counsellors/me
  Future<Map<String, dynamic>> getCounsellorProfile({
    required String token,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.counsellorMeEndpoint}');

    debugPrint('🐛 [Auth] GET COUNSELLOR PROFILE URL: $url');

    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🐛 [Auth] COUNSELLOR PROFILE STATUS: ${response.statusCode}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if ((response.statusCode == 200 || response.statusCode == 304) &&
          responseData['success'] == true) {
        final profileData = responseData['data'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(responseData['data'])
            : <String, dynamic>{};
        debugPrint('🐛 [Auth] Counsellor Profile loaded successfully for userId=${profileData['userId']}');
        return profileData;
      } else {
        final message = responseData['message'] ?? 'Failed to fetch counsellor profile';
        debugPrint('🐛 [Auth Error ${response.statusCode}] $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🐛 [Auth Exception] getCounsellorProfile: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error while fetching profile: $e');
    }
  }

  /// Update Counsellor Profile
  /// Endpoint: PATCH /api/v1/counsellors/me
  Future<Map<String, dynamic>> updateCounsellorProfile({
    required String token,
    String? bio,
    double? hourlyRateAmountInRupees,
    List<int>? specialisationIds,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.counsellorMeEndpoint}');
    final payload = <String, dynamic>{};
    if (bio != null) payload['bio'] = bio;
    if (hourlyRateAmountInRupees != null) {
      // Convert rupees to paise (1 INR = 100 paise)
      payload['hourlyRateAmount'] = (hourlyRateAmountInRupees * 100).round();
    }
    if (specialisationIds != null) payload['specialisationIds'] = specialisationIds;

    try {
      final response = await _client.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );
      final responseData = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        return responseData['data'] is Map ? Map<String, dynamic>.from(responseData['data']) : {};
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] updateCounsellorProfile: $e');
      rethrow;
    }
  }

  /// Set Availability Slots
  /// Endpoint: PUT /api/v1/counsellors/me/availability
  Future<Map<String, dynamic>> setAvailability({
    required String token,
    required List<Map<String, dynamic>> slots,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.availabilityEndpoint}');
    try {
      final response = await _client.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'slots': slots}),
      );
      final responseData = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to update availability');
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] setAvailability: $e');
      rethrow;
    }
  }

  /// Get Counsellor Followers
  /// Endpoint: GET /api/v1/counsellors/me/followers
  Future<List<Map<String, dynamic>>> getFollowers({
    required String token,
    int page = 1,
    int limit = 20,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.followersEndpoint}?page=$page&limit=$limit');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true && responseData['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (responseData['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    } catch (e) {
      debugPrint('🐛 [API Exception] getFollowers: $e');
      return [];
    }
  }

  /// Register / Refresh FCM Device Token
  /// Endpoint: POST /api/v1/notifications/device-tokens
  Future<bool> registerDeviceToken({
    required String token,
    required String deviceToken,
    String platform = 'ANDROID',
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.deviceTokensEndpoint}');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'token': deviceToken,
          'platform': platform,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🐛 [API Exception] registerDeviceToken: $e');
      return false;
    }
  }

  /// Join Consultation Session (Agora RTC Token & Credentials)
  /// Endpoint: POST /api/v1/consultations/:bookingId/join
  Future<Map<String, dynamic>> joinConsultation({
    required String token,
    required dynamic bookingId,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.consultationsEndpoint}/$bookingId/join');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final responseData = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        return responseData['data'] is Map ? Map<String, dynamic>.from(responseData['data']) : {};
      } else {
        throw Exception(responseData['message'] ?? 'Failed to join consultation session');
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] joinConsultation: $e');
      rethrow;
    }
  }

  /// Leave Consultation Session
  /// Endpoint: POST /api/v1/consultations/:bookingId/leave
  Future<bool> leaveConsultation({
    required String token,
    required dynamic bookingId,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.consultationsEndpoint}/$bookingId/leave');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🐛 [API Exception] leaveConsultation: $e');
      return false;
    }
  }

  /// End Consultation Session
  /// Endpoint: POST /api/v1/consultations/:bookingId/end
  Future<Map<String, dynamic>> endConsultation({
    required String token,
    required dynamic bookingId,
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.consultationsEndpoint}/$bookingId/end');
    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final responseData = jsonDecode(response.body);
      if ((response.statusCode == 200 || response.statusCode == 201) && responseData['success'] == true) {
        return responseData['data'] is Map ? Map<String, dynamic>.from(responseData['data']) : {};
      } else {
        throw Exception(responseData['message'] ?? 'Failed to end consultation');
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] endConsultation: $e');
      rethrow;
    }
  }

  /// List Counsellor Bookings
  /// Endpoint: GET /api/v1/bookings
  Future<List<Map<String, dynamic>>> getCounsellorBookings({
    required String token,
    String? status,
    String? consultationMode,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String>[
      'page=$page',
      'limit=$limit',
      if (status != null && status.isNotEmpty) 'status=$status',
      if (consultationMode != null && consultationMode.isNotEmpty) 'consultationMode=$consultationMode',
    ];
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.bookingsEndpoint}?${queryParams.join('&')}');
    try {
      final response = await _client.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200 && responseData['success'] == true && responseData['data'] is List) {
        return List<Map<String, dynamic>>.from(
          (responseData['data'] as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    } catch (e) {
      debugPrint('🐛 [API Exception] getCounsellorBookings: $e');
      return [];
    }
  }

  /// Get All Categories & Specialisations
  /// Endpoint: GET /api/v1/categories
  Future<List<Map<String, dynamic>>> getCategories() async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.categoriesEndpoint}');
    debugPrint('🐛 [Auth] GET CATEGORIES URL: $url');
    try {
      final response = await _client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('🐛 [Auth] CATEGORIES STATUS: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 304) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['success'] == true && responseData['data'] is List) {
          final List list = responseData['data'];
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('🐛 [Auth Exception] getCategories: $e');
      return [];
    }
  }
}
