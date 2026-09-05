enum RequestType { chat, audio, video }
enum RequestStatus { pending, accepted, declined, completed }

class ConsultationRequestModel {
  final String id;
  final String clientId;
  final String clientName;
  final String? clientAvatar;
  final String counsellorId;
  final RequestType requestType;
  final RequestStatus status;
  final double feeAmount;
  final String channelId;
  final String? agoraToken;
  final DateTime createdAt;

  ConsultationRequestModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    required this.counsellorId,
    required this.requestType,
    required this.status,
    required this.feeAmount,
    required this.channelId,
    this.agoraToken,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory ConsultationRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return ConsultationRequestModel(
      id: id,
      clientId: map['clientId'] ?? '',
      clientName: map['clientName'] ?? 'Anonymous Client',
      clientAvatar: map['clientAvatar'],
      counsellorId: map['counsellorId'] ?? '',
      requestType: _parseType(map['requestType']),
      status: _parseStatus(map['status']),
      feeAmount: (map['feeAmount'] ?? 500.0).toDouble(),
      channelId: map['channelId'] ?? id,
      agoraToken: map['agoraToken'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'counsellorId': counsellorId,
      'requestType': requestType.name,
      'status': status.name,
      'feeAmount': feeAmount,
      'channelId': channelId,
      'agoraToken': agoraToken,
      'createdAt': createdAt,
    };
  }

  static RequestType _parseType(String? type) {
    switch (type) {
      case 'audio':
        return RequestType.audio;
      case 'video':
        return RequestType.video;
      case 'chat':
      default:
        return RequestType.chat;
    }
  }

  static RequestStatus _parseStatus(String? status) {
    switch (status) {
      case 'accepted':
        return RequestStatus.accepted;
      case 'declined':
        return RequestStatus.declined;
      case 'completed':
        return RequestStatus.completed;
      case 'pending':
      default:
        return RequestStatus.pending;
    }
  }
}
