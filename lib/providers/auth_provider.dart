import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/counsellor_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    _counsellorSubscription =
        _firestore.collection('counsellors').doc(uid).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        _counsellor = CounsellorModel.fromMap(doc.data()!, doc.id);
      } else {
        _counsellor = null;
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmailAndPassword(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  void dispose() {
    _counsellorSubscription?.cancel();
    super.dispose();
  }
}
