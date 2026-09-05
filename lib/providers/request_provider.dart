import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/consultation_request_model.dart';

class RequestProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<ConsultationRequestModel> _requests = [];
  bool _isLoading = true;
  StreamSubscription? _requestSubscription;

  List<ConsultationRequestModel> get requests => _requests;
  List<ConsultationRequestModel> get pendingRequests =>
      _requests.where((r) => r.status == RequestStatus.pending).toList();
  bool get isLoading => _isLoading;

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
