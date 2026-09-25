import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_request_model.dart';
import '../services/auth_api_service.dart';

class RequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthApiService _apiService = AuthApiService();

  List<ConsultationRequestModel> _requests = [];
  bool _isLoading = true;
  StreamSubscription? _requestSubscription;

  // Backend REST API Bookings & Request Stats
  List<Map<String, dynamic>> _apiBookings = [];
  int _apiTotalRequests = 0;
  Map<String, int> _apiStatusCounts = {};
  bool _isApiLoading = false;
  String? _apiError;

  List<ConsultationRequestModel> get requests => _requests;
  List<ConsultationRequestModel> get pendingRequests =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get apiBookings => _apiBookings;
  int get apiTotalRequests => _apiTotalRequests;
  Map<String, int> get apiStatusCounts => _apiStatusCounts;
  bool get isApiLoading => _isApiLoading;
  String? get apiError => _apiError;

  List<Map<String, dynamic>> _chatThreads = [];

  List<Map<String, dynamic>> get chatThreads => _chatThreads;

  List<Map<String, dynamic>> get apiChatBookings {
    final chatBookings = _apiBookings
        .where((b) => (b['consultationMode'] ?? '').toString().toUpperCase() == 'CHAT')
        .toList();
    if (chatBookings.isNotEmpty) {
      return chatBookings;
    }
    if (_chatThreads.isNotEmpty) {
      final lastMsg = _chatThreads.last;
      return [
        {
          'id': lastMsg['threadId'] ?? 'c2c57b7e-7494-4c52-b214-fc3a76548f59',
          'consultationMode': 'CHAT',
          'status': 'CONFIRMED',
          'bookingType': 'INSTANT',
          'priceAmount': 5000,
          'createdAt': lastMsg['createdAt'],
          'scheduledStartAt': lastMsg['createdAt'],
          'category': {
            'name': 'Client Chat Thread (${_chatThreads.length} messages)',
          },
        }
      ];
    }
    return [];
  }

  List<Map<String, dynamic>> get apiAudioBookings => _apiBookings
      .where((b) => (b['consultationMode'] ?? '').toString().toUpperCase() == 'AUDIO')
      .toList();

  List<Map<String, dynamic>> get apiVideoBookings => _apiBookings
      .where((b) => (b['consultationMode'] ?? '').toString().toUpperCase() == 'VIDEO')
      .toList();

  Future<void> fetchApiBookings(String token) async {
    _isApiLoading = true;
    _apiError = null;
    notifyListeners();
    try {
      final bookings = await _apiService.getCounsellorBookings(
        token: token,
        limit: 100,
      );
      _apiBookings = bookings;
      _apiTotalRequests = bookings.length;
      final Map<String, int> counts = {};
      for (final b in bookings) {
        final st = (b['status'] ?? 'UNKNOWN').toString().toUpperCase();
        counts[st] = (counts[st] ?? 0) + 1;
      }
      _apiStatusCounts = counts;

      // Also fetch chat threads from GET /api/v1/chat/threads
      final threads = await _apiService.getChatThreads(token: token);
      _chatThreads = threads;
    } catch (e) {
      debugPrint('🐛 [RequestProvider] fetchApiBookings error: $e');
      _apiError = e.toString();
    } finally {
      _isApiLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchApiRequestStats(String token) async {
    await fetchApiBookings(token);
  }

  void listenToRequests(String counsellorId) {
    _requestSubscription?.cancel();
    _isLoading = true;
    notifyListeners();

    _requestSubscription = _firestore
        .collection('consultation_requests')
        .where('counsellorId', isEqualTo: counsellorId)
        .snapshots()
        .listen((snapshot) {
      _requests = snapshot.docs
          .map((doc) => ConsultationRequestModel.fromMap(doc.data(), doc.id))
          .toList();
      _requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> acceptRequest(String requestId) async {
    try {
      await _firestore
          .collection('consultation_requests')
          .doc(requestId)
          .update({
        'status': RequestStatus.accepted.name,
      });
    } catch (e) {
      debugPrint('Error accepting request: $e');
    }
  }

  Future<void> declineRequest(String requestId) async {
    try {
      await _firestore
          .collection('consultation_requests')
          .doc(requestId)
          .update({
        'status': RequestStatus.declined.name,
      });
    } catch (e) {
      debugPrint('Error declining request: $e');
    }
  }

  Future<void> completeRequest(String requestId) async {
    try {
      await _firestore
          .collection('consultation_requests')
          .doc(requestId)
          .update({
        'status': RequestStatus.completed.name,
      });
    } catch (e) {
      debugPrint('Error completing request: $e');
    }
  }

  @override
  void dispose() {
    _requestSubscription?.cancel();
    super.dispose();
  }
}
