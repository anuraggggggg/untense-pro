enum VerificationStatus { pending, approved, rejected }

class CounsellorModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final int yearsExperience;
  final String bio;
  final List<String> specializations;
  final String upiId;
  final Map<String, String> documents; // e.g. {'aadhaar': url, 'pan': url}
  final VerificationStatus verificationStatus;
  final bool isOnline;
  final double totalBalance;
  final double lifetimeEarnings;
  final double pendingPayouts;
  final double rating;
  final String? avatarUrl;
  final String? rejectionReason;
  final DateTime createdAt;

  CounsellorModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.yearsExperience,
    required this.bio,
    required this.specializations,
    required this.upiId,
    required this.documents,
    this.verificationStatus = VerificationStatus.pending,
    this.isOnline = false,
    this.totalBalance = 0.0,
    this.lifetimeEarnings = 0.0,
    this.pendingPayouts = 0.0,
    this.rating = 5.0,
    this.avatarUrl,
    this.rejectionReason,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CounsellorModel.fromMap(Map<String, dynamic> map, String uid) {
    return CounsellorModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      yearsExperience: map['yearsExperience'] ?? 0,
      bio: map['bio'] ?? '',
      specializations: List<String>.from(map['specializations'] ?? []),
      upiId: map['upiId'] ?? '',
      documents: Map<String, String>.from(map['documents'] ?? {}),
      verificationStatus: _parseStatus(map['verificationStatus']),
      isOnline: map['isOnline'] ?? false,
      totalBalance: (map['totalBalance'] ?? 0.0).toDouble(),
      lifetimeEarnings: (map['lifetimeEarnings'] ?? 0.0).toDouble(),
      pendingPayouts: (map['pendingPayouts'] ?? 0.0).toDouble(),
      rating: (map['rating'] ?? 5.0).toDouble(),
      avatarUrl: map['avatarUrl'],
      rejectionReason: map['rejectionReason'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'yearsExperience': yearsExperience,
      'bio': bio,
      'specializations': specializations,
      'upiId': upiId,
      'documents': documents,
      'verificationStatus': verificationStatus.name,
      'isOnline': isOnline,
      'totalBalance': totalBalance,
      'lifetimeEarnings': lifetimeEarnings,
      'pendingPayouts': pendingPayouts,
      'rating': rating,
      'avatarUrl': avatarUrl,
      'rejectionReason': rejectionReason,
      'createdAt': createdAt,
    };
  }

  static VerificationStatus _parseStatus(String? status) {
    switch (status) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
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
    List<String>? specializations,
    String? upiId,
    Map<String, String>? documents,
    VerificationStatus? verificationStatus,
    bool? isOnline,
    double? totalBalance,
    double? lifetimeEarnings,
    double? pendingPayouts,
    double? rating,
    String? avatarUrl,
    String? rejectionReason,
  }) {
    return CounsellorModel(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      bio: bio ?? this.bio,
      specializations: specializations ?? this.specializations,
      upiId: upiId ?? this.upiId,
      documents: documents ?? this.documents,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isOnline: isOnline ?? this.isOnline,
      totalBalance: totalBalance ?? this.totalBalance,
      lifetimeEarnings: lifetimeEarnings ?? this.lifetimeEarnings,
      pendingPayouts: pendingPayouts ?? this.pendingPayouts,
      rating: rating ?? this.rating,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt,
    );
  }
}
