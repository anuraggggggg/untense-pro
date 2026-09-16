class AppConstants {
  static const String appName = 'UnTense Professional';

  // Backend REST API Configuration
  static const String apiBaseUrl = 'http://65.0.73.114:4001/api/v1';
  static const String otpSendEndpoint = '/auth/otp/send';
  static const String otpVerifyEndpoint = '/auth/otp/verify';
  static const String loginEndpoint = '/auth/login';
  static const String counsellorMeEndpoint = '/counsellors/me';

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
