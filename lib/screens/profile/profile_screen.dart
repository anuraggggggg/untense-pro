import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final counsellor = authProvider.counsellor;

    final String name = counsellor?.fullName ?? 'Counsellor';
    final String email = counsellor?.email ?? '';
    final String phone = counsellor?.phone ?? '';
    final String qualification = counsellor?.qualification.isNotEmpty == true
        ? counsellor!.qualification
        : 'Certified Mental Health Counsellor';
    final bool isVerified = counsellor?.isVerified ?? true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primaryNavy),
            tooltip: 'Edit Profile',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit Profile coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Header Card
            Container(
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
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : 'C',
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
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
                    'Dr. $name',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    qualification,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined,
                          size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        email.isNotEmpty ? email : 'No email provided',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.phone_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Verification Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          size: 16,
                          color: isVerified
                              ? AppColors.onlineGreen
                              : AppColors.pendingYellow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isVerified
                              ? 'Verified Counsellor (KYC Approved)'
                              : 'KYC Verification Pending',
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
            ),
            const SizedBox(height: 16),

            // Performance Metrics Strip
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    value: (counsellor?.rating ?? 5.0).toStringAsFixed(1),
                    label: 'Rating',
                  ),
                  _buildMetricDivider(),
                  _buildMetricItem(
                    icon: Icons.work_history_outlined,
                    iconColor: AppColors.accentMint,
                    value: '${counsellor?.yearsExperience ?? 0} Yrs',
                    label: 'Experience',
                  ),
                  _buildMetricDivider(),
                  _buildMetricItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: AppColors.primaryCyan,
                    value: '₹${(counsellor?.totalBalance ?? 0.0).toStringAsFixed(0)}',
                    label: 'Balance',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile Actions List (Derived from Navigation items)
            Container(
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
                children: [
                  _buildMenuItem(
                    icon: Icons.home_outlined,
                    title: 'Home',
                    subtitle: 'Dashboard & live queues',
                    onTap: () => context.go('/dashboard'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile Info',
                    subtitle: 'Bio, qualification & skills',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.verified_user_outlined,
                    title: 'KYC & Verification',
                    subtitle: 'Govt ID & professional documents',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.event_available_outlined,
                    title: 'Session Availability',
                    subtitle: 'Manage daily working slots',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.calendar_month_outlined,
                    title: 'Bookings',
                    subtitle: 'Upcoming & past sessions',
                    onTap: () => context.go('/bookings'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Wallet & Payouts',
                    subtitle: 'Earnings & bank details',
                    onTap: () => context.go('/wallet'),
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.group_outlined,
                    title: 'Followers',
                    subtitle: 'Client network & followers',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Reviews & Feedback',
                    subtitle: 'Client ratings & feedback',
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'Push alerts & reminder settings',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => authProvider.signOut(),
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required Color iconColor,
    required String value,
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
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white24,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primaryNavy, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textSecondary,
        size: 20,
      ),
    );
  }
}
