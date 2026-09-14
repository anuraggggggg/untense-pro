import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/counsellor_model.dart';
import '../services/auth_api_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthApiService _apiService = AuthApiService();

  User? _firebaseUser;
  Map<String, dynamic>? _apiUserData;
  CounsellorModel? _counsellor;
  bool _isLoading = true;
  StreamSubscription? _counsellorSubscription;

  User? get firebaseUser => _firebaseUser;
  CounsellorModel? get counsellor => _counsellor;
  Map<String, dynamic>? get apiUserData => _apiUserData;
  bool get isLoading => _isLoading;
  bool get isAuthenticated =>
      _firebaseUser != null || _apiUserData != null || _counsellor != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((User? user) async {
      _firebaseUser = user;
      debugPrint(
          '🐛 [AuthProvider] authStateChanges: user = ${user?.email ?? "null"}');
      if (user != null) {
        _listenToCounsellorDoc(user.uid);
      } else {
        if (_apiUserData == null) {
          _counsellor = null;
        }
        _counsellorSubscription?.cancel();
        _isLoading = false;
        notifyListeners();
      }
    });
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
      } else {
        _counsellor = null;
        debugPrint('🐛 [AuthProvider] Counsellor doc does not exist');
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
  Future<bool> verifyOtp(String email, String otp) async {
    debugPrint('🐛 [AuthProvider] Initiating verifyOtp for $email');
    try {
      await _apiService.verifyOtp(email: email, otp: otp);
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
        '🐛 [AuthProvider] Initiating signInWithEmailAndPassword for $email');
    _isLoading = true;
    notifyListeners();

    try {
      final res =
          await _apiService.loginCounsellor(email: email, password: password);
      if (res['data'] is Map<String, dynamic>) {
        _apiUserData = Map<String, dynamic>.from(res['data']);
      } else if (res['user'] is Map<String, dynamic>) {
        _apiUserData = Map<String, dynamic>.from(res['user']);
      } else {
        _apiUserData = <String, dynamic>{'email': email, ...res};
      }
      debugPrint('🐛 [AuthProvider] REST API login successful for $email');

      final userData = _apiUserData!;
      _counsellor = CounsellorModel(
        uid: userData['id']?.toString() ??
            userData['userId']?.toString() ??
            userData['uid']?.toString() ??
            'api_user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: userData['fullName'] ?? userData['name'] ?? 'Counsellor',
        email: email,
        phone: userData['phone'] ?? '',
        yearsExperience: userData['experienceYears'] ?? 1,
        bio: userData['qualification'] ?? 'Therapist',
        specializations: [],
        upiId: '',
        documents: {},
        verificationStatus: VerificationStatus.approved,
      );
    } catch (e) {
      final apiError = e.toString().replaceAll('Exception: ', '').trim();
      debugPrint(
          '🐛 [AuthProvider Error] REST API login failed: $apiError');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    debugPrint('🐛 [AuthProvider] Signing out user');
    _apiUserData = null;
    _counsellor = null;
    await _auth.signOut();
    notifyListeners();
  }

  @override
  void dispose() {
    _counsellorSubscription?.cancel();
    super.dispose();
  }
}
