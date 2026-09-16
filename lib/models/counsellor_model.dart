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

  factory CounsellorModel.fromApiJson(Map<String, dynamic> json, [String? fallbackEmail]) {
    final rawKycStatus = json['kycStatus']?.toString().toUpperCase() ??
        json['verificationStatus']?.toString().toUpperCase() ??
        'APPROVED';

    final bool verified = json['isVerified'] == true || rawKycStatus == 'APPROVED';

    VerificationStatus status = VerificationStatus.pending;
    if (rawKycStatus == 'APPROVED' || verified) {
      status = VerificationStatus.approved;
    } else if (rawKycStatus == 'REJECTED') {
      status = VerificationStatus.rejected;
    }

    int? parsedUserId;
    if (json['userId'] != null) {
      if (json['userId'] is int) {
        parsedUserId = json['userId'];
      } else {
        parsedUserId = int.tryParse(json['userId'].toString());
      }
    }

    Map<String, String> docMap = {};
    if (json['kycDocuments'] is List) {
      final docs = json['kycDocuments'] as List;
      for (var d in docs) {
        if (d is Map) {
          final type = d['type'] ?? d['docType'] ?? 'doc';
          final url = d['url'] ?? d['fileUrl'] ?? '';
          if (url.isNotEmpty) docMap[type.toString()] = url.toString();
        }
      }
    } else if (json['documents'] is Map) {
      docMap = Map<String, String>.from(json['documents']);
    }

    return CounsellorModel(
      uid: json['id']?.toString() ??
          parsedUserId?.toString() ??
          'api_counsellor',
      userId: parsedUserId,
      fullName: json['displayName'] ?? json['fullName'] ?? json['name'] ?? 'Counsellor',
      email: json['email'] ?? fallbackEmail ?? '',
      phone: json['phone'] ?? '',
      yearsExperience: json['experienceYears'] ?? json['yearsExperience'] ?? 0,
      bio: json['bio'] ?? '',
      qualification: json['qualification'] ?? '',
      hourlyRateAmount: (json['hourlyRateAmount'] ?? 0.0).toDouble(),
      currency: json['currency'] ?? 'INR',
      kycStatus: rawKycStatus,
      isVerified: verified,
      specializations: List<String>.from(json['specialisations'] ?? json['specializations'] ?? []),
      upiId: json['upiId'] ?? '',
      documents: docMap,
      verificationStatus: status,
      isOnline: json['isOnline'] ?? true,
      totalBalance: (json['totalBalance'] ?? 0.0).toDouble(),
      lifetimeEarnings: (json['lifetimeEarnings'] ?? 0.0).toDouble(),
      pendingPayouts: (json['pendingPayouts'] ?? 0.0).toDouble(),
      rating: (json['ratingAverage'] ?? json['rating'] ?? 5.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      timezone: json['timezone'] ?? 'Asia/Kolkata',
      availabilities: List<dynamic>.from(json['availabilities'] ?? []),
      avatarUrl: json['avatarUrl'],
      rejectionReason: json['rejectionReason'],
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
