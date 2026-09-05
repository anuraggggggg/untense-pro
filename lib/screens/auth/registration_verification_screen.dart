import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/counsellor_provider.dart';

class RegistrationVerificationScreen extends StatefulWidget {
  const RegistrationVerificationScreen({super.key});

  @override
  State<RegistrationVerificationScreen> createState() =>
      _RegistrationVerificationScreenState();
}

class _RegistrationVerificationScreenState
    extends State<RegistrationVerificationScreen> {
  int _currentStep = 0;

  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _expController = TextEditingController();
  final _bioController = TextEditingController();
  final _upiIdController = TextEditingController();

  final List<String> _selectedSpecializations = [];
  final Map<String, PlatformFile> _pickedDocuments = {};

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().firebaseUser;
    if (user?.email != null) {
      // Pre-fill email if available
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _expController.dispose();
    _bioController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(String docType) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      withData: true, // required for web support
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _pickedDocuments[docType] = result.files.first;
      });
    }
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKeyStep1.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_selectedSpecializations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one specialization.')),
        );
        return;
      }
      if (_formKeyStep2.currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 2) {
      _submitKyc();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitKyc() async {
    final requiredDocs = [
      AppConstants.docAadhaar,
      AppConstants.docPan,
      AppConstants.docMarksheet10,
      AppConstants.docDegree,
    ];

    for (var doc in requiredDocs) {
      if (!_pickedDocuments.containsKey(doc)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please upload all 4 required verification documents.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final authProvider = context.read<AuthProvider>();
    final counsellorProvider = context.read<CounsellorProvider>();
    final user = authProvider.firebaseUser;

    if (user == null) return;

    final success = await counsellorProvider.submitKycRegistration(
      uid: user.uid,
      fullName: _fullNameController.text.trim(),
      email: user.email ?? '',
      phone: _phoneController.text.trim(),
      yearsExperience: int.parse(_expController.text.trim()),
      bio: _bioController.text.trim(),
      specializations: _selectedSpecializations,
      upiId: _upiIdController.text.trim(),
      pickedFiles: _pickedDocuments,
    );

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(counsellorProvider.errorMessage ?? 'KYC submission failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final counsellorProvider = context.watch<CounsellorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counsellor Verification & KYC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: counsellorProvider.isSubmitting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primaryTeal),
                  const SizedBox(height: 16),
                  const Text('Uploading documents & submitting KYC verification...'),
                ],
              ),
            )
          : Stepper(
              type: StepperType.horizontal,
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          child: Text(_currentStep == 2 ? 'Submit KYC' : 'Next Step'),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: details.onStepCancel,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Back'),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                // STEP 1: Basic Information
                Step(
                  title: const Text('Basic Info'),
                  isActive: _currentStep >= 0,
                  state: _currentStep > 0 ? StepState.complete : StepState.editing,
                  content: Form(
                    key: _formKeyStep1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Personal & Professional Info',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullNameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (val) => val == null || val.isEmpty
                              ? 'Enter full name'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          validator: (val) => val == null || val.length < 10
                              ? 'Enter valid 10-digit phone number'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _expController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Years of Experience',
                            prefixIcon: Icon(Icons.work_history_outlined),
                          ),
                          validator: (val) => val == null || int.tryParse(val) == null
                              ? 'Enter valid years of experience'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Professional Summary / Bio',
                            alignLabelWithHint: true,
                          ),
                          validator: (val) => val == null || val.length < 20
                              ? 'Bio must be at least 20 characters long'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP 2: Specializations & UPI ID
                Step(
                  title: const Text('Specialties'),
                  isActive: _currentStep >= 1,
                  state: _currentStep > 1 ? StepState.complete : StepState.editing,
                  content: Form(
                    key: _formKeyStep2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Specializations',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose areas where you specialize as a counsellor.',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.specializations.map((spec) {
                            final isSelected = _selectedSpecializations.contains(spec);
                            return FilterChip(
                              label: Text(spec),
                              selected: isSelected,
                              selectedColor: AppColors.mintBg,
                              checkmarkColor: AppColors.primaryTeal,
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryTeal
                                    : AppColors.textPrimary,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedSpecializations.add(spec);
                                  } else {
                                    _selectedSpecializations.remove(spec);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Payout Details (UPI)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _upiIdController,
                          decoration: const InputDecoration(
                            labelText: 'UPI ID for Session Earnings (e.g. name@upi)',
                            prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                          ),
                          validator: (val) => val == null || !val.contains('@')
                              ? 'Enter valid UPI ID'
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),

                // STEP 3: Document Uploads
                Step(
                  title: const Text('Documents'),
                  isActive: _currentStep >= 2,
                  state: _currentStep == 2 ? StepState.editing : StepState.complete,
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Verification Documents',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Clear scans/photos of official documents are required for KYC approval.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 16),

                      _buildDocTile(
                        title: 'Aadhaar Card',
                        subtitle: 'Front/Back scan or PDF',
                        docType: AppConstants.docAadhaar,
                        icon: Icons.badge_outlined,
                      ),
                      _buildDocTile(
                        title: 'PAN Card',
                        subtitle: 'Identity verification card',
                        docType: AppConstants.docPan,
                        icon: Icons.credit_card_outlined,
                      ),
                      _buildDocTile(
                        title: 'Class 10 (X) Marksheet',
                        subtitle: 'Date of Birth proof',
                        docType: AppConstants.docMarksheet10,
                        icon: Icons.school_outlined,
                      ),
                      _buildDocTile(
                        title: 'Professional Degree / License',
                        subtitle: 'Psychology / Counselling Certificate',
                        docType: AppConstants.docDegree,
                        icon: Icons.workspace_premium_outlined,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDocTile({
    required String title,
    required String subtitle,
    required String docType,
    required IconData icon,
  }) {
    final picked = _pickedDocuments[docType];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: picked != null ? AppColors.mintBg : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: picked != null ? AppColors.primaryTealLight : AppColors.borderGrey,
          width: picked != null ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                picked != null ? AppColors.primaryTeal : Colors.grey[100],
            child: Icon(
              picked != null ? Icons.check : icon,
              color: picked != null ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  picked != null ? picked.name : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: picked != null ? AppColors.primaryTeal : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _pickFile(docType),
            icon: Icon(picked != null ? Icons.refresh : Icons.upload_file, size: 18),
            label: Text(picked != null ? 'Change' : 'Upload'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(100, 38),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ],
      ),
    );
  }
}
