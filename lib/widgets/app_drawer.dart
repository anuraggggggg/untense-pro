import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/counsellor_provider.dart';

class DrawerMenuItem {
  final String title;
  final IconData icon;
  final String? route;
  final VoidCallback? onTap;

  const DrawerMenuItem({
    required this.title,
    required this.icon,
    this.route,
    this.onTap,
  });
}

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final authProvider = context.watch<AuthProvider>();
    final counsellor = authProvider.counsellor;

    return Drawer(
      backgroundColor: const Color(0xFF071224), // Dark Navy matching screenshot
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header / User Profile Snippet
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFF132448),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.2),
                    child: Text(
                      (counsellor?.fullName.isNotEmpty == true)
                          ? counsellor!.fullName[0].toUpperCase()
                          : 'C',
                      style: const TextStyle(
                        color: Color(0xFF00E5AE),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          counsellor?.fullName.isNotEmpty == true
                              ? counsellor!.fullName
                              : 'UnTense Counsellor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          counsellor?.email ?? 'Pro Member',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8C9BAE),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: Color(0xFF8C9BAE), size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Navigation List Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                children: [
                  _buildDrawerItem(
                    context: context,
                    title: 'Home',
                    icon: Icons.home_outlined,
                    isSelected: currentLocation == '/dashboard',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentLocation != '/dashboard') {
                        context.go('/dashboard');
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Profile',
                    icon: Icons.person_outline_rounded,
                    isSelected: currentLocation == '/profile',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentLocation != '/profile') {
                        context.go('/profile');
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'KYC',
                    icon: Icons.shield_outlined,
                    isSelected: currentLocation == '/kyc',
                    onTap: () {
                      Navigator.pop(context);
                      _showKycDialog(context, counsellor?.verificationStatus.name);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Availability',
                    icon: Icons.schedule_outlined,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _toggleAvailabilitySheet(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Bookings',
                    icon: Icons.calendar_today_outlined,
                    isSelected: currentLocation == '/bookings',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentLocation != '/bookings') {
                        context.go('/bookings');
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Chat History',
                    icon: Icons.chat_bubble_outline_rounded,
                    isSelected: currentLocation == '/chat',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentLocation != '/chat') {
                        context.go('/chat');
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Wallet',
                    icon: Icons.account_balance_wallet_outlined,
                    isSelected: currentLocation == '/wallet',
                    onTap: () {
                      Navigator.pop(context);
                      if (currentLocation != '/wallet') {
                        context.go('/wallet');
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Followers',
                    icon: Icons.people_outline_rounded,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showFollowersSheet(context);
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Reviews',
                    icon: Icons.star_border_rounded,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentLocation != '/profile') {
                        context.go('/profile');
                      }
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    title: 'Notifications',
                    icon: Icons.notifications_none_rounded,
                    isSelected: false,
                    onTap: () {
                      Navigator.pop(context);
                      _showNotificationsSheet(context);
                    },
                  ),
                ],
              ),
            ),

            // Footer / Sign Out Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().signOut();
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF132448).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Colors matching exact screenshot design
    const activeBgColor = Color(0xFF0D3238); // Dark Teal Translucent Container
    const activeAccentColor = Color(0xFF00E5AE); // Vibrant Cyan Mint Accent
    const inactiveColor = Color(0xFF8C9BAE); // Muted Slate Blue Text/Icon

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: activeAccentColor.withValues(alpha: 0.1),
          highlightColor: activeAccentColor.withValues(alpha: 0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? activeBgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? const Border(
                      left: BorderSide(
                        color: activeAccentColor,
                        width: 3.5,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected ? activeAccentColor : inactiveColor,
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? activeAccentColor : inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showKycDialog(BuildContext context, String? status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1B3D),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFF00E5AE)),
            SizedBox(width: 10),
            Text('KYC Verification Status', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status: ${(status ?? "APPROVED").toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF00E5AE),
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your professional credentials and ID verification are active. You are eligible to offer audio, video, and chat consultations.',
              style: TextStyle(color: Color(0xFF8C9BAE), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFF00E5AE))),
          ),
        ],
      ),
    );
  }

  void _toggleAvailabilitySheet(BuildContext context) {
    final counsellor = context.read<AuthProvider>().counsellor;
    final isOnline = counsellor?.isOnline ?? false;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1B3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final counsellorProvider = context.watch<CounsellorProvider>();
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session Availability Setting',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toggle whether clients can see you online and send instant consultation requests.',
                    style: TextStyle(color: Color(0xFF8C9BAE), fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF132448),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: isOnline ? const Color(0xFF10B981) : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              isOnline ? 'Online & Available' : 'Offline / Away',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: isOnline,
                          activeThumbColor: const Color(0xFF00E5AE),
                          activeTrackColor: const Color(0xFF00E5AE).withValues(alpha: 0.3),
                          onChanged: (val) {
                            if (counsellor != null) {
                              counsellorProvider.toggleOnlineStatus(counsellor.uid, val);
                              setModalState(() {});
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFollowersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1B3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline_rounded, size: 48, color: Color(0xFF00E5AE)),
            const SizedBox(height: 12),
            const Text(
              'Your Followers',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '148 clients are following your profile for updates and availability notifications.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF8C9BAE), fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E5AE),
                foregroundColor: const Color(0xFF071224),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1B3D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_none_rounded, color: Color(0xFF00E5AE)),
                SizedBox(width: 10),
                Text('Recent Notifications', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            _buildNotificationTile(
              'New Booking Confirmed',
              'An upcoming session has been scheduled for tomorrow at 4:00 PM.',
              '10m ago',
            ),
            const SizedBox(height: 10),
            _buildNotificationTile(
              'Wallet Credit Received',
              '₹450 credited for completed Audio Call session.',
              '1h ago',
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(String title, String body, String time) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF132448),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF00E5AE)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(body, style: const TextStyle(color: Color(0xFF8C9BAE), fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: const TextStyle(color: Color(0xFF8C9BAE), fontSize: 11)),
        ],
      ),
    );
  }
}
