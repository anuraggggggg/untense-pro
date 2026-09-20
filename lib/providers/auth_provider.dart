import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/counsellor_model.dart';
import '../services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  static const String _authTokenKey = 'jwt_auth_token';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthApiService _apiService = AuthApiService();

  User? _firebaseUser;
  String? _token;
  Map<String, dynamic>? _apiUserData;
  CounsellorModel? _counsellor;
  bool _isLoading = true;
  StreamSubscription? _counsellorSubscription;

  User? get firebaseUser => _firebaseUser;
  String? get token => _token;
  CounsellorModel? get counsellor => _counsellor;
  Map<String, dynamic>? get apiUserData => _apiUserData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _token != null || _firebaseUser != null || _counsellor != null;

  AuthProvider() {
    _initSession();
  }

  Future<void> _initSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedToken = prefs.getString(_authTokenKey);

      if (storedToken != null && storedToken.isNotEmpty) {
        debugPrint('🐛 [Auth] Found stored JWT token. Restoring session via GET /counsellors/me...');
        final profileData = await _apiService.getCounsellorProfile(token: storedToken);
        _token = storedToken;
        _counsellor = CounsellorModel.fromApiJson(profileData);
        debugPrint('🐛 [Auth] Session restored successfully for counsellor: ${_counsellor?.fullName}');
      } else {
        debugPrint('🐛 [Auth] No stored JWT token found.');
      }
    } catch (e) {
      debugPrint('🐛 [Auth Error] Failed to restore session from token: $e');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      _token = null;
      _counsellor = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToCounsellorDoc(String uid) {
    _counsellorSubscription?.cancel();
    debugPrint('🐛 [AuthProvider] Listening to counsellor doc for UID: $uid');
    _counsellorSubscription =
        _firestore.collection('counsellors').doc(uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        _counsellor = CounsellorModel.fromMap(doc.data()!, doc.id);
        debugPrint(
            '🐛 [AuthProvider] Counsellor doc loaded: status = ${_counsellor?.verificationStatus}');
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('🐛 [AuthProvider Error] Listening to counsellor doc: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  /// Sends OTP code via Backend REST API (POST /auth/otp/send)
  Future<bool> sendOtp(String email,
      {String otpFor = 'COUNSELLOR_REGISTRATION'}) async {
    debugPrint('🐛 [AuthProvider] Initiating sendOtp for $email ($otpFor)');
    try {
      await _apiService.sendOtp(email: email, otpFor: otpFor);
      debugPrint('🐛 [AuthProvider] sendOtp succeeded for $email');
      return true;
    } catch (e) {
      debugPrint('🐛 [AuthProvider Error] sendOtp failed: $e');
      rethrow;
    }
  }

  /// Verifies OTP code via Backend REST API (POST /auth/otp/verify)
  Future<bool> verifyOtp(String email, String otp,
      {String otpFor = 'COUNSELLOR_REGISTRATION'}) async {
    debugPrint('🐛 [AuthProvider] Initiating verifyOtp for $email ($otpFor)');
    try {
      await _apiService.verifyOtp(email: email, otp: otp, otpFor: otpFor);
      debugPrint('🐛 [AuthProvider] verifyOtp succeeded for $email');
      return true;
    } catch (e) {
      debugPrint('🐛 [AuthProvider Error] verifyOtp failed: $e');
      rethrow;
    }
  }

  /// Registers a Counsellor via Backend REST API (POST /auth/register/counsellor)
  Future<Map<String, dynamic>> registerCounsellorWithApi({
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
    debugPrint(
        '🐛 [AuthProvider] Initiating registerCounsellorWithApi for $email');
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _apiService.registerCounsellor(
        email: email,
        phone: phone,
        password: password,
        fullName: fullName,
        qualification: qualification,
        experienceYears: experienceYears,
        govtIdType: govtIdType,
        govtIdNumber: govtIdNumber,
        emailOtp: emailOtp,
        phoneOtp: phoneOtp,
      );
      debugPrint('🐛 [AuthProvider] Backend registration successful');
      return res;
    } catch (e) {
      debugPrint(
          '🐛 [AuthProvider Error] registerCounsellorWithApi failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sign in with email and password via Backend REST API
  Future<void> signInWithEmailAndPassword(
      String email, String password) async {
    debugPrint(
        '🐛 [Auth] Initiating signInWithEmailAndPassword for $email');
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Call POST /auth/login
      final res =
          await _apiService.loginCounsellor(email: email, password: password);
      
      final jwtToken = res['token'].toString();
      final userData = res['user'] is Map<String, dynamic>
          ? res['user'] as Map<String, dynamic>
          : (res['user'] is Map ? Map<String, dynamic>.from(res['user'] as Map) : null);

      // 2. Persist Token locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, jwtToken);

      // 3. Immediately fetch Counsellor Profile GET /counsellors/me
      final profileData = await _apiService.getCounsellorProfile(token: jwtToken);

      // 4. Update internal state
      _token = jwtToken;
      _apiUserData = userData;
      _counsellor = CounsellorModel.fromApiJson(profileData, email);

      debugPrint('🐛 [Auth] DASHBOARD NAVIGATION');
    } catch (e) {
      final apiError = e.toString().replaceAll('Exception: ', '').trim();
      debugPrint(
          '🐛 [Auth Error] REST API login failed: $apiError');
      _token = null;
      _counsellor = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    debugPrint('🐛 [Auth] Signing out user');
    _token = null;
    _apiUserData = null;
    _counsellor = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
    } catch (e) {
      debugPrint('🐛 [Auth Error] Error removing token: $e');
    }
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _counsellorSubscription?.cancel();
    super.dispose();
  }
}
