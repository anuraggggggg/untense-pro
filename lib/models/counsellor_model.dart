enum VerificationStatus { pending, approved, rejected }

class CounsellorModel {
  final String uid;
  final int? userId;
  final String fullName;
  final String email;
  final String phone;
  final int yearsExperience;
  final String bio;
  final String qualification;
  final double hourlyRateAmount;
  final String currency;
  final String kycStatus;
  final bool isVerified;
  final List<String> specializations;
  final String upiId;
  final Map<String, String> documents;
  final VerificationStatus verificationStatus;
  final bool isOnline;
  final double totalBalance;
  final double lifetimeEarnings;
  final double pendingPayouts;
  final double rating;
  final int ratingCount;
  final String timezone;
  final List<dynamic> availabilities;
  final String? avatarUrl;
  final String? rejectionReason;
  final DateTime createdAt;

  CounsellorModel({
    required this.uid,
    this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.yearsExperience,
    required this.bio,
    this.qualification = '',
    this.hourlyRateAmount = 0.0,
    this.currency = 'INR',
    this.kycStatus = 'APPROVED',
    this.isVerified = true,
    required this.specializations,
    required this.upiId,
    required this.documents,
    this.verificationStatus = VerificationStatus.pending,
    this.isOnline = false,
    this.totalBalance = 0.0,
    this.lifetimeEarnings = 0.0,
    this.pendingPayouts = 0.0,
    this.rating = 5.0,
    this.ratingCount = 0,
    this.timezone = 'Asia/Kolkata',
    this.availabilities = const [],
    this.avatarUrl,
    this.rejectionReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  static double _parseNumToDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  static int _parseNumToInt(dynamic val, [int defaultVal = 0]) {
    if (val == null) return defaultVal;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultVal;
    return defaultVal;
  }

  static bool _parseToBool(dynamic val, [bool defaultVal = false]) {
    if (val == null) return defaultVal;
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val is String) {
      final s = val.trim().toLowerCase();
      return s == 'true' || s == '1' || s == 'yes';
    }
    return defaultVal;
  }

  factory CounsellorModel.fromApiJson(Map<String, dynamic> json, [String? fallbackEmail]) {
    Map<String, dynamic>? userMap;
    if (json['user'] is Map) {
      userMap = Map<String, dynamic>.from(json['user'] as Map);
    }

    final rawKycStatus = (json['kycStatus'] ??
            json['verificationStatus'] ??
            json['kyc_status'] ??
            'APPROVED')
        .toString()
        .toUpperCase();

    final bool verified = _parseToBool(json['isVerified'] ?? json['is_verified'], rawKycStatus == 'APPROVED');

    VerificationStatus status = VerificationStatus.pending;
    if (rawKycStatus == 'APPROVED' || verified) {
      status = VerificationStatus.approved;
    } else if (rawKycStatus == 'REJECTED') {
      status = VerificationStatus.rejected;
    }

    int? parsedUserId;
    final rawUserId = json['userId'] ?? json['user_id'] ?? userMap?['id'];
    if (rawUserId != null) {
      if (rawUserId is int) {
        parsedUserId = rawUserId;
      } else if (rawUserId is num) {
        parsedUserId = rawUserId.toInt();
      } else {
        parsedUserId = int.tryParse(rawUserId.toString());
      }
    }

    Map<String, String> docMap = {};
    if (json['kycDocuments'] is List) {
      final docs = json['kycDocuments'] as List;
      for (var d in docs) {
        if (d is Map) {
          final type = d['type'] ?? d['docType'] ?? 'doc';
          final url = d['url'] ?? d['fileUrl'] ?? d['path'] ?? '';
          if (url != null && url.toString().isNotEmpty) {
            docMap[type.toString()] = url.toString();
          }
        }
      }
    } else if (json['documents'] is Map) {
      final docs = json['documents'] as Map;
      docs.forEach((key, val) {
        if (val != null) {
          if (val is Map) {
            final url = val['url'] ?? val['fileUrl'] ?? val['path'] ?? val.toString();
            docMap[key.toString()] = url.toString();
          } else {
            docMap[key.toString()] = val.toString();
          }
        }
      });
    }

    final rawSpecs = json['specialisations'] ?? json['specializations'] ?? [];
    List<String> specsList = [];
    if (rawSpecs is List) {
      for (var item in rawSpecs) {
        if (item == null) continue;
        if (item is String) {
          specsList.add(item);
        } else if (item is Map) {
          final name = item['name'] ?? item['title'] ?? item['specialisation'] ?? item['specialization'] ?? item.toString();
          specsList.add(name.toString());
        } else {
          specsList.add(item.toString());
        }
      }
    }

    final rawAvatar = json['avatarUrl'] ?? json['avatar'] ?? userMap?['avatarUrl'] ?? userMap?['avatar'];
    final avatarUrlStr = (rawAvatar != null && rawAvatar is! Map) ? rawAvatar.toString() : null;

    final rawRejection = json['rejectionReason'] ?? json['rejection_reason'];
    final rejectionReasonStr = (rawRejection != null && rawRejection is! Map) ? rawRejection.toString() : null;

    final uidStr = (json['id'] ?? json['_id'] ?? parsedUserId ?? 'api_counsellor').toString();

    final availabilitiesList = json['availabilities'] is List
        ? List<dynamic>.from(json['availabilities'])
        : <dynamic>[];

    return CounsellorModel(
      uid: uidStr,
      userId: parsedUserId,
      fullName: (json['displayName'] ??
              json['fullName'] ??
              json['name'] ??
              userMap?['displayName'] ??
              userMap?['fullName'] ??
              userMap?['name'] ??
              'Counsellor')
          .toString(),
      email: (json['email'] ?? userMap?['email'] ?? fallbackEmail ?? '').toString(),
      phone: (json['phone'] ?? userMap?['phone'] ?? '').toString(),
      yearsExperience: _parseNumToInt(json['experienceYears'] ?? json['yearsExperience']),
      bio: (json['bio'] ?? '').toString(),
      qualification: (json['qualification'] ?? '').toString(),
      hourlyRateAmount: _parseNumToDouble(json['hourlyRateAmount'] ?? json['hourly_rate']),
      currency: (json['currency'] ?? 'INR').toString(),
      kycStatus: rawKycStatus,
      isVerified: verified,
      specializations: specsList,
      upiId: (json['upiId'] ?? json['upi_id'] ?? '').toString(),
      documents: docMap,
      verificationStatus: status,
      isOnline: _parseToBool(json['isOnline'], true),
      totalBalance: _parseNumToDouble(json['totalBalance'] ?? json['total_balance']),
      lifetimeEarnings: _parseNumToDouble(json['lifetimeEarnings'] ?? json['lifetime_earnings']),
      pendingPayouts: _parseNumToDouble(json['pendingPayouts'] ?? json['pending_payouts']),
      rating: _parseNumToDouble(json['ratingAverage'] ?? json['rating'], 5.0),
      ratingCount: _parseNumToInt(json['ratingCount'] ?? json['rating_count']),
      timezone: (json['timezone'] ?? 'Asia/Kolkata').toString(),
      availabilities: availabilitiesList,
      avatarUrl: avatarUrlStr,
      rejectionReason: rejectionReasonStr,
    );
  }

  factory CounsellorModel.fromMap(Map<String, dynamic> map, String uid) {
    return CounsellorModel.fromApiJson({...map, 'id': uid});
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userId': userId,
      'fullName': fullName,
      'displayName': fullName,
      'email': email,
      'phone': phone,
      'yearsExperience': yearsExperience,
      'experienceYears': yearsExperience,
      'bio': bio,
      'qualification': qualification,
      'hourlyRateAmount': hourlyRateAmount,
      'currency': currency,
      'kycStatus': kycStatus,
      'isVerified': isVerified,
      'specializations': specializations,
      'upiId': upiId,
      'documents': documents,
      'verificationStatus': verificationStatus.name,
      'isOnline': isOnline,
      'totalBalance': totalBalance,
      'lifetimeEarnings': lifetimeEarnings,
      'pendingPayouts': pendingPayouts,
      'rating': rating,
      'ratingCount': ratingCount,
      'timezone': timezone,
      'avatarUrl': avatarUrl,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }

  static VerificationStatus _parseStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return VerificationStatus.approved;
      case 'REJECTED':
        return VerificationStatus.rejected;
      case 'PENDING':
      default:
        return VerificationStatus.pending;
    }
  }

  CounsellorModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    int? yearsExperience,
    String? bio,
    String? qualification,
    double? hourlyRateAmount,
    String? currency,
    String? kycStatus,
    bool? isVerified,
    List<String>? specializations,
    String? upiId,
    Map<String, String>? documents,
    VerificationStatus? verificationStatus,
    bool? isOnline,
    double? totalBalance,
    double? lifetimeEarnings,
    double? pendingPayouts,
    double? rating,
    int? ratingCount,
    String? timezone,
    List<dynamic>? availabilities,
    String? avatarUrl,
    String? rejectionReason,
  }) {
    return CounsellorModel(
      uid: uid,
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      bio: bio ?? this.bio,
      qualification: qualification ?? this.qualification,
      hourlyRateAmount: hourlyRateAmount ?? this.hourlyRateAmount,
      currency: currency ?? this.currency,
      kycStatus: kycStatus ?? this.kycStatus,
      isVerified: isVerified ?? this.isVerified,
      specializations: specializations ?? this.specializations,
      upiId: upiId ?? this.upiId,
      documents: documents ?? this.documents,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isOnline: isOnline ?? this.isOnline,
      totalBalance: totalBalance ?? this.totalBalance,
      lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      timezone: timezone ?? this.timezone,
      availabilities: availabilities ?? this.availabilities,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
    );
  }
}
