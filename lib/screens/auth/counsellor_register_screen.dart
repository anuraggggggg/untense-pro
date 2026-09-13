import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class CounsellorRegisterScreen extends StatefulWidget {
  const CounsellorRegisterScreen({super.key});

  @override
  State<CounsellorRegisterScreen> createState() =>
      _CounsellorRegisterScreenState();
}

class _CounsellorRegisterScreenState extends State<CounsellorRegisterScreen> {
  int _currentStep = 0;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Step 1: Personal & Account
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91');
  final _passwordController = TextEditingController();

  // Step 2: OTP Verification
  final _emailOtpController = TextEditingController();
  final _phoneOtpController = TextEditingController(text: '0000');
  bool _isSendingOtp = false;
  bool _isVerifyingOtp = false;
  bool _otpSent = false;
  bool _isEmailOtpVerified = false;

  // Step 3: Professional & Govt ID
  final _qualificationController = TextEditingController();
  final _expController = TextEditingController(text: '3');
  final _govtIdNumberController = TextEditingController();
  String _selectedGovtIdType = 'AADHAAR';

  String? _errorMessage;
  String? _successMessage;

  final List<String> _govtIdTypes = [
    'AADHAAR',
    'PAN',
    'PASSPORT',
    'DRIVING_LICENSE',
    'VOTER_ID',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailOtpController.dispose();
    _phoneOtpController.dispose();
    _qualificationController.dispose();
    _expController.dispose();
    _govtIdNumberController.dispose();
    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    if (!_formKeyStep1.currentState!.validate()) return;
    if (!mounted) return;
    setState(() {
      _isSendingOtp = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendOtp(email, otpFor: 'COUNSELLOR_REGISTRATION');

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _successMessage = 'OTP code sent to $email';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP sent successfully to $email'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '').trim();
      if (!mounted) return;
      setState(() {
        _errorMessage = err;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send OTP: $err'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _verifyEmailOtp() async {
    final otp = _emailOtpController.text.trim();
    if (otp.length != 6) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Enter 6-digit OTP code');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isVerifyingOtp = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyOtp(email, otp);
      if (success) {
        if (!mounted) return;
        setState(() {
          _isEmailOtpVerified = true;
          _successMessage = '✓ Email OTP Verified Successfully!';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Email OTP Verified Successfully!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      }
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '').trim();
      if (!mounted) return;
      setState(() {
        _errorMessage = err;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('OTP Verification Failed: $err'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKeyStep3.currentState!.validate()) return;
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    try {
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();
      final password = _passwordController.text;
      final fullName = _fullNameController.text.trim();
      final qualification = _qualificationController.text.trim();
      final experienceYears = int.parse(_expController.text.trim());
      final govtIdNumber = _govtIdNumberController.text.trim();
      final emailOtp = _emailOtpController.text.trim();
      final phoneOtp = _phoneOtpController.text.trim();

      final res = await authProvider.registerCounsellorWithApi(
        email: email,
        phone: phone,
        password: password,
        fullName: fullName,
        qualification: qualification,
        experienceYears: experienceYears,
        govtIdType: _selectedGovtIdType,
        govtIdNumber: govtIdNumber,
        emailOtp: emailOtp,
        phoneOtp: phoneOtp,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Registration successful!'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
      context.go('/pending-verification');
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '').trim();
      if (!mounted) return;
      setState(() {
        _errorMessage = err;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration Failed: $err'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_emailOtpController.text.trim().length != 6) {
        setState(
            () => _errorMessage = 'Please enter a valid 6-digit Email OTP');
        return;
      }
      setState(() {
        _errorMessage = null;
        _currentStep += 1;
      });
    } else if (_currentStep == 2) {
      _submitRegistration();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _errorMessage = null;
        _currentStep -= 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counsellor Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status & Feedback Banner
            if (_errorMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            if (_successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: AppColors.onlineGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

            // Stepper Form
            Expanded(
              child: Stepper(
                type: StepperType.horizontal,
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                controlsBuilder: (context, details) {
                  return Container(
                    margin: const EdgeInsets.only(top: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: authProvider.isLoading ||
                                    _isSendingOtp ||
                                    _isVerifyingOtp
                                ? null
                                : details.onStepContinue,
                            child: authProvider.isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_currentStep == 2
                                    ? 'Submit Registration'
                                    : 'Next Step'),
                          ),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
                steps: [
                  // STEP 1: Personal & Credentials
                  Step(
                    title: const Text('Account'),
                    isActive: _currentStep >= 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.editing,
                    content: Form(
                      key: _formKeyStep1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Counsellor Credentials',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _fullNameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name (Dr. / Mr. / Ms.)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Enter your full name'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (val) =>
                                val == null || !val.contains('@')
                                    ? 'Enter a valid email'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (with country code)',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (val) => val == null || val.length < 10
                                ? 'Enter valid phone number (e.g. +919876543210)'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              helperText:
                                  'Must contain uppercase, lowercase, digit, and special symbol',
                            ),
                            validator: (val) {
                              if (val == null || val.length < 8) {
                                return 'Password must be at least 8 characters';
                              }
                              final regex = RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
                              if (!regex.hasMatch(val)) {
                                return 'Include uppercase, lowercase, number & symbol';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // STEP 2: OTP Verification
                  Step(
                    title: const Text('OTP Verify'),
                    isActive: _currentStep >= 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.editing,
                    content: Form(
                      key: _formKeyStep2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email & Phone Verification',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isSendingOtp ? null : _sendEmailOtp,
                            icon: const Icon(Icons.send_rounded),
                            label: Text(_otpSent
                                ? 'Resend Email OTP Code'
                                : 'Send Email OTP Code'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailOtpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: InputDecoration(
                              labelText: '6-digit Email OTP',
                              prefixIcon:
                                  const Icon(Icons.mark_email_read_outlined),
                              suffixIcon: _isEmailOtpVerified
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.onlineGreen)
                                  : null,
                            ),
                            validator: (val) => val == null || val.length != 6
                                ? 'Enter 6-digit OTP code sent to your email'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isVerifyingOtp ? null : _verifyEmailOtp,
                              icon: const Icon(Icons.verified_outlined),
                              label: _isVerifyingOtp
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(_isEmailOtpVerified
                                      ? 'Email OTP Verified ✓'
                                      : 'Verify Email OTP Code'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isEmailOtpVerified
                                    ? AppColors.onlineGreen
                                    : AppColors.primaryNavy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneOtpController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              labelText: '4-digit Phone OTP',
                              prefixIcon: Icon(Icons.sms_outlined),
                            ),
                            validator: (val) => val == null || val.length != 4
                                ? 'Enter 4-digit Phone OTP'
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // STEP 3: Professional & Govt ID
                  Step(
                    title: const Text('Govt ID'),
                    isActive: _currentStep >= 2,
                    state: _currentStep == 2
                        ? StepState.editing
                        : StepState.complete,
                    content: Form(
                      key: _formKeyStep3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Qualification & Government ID',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryNavy,
                                ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _qualificationController,
                            decoration: const InputDecoration(
                              labelText: 'Qualification / Degree',
                              prefixIcon: Icon(Icons.school_outlined),
                              hintText: 'e.g. M.Sc Clinical Psychology',
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Enter qualification'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _expController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Years of Experience',
                              prefixIcon:
                                  Icon(Icons.workspace_premium_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Enter experience';
                              }
                              final num = int.tryParse(val);
                              if (num == null || num < 0) {
                                return 'Enter valid number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGovtIdType,
                            decoration: const InputDecoration(
                              labelText: 'Government ID Type',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                            items: _govtIdTypes.map((type) {
                              return DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGovtIdType = val);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _govtIdNumberController,
                            decoration: const InputDecoration(
                              labelText: 'Government ID Number',
                              prefixIcon: Icon(Icons.card_membership_outlined),
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Enter Government ID number'
                                    : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
