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
    final url =
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.otpSendEndpoint}');
    final payload = {
      'email': email,
      'otpFor': otpFor,
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
  }) async {
    final url = Uri.parse(
        '${AppConstants.apiBaseUrl}${AppConstants.otpVerifyEndpoint}');
    final payload = {
      'email': email,
      'otp': otp,
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
        Uri.parse('${AppConstants.apiBaseUrl}/auth/register/counsellor');
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
  }) async {
    final url = Uri.parse('${AppConstants.apiBaseUrl}/auth/login');
    final payload = {
      'email': email,
      'password': password,
    };

    debugPrint('🐛 [API Request] POST $url');
    debugPrint('🐛 [API Payload] email: $email, password: ***');

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      debugPrint('🐛 [API Response ${response.statusCode}] ${response.body}');

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        debugPrint('🐛 [API Success] Login successful for $email');
        return responseData;
      } else {
        final message = responseData['message'] ?? 'Login failed';
        debugPrint('🐛 [API Error Response] $message');
        throw Exception(message);
      }
    } catch (e) {
      debugPrint('🐛 [API Exception] loginCounsellor: $e');
      if (e is Exception) rethrow;
      throw Exception('Network error during login: $e');
    }
  }
}
