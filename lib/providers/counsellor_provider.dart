import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import '../models/counsellor_model.dart';

class CounsellorProvider extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<String?> uploadDocument({
    required String uid,
    required String docType,
    required PlatformFile file,
  }) async {
    try {
      final ref = _storage
          .ref()
          .child('counsellors')
          .child(uid)
          .child('documents')
          .child('${docType}_${file.name}');

      UploadTask uploadTask;
      if (kIsWeb) {
        if (file.bytes == null) return null;
        uploadTask = ref.putData(file.bytes!);
      } else {
        if (file.path == null) return null;
        uploadTask = ref.putFile(File(file.path!));
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _errorMessage = 'Failed to upload document: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> submitKycRegistration({
    required String uid,
    required String fullName,
    required String email,
    required String phone,
    required int yearsExperience,
    required String bio,
    required List<String> specializations,
    required String upiId,
    required Map<String, PlatformFile> pickedFiles,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final Map<String, String> documentUrls = {};

      for (var entry in pickedFiles.entries) {
        final url = await uploadDocument(
          uid: uid,
          docType: entry.key,
          file: entry.value,
        );
        if (url != null) {
          documentUrls[entry.key] = url;
        }
      }

      final counsellor = CounsellorModel(
        uid: uid,
        fullName: fullName,
        email: email,
        phone: phone,
        yearsExperience: yearsExperience,
        bio: bio,
        specializations: specializations,
        upiId: upiId,
        documents: documentUrls,
        verificationStatus: VerificationStatus.pending,
        isOnline: false,
      );

      await _firestore
          .collection('counsellors')
          .doc(uid)
          .set(counsellor.toMap(), SetOptions(merge: true));

      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'KYC submission failed: $e';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> toggleOnlineStatus(String uid, bool isOnline) async {
    try {
      await _firestore.collection('counsellors').doc(uid).update({
        'isOnline': isOnline,
      });
    } catch (e) {
      _errorMessage = 'Failed to update availability: $e';
      notifyListeners();
    }
  }
}
