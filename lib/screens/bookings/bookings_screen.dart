import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryNavy,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primaryCyan,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpcomingBookings(),
          _buildCompletedBookings(),
          _buildCancelledBookings(),
        ],
      ),
    );
  }

  Widget _buildUpcomingBookings() {
    final upcomingList = [
      {
        'id': 'BK-1001',
        'clientName': 'Ananya Sharma',
        'type': 'Video Call',
        'icon': Icons.videocam_outlined,
        'badgeColor': AppColors.videoCallAccent,
        'date': 'Today, 04:30 PM',
        'duration': '45 mins',
        'fee': '₹500',
        'status': 'Confirmed',
      },
      {
        'id': 'BK-1002',
        'clientName': 'Rohan Mehta',
        'type': 'Audio Call',
        'icon': Icons.call_outlined,
        'badgeColor': AppColors.audioCallAccent,
        'date': 'Tomorrow, 11:00 AM',
        'duration': '30 mins',
        'fee': '₹400',
        'status': 'Confirmed',
      },
      {
        'id': 'BK-1003',
        'clientName': 'Priya Nair',
        'type': 'Text Chat',
        'icon': Icons.chat_bubble_outline,
        'badgeColor': AppColors.chatAccent,
        'date': '22 Sep 2026, 06:00 PM',
        'duration': '60 mins',
        'fee': '₹600',
        'status': 'Scheduled',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingList.length,
      itemBuilder: (context, index) {
        final booking = upcomingList[index];
        return _buildBookingCard(booking, isUpcoming: true);
      },
    );
  }

  Widget _buildCompletedBookings() {
    final completedList = [
      {
        'id': 'BK-0988',
        'clientName': 'Vikram Singh',
        'type': 'Audio Call',
        'icon': Icons.call_outlined,
        'badgeColor': AppColors.audioCallAccent,
        'date': 'Yesterday, 02:00 PM',
        'duration': '45 mins',
        'fee': '₹500',
        'status': 'Completed',
      },
      {
        'id': 'BK-0975',
        'clientName': 'Sneha Kapoor',
        'type': 'Video Call',
        'icon': Icons.videocam_outlined,
        'badgeColor': AppColors.videoCallAccent,
        'date': '18 Sep 2026, 05:15 PM',
        'duration': '45 mins',
        'fee': '₹500',
        'status': 'Completed',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedList.length,
      itemBuilder: (context, index) {
        final booking = completedList[index];
        return _buildBookingCard(booking, isUpcoming: false);
      },
    );
  }

  Widget _buildCancelledBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'No cancelled bookings',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking,
      {required bool isUpcoming}) {
    final Color badgeColor = booking['badgeColor'] as Color;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor.withValues(alpha: 0.12),
                  child: Icon(booking['icon'] as IconData, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['clientName'] as String,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${booking['id']} • ${booking['duration']}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['type'] as String,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 0.8),
            Row(
              children: [
                const Icon(Icons.access_time_rounded,
                    size: 16, color: AppColors.primaryCyan),
                const SizedBox(width: 6),
                Text(
                  booking['date'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  booking['fee'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ],
            ),
            if (isUpcoming) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.borderGrey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Reschedule'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (booking['type'] == 'Video Call') {
                          context.push('/video-call', extra: {
                            'channelId': booking['id'],
                            'clientName': booking['clientName'],
                          });
                        } else if (booking['type'] == 'Audio Call') {
                          context.push('/audio-call', extra: {
                            'channelId': booking['id'],
                            'clientName': booking['clientName'],
                          });
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryCyan,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Start Session'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
