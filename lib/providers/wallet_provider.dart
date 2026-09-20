import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_api_service.dart';

class WalletProvider extends ChangeNotifier {
  final AuthApiService _apiService = AuthApiService();

  int _balanceCredits = 0;
  String _currency = 'INR';
  List<Map<String, dynamic>> _transactions = [];
  int _totalTransactions = 0;
  bool _isLoading = true;
  bool _isApplyingCoupon = false;
  String? _errorMessage;

  int get balanceCredits => _balanceCredits;
  String get currency => _currency;
  List<Map<String, dynamic>> get transactions => _transactions;
  int get totalTransactions => _totalTransactions;
  bool get isLoading => _isLoading;
  bool get isApplyingCoupon => _isApplyingCoupon;
  String? get errorMessage => _errorMessage;

  Future<void> fetchWalletAndTransactions(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final walletData = await _apiService.getWallet(token: token);
      if (walletData.isNotEmpty) {
        final rawBal = walletData['balanceCredits'];
        if (rawBal is int) {
          _balanceCredits = rawBal;
        } else if (rawBal is num) {
          _balanceCredits = rawBal.toInt();
        } else {
          _balanceCredits = int.tryParse(rawBal?.toString() ?? '0') ?? 0;
        }
        _currency = walletData['currency']?.toString() ?? 'INR';
      }

      final txData = await _apiService.getWalletTransactions(token: token, page: 1, limit: 20);
      if (txData.isNotEmpty && txData['items'] is List) {
        final List items = txData['items'];
        _transactions = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _totalTransactions = txData['total'] is int ? txData['total'] : _transactions.length;
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> applyCoupon({required String token, required String code}) async {
    _isApplyingCoupon = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.applyCoupon(token: token, code: code);
      await fetchWalletAndTransactions(token);
      _isApplyingCoupon = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isApplyingCoupon = false;
      notifyListeners();
      return false;
    }
  }
}
