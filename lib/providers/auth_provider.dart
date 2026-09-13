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
  CounsellorModel? _counsellor;
  bool _isLoading = true;
  StreamSubscription? _counsellorSubscription;

  User? get firebaseUser => _firebaseUser;
  CounsellorModel? get counsellor => _counsellor;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;

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
        _counsellor = null;
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

      // Attempt Firebase signup as fallback/sync if credentials permit
      try {
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        debugPrint('🐛 [AuthProvider] Firebase user created for $email');
      } catch (e) {
        debugPrint(
            '🐛 [AuthProvider Sync Warning] Firebase signup fallback: $e');
      }
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

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    debugPrint(
        '🐛 [AuthProvider] Initiating signInWithEmailAndPassword for $email');
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      debugPrint('🐛 [AuthProvider] Firebase signin successful for $email');
    } catch (e) {
      debugPrint(
          '🐛 [AuthProvider Error] signInWithEmailAndPassword failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    debugPrint(
        '🐛 [AuthProvider] Initiating signUpWithEmailAndPassword for $email');
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      debugPrint('🐛 [AuthProvider] Firebase signup successful for $email');
    } catch (e) {
      debugPrint(
          '🐛 [AuthProvider Error] signUpWithEmailAndPassword failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    debugPrint('🐛 [AuthProvider] Signing out user');
    await _auth.signOut();
  }

  @override
  void dispose() {
    _counsellorSubscription?.cancel();
    super.dispose();
  }
}
