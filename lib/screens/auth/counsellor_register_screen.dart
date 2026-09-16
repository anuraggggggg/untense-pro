import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_error_bottom_sheet.dart';

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

  // Step 1: Personal & Account Controllers & FocusNodes
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  // Step 2: OTP Verification Controllers & FocusNodes
  final _emailOtpController = TextEditingController();
  final _phoneOtpController = TextEditingController(text: '0000');

  final _emailOtpFocusNode = FocusNode();

  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _isEmailOtpVerified = false;
  bool _isSubmittingRegistration = false;

  // Step 3: Professional & Govt ID Controllers & FocusNodes
  final _qualificationController = TextEditingController();
  final _expController = TextEditingController(text: '3');
  final _govtIdNumberController = TextEditingController();

  final _qualificationFocusNode = FocusNode();
  final _expFocusNode = FocusNode();
  final _govtIdNumberFocusNode = FocusNode();

  String _selectedGovtIdType = 'AADHAAR';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
    _confirmPasswordController.dispose();

    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();

    _emailOtpController.dispose();
    _phoneOtpController.dispose();
    _emailOtpFocusNode.dispose();

    _qualificationController.dispose();
    _expController.dispose();
    _govtIdNumberController.dispose();

    _qualificationFocusNode.dispose();
    _expFocusNode.dispose();
    _govtIdNumberFocusNode.dispose();

    super.dispose();
  }

  Future<void> _sendEmailOtp() async {
    FocusScope.of(context).unfocus();

    if (!_formKeyStep1.currentState!.validate()) {
      _focusFirstInvalidStep1Field();
      return;
    }

    if (_isSendingOtp) return;

    if (!mounted) return;
    setState(() {
      _isSendingOtp = true;
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final authProvider = context.read<AuthProvider>();
      await authProvider.sendOtp(email, otpFor: 'COUNSELLOR_REGISTRATION');

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _successMessage = 'OTP code sent successfully to $email';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ OTP sent successfully to $email'),
          backgroundColor: AppColors.onlineGreen,
        ),
      );
    } catch (e) {
      final err = e.toString().replaceAll('Exception: ', '').trim();
      if (!mounted) return;
      showAppErrorBottomSheet(
        context,
        title: 'Failed to Send OTP',
        message: err.isNotEmpty
            ? err
            : 'Unable to send OTP at this time. Please check your internet connection and email address.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _submitRegistration() async {
    FocusScope.of(context).unfocus();

    if (!_formKeyStep3.currentState!.validate()) {
      _focusFirstInvalidStep3Field();
      return;
    }

    if (_isSubmittingRegistration) return;

    if (!mounted) return;
    setState(() {
      _isSubmittingRegistration = true;
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
      // Strip spaces from Govt ID number
      final govtIdNumber =
          _govtIdNumberController.text.trim().replaceAll(' ', '');
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
      showAppErrorBottomSheet(
        context,
        title: 'Registration Failed',
        message: err.isNotEmpty
            ? err
            : 'Could not complete your registration. Please verify your OTP code and details.',
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmittingRegistration = false);
      }
    }
  }

  void _onStepContinue() {
    FocusScope.of(context).unfocus();

    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        setState(() => _currentStep += 1);
      } else {
        _focusFirstInvalidStep1Field();
      }
    } else if (_currentStep == 1) {
      final otp = _emailOtpController.text.trim();
      if (otp.length != 6 || int.tryParse(otp) == null) {
        _emailOtpFocusNode.requestFocus();
        showAppErrorBottomSheet(
          context,
          title: 'Invalid OTP',
          message: 'Please enter a valid 6-digit OTP code sent to your email address.',
        );
        return;
      }
      setState(() {
        _isEmailOtpVerified = true;
        _currentStep += 1;
      });
    } else if (_currentStep == 2) {
      _submitRegistration();
    }
  }

  void _onStepCancel() {
    FocusScope.of(context).unfocus();
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  void _focusFirstInvalidStep1Field() {
    if (_fullNameController.text.trim().length < 3) {
      _fullNameFocusNode.requestFocus();
    } else if (_emailController.text.trim().isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text.trim())) {
      _emailFocusNode.requestFocus();
    } else if (_phoneController.text.trim().length < 10) {
      _phoneFocusNode.requestFocus();
    } else if (_passwordController.text.length < 8) {
      _passwordFocusNode.requestFocus();
    } else if (_confirmPasswordController.text != _passwordController.text) {
      _confirmPasswordFocusNode.requestFocus();
    }
  }

  void _focusFirstInvalidStep3Field() {
    if (_qualificationController.text.trim().isEmpty) {
      _qualificationFocusNode.requestFocus();
    } else if (_expController.text.trim().isEmpty ||
        int.tryParse(_expController.text.trim()) == null) {
      _expFocusNode.requestFocus();
    } else if (_govtIdNumberController.text.trim().isEmpty) {
      _govtIdNumberFocusNode.requestFocus();
    }
  }

  String? _validateGovtIdNumber(String? val) {
    if (val == null || val.trim().isEmpty) {
      return 'Please enter your Government ID number.';
    }
    final cleanId = val.trim().replaceAll(' ', '');
    if (_selectedGovtIdType == 'AADHAAR') {
      if (cleanId.length != 12 || int.tryParse(cleanId) == null) {
        return 'Please enter a valid 12-digit Aadhaar number.';
      }
    } else if (_selectedGovtIdType == 'PAN') {
      if (cleanId.length != 10 ||
          !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(cleanId.toUpperCase())) {
        return 'Please enter a valid 10-character PAN number.';
      }
    } else {
      if (cleanId.length < 5) {
        return 'Please enter a valid ID number.';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isBusy = authProvider.isLoading ||
        _isSendingOtp ||
        _isSubmittingRegistration;

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
            // Success Feedback Banner
            if (_successMessage != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                onStepContinue: isBusy ? null : _onStepContinue,
                onStepCancel: isBusy ? null : _onStepCancel,
                controlsBuilder: (context, details) {
                  return Container(
                    margin: const EdgeInsets.only(top: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isBusy ? null : details.onStepContinue,
                            child: isBusy
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
                              onPressed: isBusy ? null : details.onStepCancel,
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            focusNode: _fullNameFocusNode,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Full Name (Dr. / Mr. / Ms.)',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your full name.';
                              }
                              if (val.trim().length < 3) {
                                return 'Name must be at least 3 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            focusNode: _emailFocusNode,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email address.';
                              }
                              final regex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!regex.hasMatch(val.trim())) {
                                return 'Please enter a valid email address.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number (with country code)',
                              prefixIcon: Icon(Icons.phone_outlined),
                              hintText: '+919876543210',
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your phone number.';
                              }
                              final cleanPhone = val.trim().replaceAll(' ', '');
                              if (cleanPhone.length < 10) {
                                return 'Please enter a valid phone number.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              helperText:
                                  'Min 8 chars, uppercase, lowercase, digit & symbol',
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please enter a password.';
                              }
                              if (val.length < 8) {
                                return 'Password must be at least 8 characters.';
                              }
                              final regex = RegExp(
                                  r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
                              if (!regex.hasMatch(val)) {
                                return 'Include uppercase, lowercase, number & symbol.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordFocusNode,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: const Icon(Icons.lock_reset),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (val != _passwordController.text) {
                                return 'Passwords do not match.';
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            icon: _isSendingOtp
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(_otpSent
                                ? 'Resend Email OTP Code'
                                : 'Send Email OTP Code'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _emailOtpController,
                            focusNode: _emailOtpFocusNode,
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
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter the 6-digit Email OTP.';
                              }
                              if (val.trim().length != 6 ||
                                  int.tryParse(val.trim()) == null) {
                                return 'Please enter a valid 6-digit OTP.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _phoneOtpController,
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            decoration: const InputDecoration(
                              labelText: '4-digit Phone OTP',
                              prefixIcon: Icon(Icons.sms_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter Phone OTP.';
                              }
                              if (val.trim().length != 4 ||
                                  int.tryParse(val.trim()) == null) {
                                return 'Please enter a valid 4-digit OTP.';
                              }
                              return null;
                            },
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
                      autovalidateMode: AutovalidateMode.onUserInteraction,
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
                            focusNode: _qualificationFocusNode,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Qualification / Degree',
                              prefixIcon: Icon(Icons.school_outlined),
                              hintText: 'e.g. M.Sc Clinical Psychology',
                            ),
                            validator: (val) =>
                                val == null || val.trim().isEmpty
                                    ? 'Please enter your qualification.'
                                    : null,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _expController,
                            focusNode: _expFocusNode,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Years of Experience',
                              prefixIcon:
                                  Icon(Icons.workspace_premium_outlined),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter years of experience.';
                              }
                              final num = int.tryParse(val.trim());
                              if (num == null || num < 0 || num > 50) {
                                return 'Please enter valid experience (0-50 years).';
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
                            focusNode: _govtIdNumberFocusNode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: 'Government ID Number',
                              prefixIcon:
                                  const Icon(Icons.card_membership_outlined),
                              hintText: _selectedGovtIdType == 'AADHAAR'
                                  ? '12-digit Aadhaar number'
                                  : (_selectedGovtIdType == 'PAN'
                                      ? '10-character PAN number'
                                      : 'ID Number'),
                            ),
                            validator: _validateGovtIdNumber,
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
