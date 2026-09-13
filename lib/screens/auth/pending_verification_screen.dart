import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/counsellor_model.dart';
import '../../providers/auth_provider.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final counsellor = authProvider.counsellor;
    final isRejected =
        counsellor?.verificationStatus == VerificationStatus.rejected;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: isRejected ? Colors.red[50] : AppColors.mintBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isRejected
                        ? AppColors.rejectedRed
                        : AppColors.pendingYellow,
                    width: 3,
                  ),
                ),
                child: Icon(
                  isRejected
                      ? Icons.gavel_outlined
                      : Icons.hourglass_top_outlined,
                  size: 52,
                  color: isRejected
                      ? AppColors.rejectedRed
                      : AppColors.pendingYellow,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isRejected
                    ? 'KYC Verification Rejected'
                    : 'Verification Pending Approval',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isRejected
                          ? AppColors.rejectedRed
                          : AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                isRejected
                    ? (counsellor?.rejectionReason ??
                        'Your uploaded documents could not be verified by our administrative team. Please contact support or re-submit updated documents.')
                    : 'Thank you for submitting your KYC verification details and credentials. Our clinical administration team is currently reviewing your documents.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatusRow(
                      context,
                      label: 'Applicant Name',
                      value: counsellor?.fullName ?? 'N/A',
                    ),
                    const Divider(height: 20),
                    _buildStatusRow(
                      context,
                      label: 'Documents Uploaded',
                      value: '${counsellor?.documents.length ?? 0} files',
                    ),
                    const Divider(height: 20),
                    _buildStatusRow(
                      context,
                      label: 'Current Status',
                      valueWidget: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color:
                              isRejected ? Colors.red[100] : Colors.amber[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isRejected ? 'REJECTED' : 'PENDING REVIEW',
                          style: TextStyle(
                            color: isRejected
                                ? Colors.red[800]
                                : Colors.amber[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.read<AuthProvider>().signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign Out'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    required String label,
    String? value,
    Widget? valueWidget,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        if (valueWidget != null)
          valueWidget
        else
          Text(
            value ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
      ],
    );
  }
}
