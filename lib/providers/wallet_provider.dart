import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class WalletProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  bool _isRequestingPayout = false;
  String? _errorMessage;
  StreamSubscription? _txSubscription;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isRequestingPayout => _isRequestingPayout;
  String? get errorMessage => _errorMessage;

  void listenToTransactions(String counsellorId) {
    _txSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _txSubscription = _firestore
        .collection('counsellors')
        .doc(counsellorId)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) {
      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data(), doc.id))
          .toList();
      _transactions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _isLoading = false;
      notifyListeners();
    }, onError: (_) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<bool> withdrawToUpi({
    required String counsellorId,
    required double amount,
    required String upiId,
  }) async {
    _isRequestingPayout = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docRef = _firestore.collection('counsellors').doc(counsellorId);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final currentBalance =
            (snapshot.data()?['totalBalance'] ?? 0.0).toDouble();

        if (currentBalance < amount) {
          throw Exception('Insufficient balance. Available: ₹$currentBalance');
        }

        final newBalance = currentBalance - amount;
        final currentPending =
            (snapshot.data()?['pendingPayouts'] ?? 0.0).toDouble();

        transaction.update(docRef, {
          'totalBalance': newBalance,
          'pendingPayouts': currentPending + amount,
        });

        final txRef = docRef.collection('transactions').doc();
        transaction.set(txRef, {
          'amount': amount,
          'type': TransactionType.payout.name,
          'status': TransactionStatus.pending.name,
          'upiId': upiId,
          'description': 'Withdrawal to UPI: $upiId',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      _isRequestingPayout = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isRequestingPayout = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _txSubscription?.cancel();
    super.dispose();
  }
}
