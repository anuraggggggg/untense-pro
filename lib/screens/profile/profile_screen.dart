import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/counsellor_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_api_service.dart';
import '../../widgets/app_shimmer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthApiService _apiService = AuthApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final categoriesData = await _apiService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categoriesData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final counsellor = authProvider.counsellor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Counsellor Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryNavy),
            tooltip: 'Reload Profile & Categories',
            onPressed: _loadProfileData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: AppColors.primaryCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? _buildShimmerProfileLoading()
              : counsellor == null
                  ? _buildNoProfileFound()
                  : Column(
                      children: [
                        // Dynamic Profile Header Card
                        _buildDynamicHeaderCard(counsellor),
                        const SizedBox(height: 16),

                        // Dynamic Financial & Performance Metrics
                        _buildDynamicMetricsGrid(counsellor),
                        const SizedBox(height: 20),

                        // Dynamic KYC & Documents Status Section
                        _buildDynamicKycSection(counsellor),
                        const SizedBox(height: 20),

                        // Dynamic Categories & Specialisations Section (Loaded via API)
                        _buildDynamicCategoriesSection(counsellor),
                        const SizedBox(height: 20),

                        // Dynamic Availability & Account Info Section
                        _buildDynamicAccountDetails(counsellor),
                        const SizedBox(height: 24),

                        // Sign Out Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => authProvider.signOut(),
                            icon: const Icon(Icons.logout_rounded,
                                color: Colors.white),
                            label: const Text(
                              'Sign Out',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rejectedRed,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
        ),
      ),
    );
  }

  /// Dynamic Header Card driven by CounsellorModel API response
  Widget _buildDynamicHeaderCard(CounsellorModel counsellor) {
    final String name = counsellor.fullName.isNotEmpty
        ? counsellor.fullName
        : (counsellor.email.isNotEmpty ? counsellor.email : 'Counsellor');
    final String email = counsellor.email;
    final String phone = counsellor.phone;
    final String qualification = counsellor.qualification;
    final String bio = counsellor.bio;
    final bool isVerified = counsellor.isVerified;
    final String? avatarUrl = counsellor.avatarUrl;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primaryNavy,
                backgroundImage:
                    avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.onlineGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            name.startsWith('Dr.') ? name : 'Dr. $name',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          if (qualification.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              qualification,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 8),

          // Email & Phone
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (email.isNotEmpty) ...[
                Icon(Icons.email_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
              if (phone.isNotEmpty) ...[
                const SizedBox(width: 10),
                Icon(Icons.phone_outlined, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(
                  phone,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ],
          ),

          // Dynamic Bio
          if (bio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bio,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // Dynamic Hourly Rate & Verification Status Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryNavy.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Fee: ${counsellor.currency} ${counsellor.hourlyRateAmount.toStringAsFixed(0)} / session',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isVerified
                      ? AppColors.mintBg
                      : AppColors.pendingYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.accentMint
                        : AppColors.pendingYellow,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVerified
                          ? Icons.verified_user_rounded
                          : Icons.hourglass_empty_rounded,
                      size: 14,
                      color: isVerified
                          ? AppColors.onlineGreen
                          : AppColors.pendingYellow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'KYC: ${counsellor.kycStatus}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isVerified
                            ? AppColors.primaryNavy
                            : AppColors.pendingYellow,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Dynamic Metrics grid driven by real counsellor earnings & ratings
  Widget _buildDynamicMetricsGrid(CounsellorModel counsellor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryNavy.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTile(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                value: counsellor.rating.toStringAsFixed(1),
                subtext: '${counsellor.ratingCount} reviews',
                label: 'Rating',
              ),
              _buildMetricDivider(),
              _buildMetricTile(
                icon: Icons.work_history_outlined,
                iconColor: AppColors.accentMint,
                value: '${counsellor.yearsExperience}',
                subtext: 'Years',
                label: 'Experience',
              ),
              _buildMetricDivider(),
              _buildMetricTile(
                icon: Icons.account_balance_wallet_outlined,
                iconColor: AppColors.primaryCyan,
                value: '₹${counsellor.totalBalance.toStringAsFixed(0)}',
                subtext: 'Available',
                label: 'Balance',
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24, thickness: 0.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                'Lifetime Earnings: ₹${counsellor.lifetimeEarnings.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                'Pending Payouts: ₹${counsellor.pendingPayouts.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String subtext,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtext,
          style: const TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white24,
    );
  }

  /// Dynamic KYC & Documents Card
  Widget _buildDynamicKycSection(CounsellorModel counsellor) {
    final docs = counsellor.documents;
    final kycStatus = counsellor.kycStatus;
    final rejectionReason = counsellor.rejectionReason;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_outlined,
                  color: AppColors.primaryNavy, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'KYC & Document Verification',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kycStatus == 'APPROVED'
                      ? AppColors.onlineGreen.withValues(alpha: 0.12)
                      : (kycStatus == 'REJECTED'
                          ? AppColors.rejectedRed.withValues(alpha: 0.12)
                          : AppColors.pendingYellow.withValues(alpha: 0.12)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kycStatus,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: kycStatus == 'APPROVED'
                        ? AppColors.onlineGreen
                        : (kycStatus == 'REJECTED'
                            ? AppColors.rejectedRed
                            : AppColors.pendingYellow),
                  ),
                ),
              ),
            ],
          ),
          if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.rejectedRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.rejectedRed, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection Reason: $rejectionReason',
                      style: const TextStyle(
                          color: AppColors.rejectedRed, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Uploaded Documents List from API model
          if (docs.isEmpty)
            Text(
              'No KYC documents uploaded yet.',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: docs.entries.map((entry) {
                final docName = entry.key.replaceAll('_', ' ').toUpperCase();
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.file_present_rounded,
                          size: 14, color: AppColors.primaryCyan),
                      const SizedBox(width: 6),
                      Text(
                        docName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  /// Dynamic Categories & Specialisations Section loaded via API
  Widget _buildDynamicCategoriesSection(CounsellorModel counsellor) {
    final List<String> counsellorSpecs = counsellor.specializations;

    if (_categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: Row(
          children: [
            const Icon(Icons.category_outlined, color: AppColors.primaryCyan),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Fetching backend categories...',
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_outlined,
                  color: AppColors.primaryCyan, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Specialisations & Categories',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_categories.length} Categories',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _categories.length,
            separatorBuilder: (context, index) =>
                const Divider(height: 20, thickness: 0.8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final String catName = cat['name'] ?? 'Category';
              final String catDesc = cat['description'] ?? '';
              final List specs = cat['specialisations'] is List
                  ? cat['specialisations'] as List
                  : [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryCyan,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        catName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  if (catDesc.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Text(
                        catDesc,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),

                  if (specs.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: specs.map((s) {
                          final specName = s['name']?.toString() ?? '';
                          final bool isSelected = counsellorSpecs.any(
                              (cs) => cs.toLowerCase() == specName.toLowerCase());

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.mintBg
                                  : AppColors.backgroundLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentMint
                                    : AppColors.borderGrey,
                                width: isSelected ? 1.2 : 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(Icons.check_circle_rounded,
                                      size: 13, color: AppColors.onlineGreen),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  specName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? AppColors.primaryNavy
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Dynamic Account & Schedule Details Card
  Widget _buildDynamicAccountDetails(CounsellorModel counsellor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account & Schedule Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.language_rounded,
            label: 'Timezone',
            value: counsellor.timezone,
          ),
          const Divider(height: 16, thickness: 0.6),
          _buildInfoRow(
            icon: Icons.payment_rounded,
            label: 'UPI Payout ID',
            value: counsellor.upiId.isNotEmpty ? counsellor.upiId : 'Not configured',
          ),
          const Divider(height: 16, thickness: 0.6),
          _buildInfoRow(
            icon: Icons.toggle_on_rounded,
            label: 'Online Status',
            value: counsellor.isOnline ? 'Online • Ready for Sessions' : 'Offline',
            valueColor: counsellor.isOnline ? AppColors.onlineGreen : AppColors.offlineGrey,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryNavy),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppColors.primaryNavy,
          ),
        ),
      ],
    );
  }

  Widget _buildNoProfileFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.person_off_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No counsellor profile data available.',
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProfileData,
              child: const Text('Reload Profile'),
            ),
          ],
        ),
      ),
    );
  }

  /// Shimmer loading layout for profile data & categories
  Widget _buildShimmerProfileLoading() {
    return AppShimmer(
      isLoading: true,
      child: Column(
        children: [
          // Header Card Shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              children: const [
                ShimmerCircle(radius: 42),
                SizedBox(height: 14),
                ShimmerBox(width: 160, height: 18),
                SizedBox(height: 8),
                ShimmerBox(width: 220, height: 14),
                SizedBox(height: 8),
                ShimmerBox(width: 180, height: 12),
                SizedBox(height: 16),
                ShimmerBox(width: 200, height: 28, borderRadius: 20),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Metrics Shimmer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                ShimmerBox(width: 60, height: 24),
                ShimmerBox(width: 60, height: 24),
                ShimmerBox(width: 60, height: 24),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Categories Card Shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                ShimmerBox(width: 240, height: 20),
                SizedBox(height: 16),
                ShimmerBox(width: 120, height: 16),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 36, borderRadius: 18),
                SizedBox(height: 16),
                ShimmerBox(width: 140, height: 16),
                SizedBox(height: 8),
                ShimmerBox(width: double.infinity, height: 36, borderRadius: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
