class AppConstants {
  static const String appName = 'UnTense Professional';

  // Backend REST API Configuration
  static const String apiBaseUrl = 'http://65.0.73.114:4001/api/v1';
  // Auth Endpoints
  static const String otpSendEndpoint = '/auth/otp/send';
  static const String otpVerifyEndpoint = '/auth/otp/verify';
  static const String registerCounsellorEndpoint = '/auth/register/counsellor';
  static const String loginEndpoint = '/auth/login';
  static const String logoutEndpoint = '/auth/logout';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  // Counsellor Profile & KYC Endpoints
  static const String counsellorMeEndpoint = '/counsellors/me';
  static const String kycSubmitEndpoint = '/counsellors/me/kyc';
  static const String filesUploadEndpoint = '/files';
  static const String availabilityEndpoint = '/counsellors/me/availability';
  static const String followersEndpoint = '/counsellors/me/followers';

  // Consultations & Bookings Endpoints
  static const String bookingsEndpoint = '/bookings';
  static const String consultationsEndpoint = '/consultations';
  static const String instantConsultationStartEndpoint = '/consultations/wallet/start';

  // Chat Endpoints
  static const String chatThreadsEndpoint = '/chat/threads';

  // Wallet Endpoints
  static const String walletMeEndpoint = '/wallet/me';
  static const String walletTransactionsEndpoint = '/wallet/me/transactions';
  static const String walletSendEndpoint = '/wallet/send';

  // Categories & Notifications
  static const String categoriesEndpoint = '/categories';
  static const String reviewsEndpoint = '/reviews';
  static const String deviceTokensEndpoint = '/notifications/device-tokens';
  static const String notificationsEndpoint = '/notifications';

  // Agora App ID - Replace with your actual Agora App ID from Agora Console
  static const String agoraAppId = 'YOUR_AGORA_APP_ID';

  // Specialization Options
  static const List<String> specializations = [
    'Anxiety & Stress',
    'Depression',
    'Relationship Counselling',
    'Trauma & PTSD',
    'Child & Adolescent Therapy',
    'Career & Life Coaching',
    'Grief & Loss',
    'Addiction Recovery',
    'Self-Esteem & Identity',
  ];

  // Document Types
  static const String docAadhaar = 'aadhaar';
  static const String docPan = 'pan';
  static const String docMarksheet10 = 'marksheet_10';
  static const String docDegree = 'degree';
}
