import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/app_drawer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/counsellor_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/auth_api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthApiService _apiService = AuthApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final tabs = ['All', 'Chat', 'Audio', 'Video'];
        debugPrint(
            '📊 [DashboardScreen] Switched tab to index ${_tabController.index} (${tabs[_tabController.index]})');
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      final user = authProvider.firebaseUser;
      debugPrint('🚀 [DashboardScreen] Initialized. Firebase User: ${user?.uid}');
      if (user != null) {
        debugPrint('📡 [DashboardScreen] Subscribing to Firestore requests for UID: ${user.uid}');
        context.read<RequestProvider>().listenToRequests(user.uid);
      }
      final token = authProvider.token;
      debugPrint('🔑 [DashboardScreen] API Token present: ${token != null && token.isNotEmpty}');
      if (token != null && token.isNotEmpty) {
        debugPrint('🔄 [DashboardScreen] Fetching initial API bookings...');
        context.read<RequestProvider>().fetchApiBookings(token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final counsellor = authProvider.counsellor;
    final counsellorProvider = context.watch<CounsellorProvider>();
    final requestProvider = context.watch<RequestProvider>();
    final token = authProvider.token;

    final apiBookings = requestProvider.apiBookings;
    final apiChat = requestProvider.apiChatBookings;
    final apiAudio = requestProvider.apiAudioBookings;
    final apiVideo = requestProvider.apiVideoBookings;

    final isOnline = counsellor?.isOnline ?? false;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        titleSpacing: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryNavy, size: 26),
            tooltip: 'Open Menu',
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'assets/transparent_ic.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dr. ${counsellor?.fullName ?? "Counsellor"}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy),
                  ),
                  Text(
                    isOnline
                        ? 'Online • Ready for Sessions'
                        : 'Offline • Unavailable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isOnline
                          ? AppColors.onlineGreen
                          : AppColors.offlineGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: AppColors.primaryNavy),
            tooltip: 'Wallet & Earnings',
            onPressed: () {
              debugPrint('👛 [DashboardScreen] Wallet button tapped -> Navigating to /wallet');
              context.go('/wallet');
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryNavy),
            tooltip: 'Sign Out',
            onPressed: () {
              debugPrint('🚪 [DashboardScreen] Sign Out button tapped -> Signing out');
              context.read<AuthProvider>().signOut();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Availability Toggle Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: isOnline ? AppColors.mintBg : AppColors.backgroundLight,
              border: Border(
                bottom: BorderSide(
                  color: isOnline ? AppColors.accentMint : AppColors.borderGrey,
                  width: 1,
                ),
              ),
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
                        color: isOnline
                            ? AppColors.onlineGreen
                            : AppColors.offlineGrey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Session Availability',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isOnline
                            ? AppColors.primaryNavy
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isOnline,
                  activeThumbColor: AppColors.primaryCyan,
                  activeTrackColor:
                      AppColors.primaryCyan.withValues(alpha: 0.3),
                  onChanged: (val) {
                    if (counsellor != null) {
                      debugPrint(
                          '⚡ [DashboardScreen] Toggling online status for UID ${counsellor.uid} -> $val');
                      counsellorProvider.toggleOnlineStatus(
                          counsellor.uid, val);
                    } else {
                      debugPrint(
                          '⚠️ [DashboardScreen] Cannot toggle online status: counsellor is null');
                    }
                  },
                ),
              ],
            ),
          ),

          // Request Queues Tabs (Powered by GET /api/v1/bookings)
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryNavy,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryCyan,
            tabs: [
              Tab(text: 'All (${apiBookings.length})'),
              Tab(text: 'Chat (${apiChat.length})'),
              Tab(text: 'Audio (${apiAudio.length})'),
              Tab(text: 'Video (${apiVideo.length})'),
            ],
          ),

          // Requests List Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildApiBookingList(apiBookings, requestProvider, token),
                _buildApiBookingList(apiChat, requestProvider, token),
                _buildApiBookingList(apiAudio, requestProvider, token),
                _buildApiBookingList(apiVideo, requestProvider, token),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiBookingList(
      List<Map<String, dynamic>> bookingList,
      RequestProvider requestProvider,
      String? token) {
    if (requestProvider.isApiLoading && bookingList.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryNavy),
      );
    }

    if (requestProvider.apiError != null && bookingList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
              const SizedBox(height: 12),
              const Text(
                'Failed to load bookings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                requestProvider.apiError!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  if (token != null) {
                    debugPrint('🔄 [DashboardScreen] Retrying fetchApiBookings...');
                    requestProvider.fetchApiBookings(token);
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (bookingList.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          debugPrint('🔄 [DashboardScreen] Manual pull-to-refresh triggered (empty list)');
          if (token != null) {
            await requestProvider.fetchApiBookings(token);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Refreshed: ${requestProvider.apiBookings.length} booking request(s) found'),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 12),
                    Text(
                      'No booking requests in queue',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pull down to refresh',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🔄 [DashboardScreen] Manual pull-to-refresh triggered (${bookingList.length} items)');
        if (token != null) {
          await requestProvider.fetchApiBookings(token);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Refreshed: ${requestProvider.apiBookings.length} booking request(s) found'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookingList.length,
        itemBuilder: (context, index) {
          final booking = bookingList[index];
          return _buildApiBookingCard(booking, token);
        },
      ),
    );
  }

  Widget _buildApiBookingCard(Map<String, dynamic> booking, String? token) {
    final mode = (booking['consultationMode'] ?? 'CHAT').toString().toUpperCase();
    final status = (booking['status'] ?? 'PENDING').toString().toUpperCase();

    Color badgeColor;
    IconData iconData;
    String modeLabel;

    switch (mode) {
      case 'AUDIO':
        badgeColor = AppColors.audioCallAccent;
        iconData = Icons.call_outlined;
        modeLabel = 'Audio Call';
        break;
      case 'VIDEO':
        badgeColor = AppColors.videoCallAccent;
        iconData = Icons.videocam_outlined;
        modeLabel = 'Video Call';
        break;
      case 'CHAT':
      default:
        badgeColor = AppColors.chatAccent;
        iconData = Icons.chat_bubble_outline;
        modeLabel = 'Text Chat';
        break;
    }

    final categoryName = booking['category'] is Map
        ? (booking['category']['name'] ?? 'General Consultation')
        : 'General Consultation';
    final bookingType = (booking['bookingType'] ?? 'INSTANT').toString();
    final priceAmount = booking['priceAmount'] is num
        ? (booking['priceAmount'] as num) / 100.0
        : 0.0;
    final scheduledTimeStr = _formatDateTime(
        booking['scheduledStartAt'] ?? booking['createdAt']);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (kDebugMode) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  '🐛 [DEBUG] ID: ${booking['id'] ?? 'N/A'} | Status: $status | Mode: $mode',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ],
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: badgeColor.withValues(alpha: 0.15),
                  child: Icon(iconData, color: badgeColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Fee: ₹${priceAmount.toStringAsFixed(0)} • Type: $bookingType',
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
                    modeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      scheduledTimeStr,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
                _buildStatusBadge(status),
              ],
            ),
            if (status == 'CONFIRMED' || status == 'IN_PROGRESS' || status == 'ACCEPTED') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (token == null) {
                      debugPrint('⚠️ [DashboardScreen] Cannot join session: auth token is null');
                      return;
                    }
                    final bookingId = booking['id'];
                    debugPrint('📞 [DashboardScreen] Attempting to join session for bookingId: $bookingId (Mode: $mode)');
                    try {
                      final res = await _apiService.joinConsultation(
                        token: token,
                        bookingId: bookingId,
                      );
                      debugPrint('✅ [DashboardScreen] joinConsultation response: $res');
                      final channelId =
                          res['channelId'] ?? res['channelName'] ?? bookingId;
                      final agoraToken = res['token'] ?? res['agoraToken'];

                      if (!mounted) return;

                      if (mode == 'AUDIO') {
                        debugPrint('🔀 [DashboardScreen] Pushing to /audio-call with channelId: $channelId');
                        context.push('/audio-call', extra: {
                          'channelId': channelId,
                          'clientName': 'Client ($categoryName)',
                          'agoraToken': agoraToken,
                        });
                      } else if (mode == 'VIDEO') {
                        debugPrint('🔀 [DashboardScreen] Pushing to /video-call with channelId: $channelId');
                        context.push('/video-call', extra: {
                          'channelId': channelId,
                          'clientName': 'Client ($categoryName)',
                          'agoraToken': agoraToken,
                        });
                      } else {
                        debugPrint('🔀 [DashboardScreen] Navigating to /chat');
                        context.go('/chat');
                      }
                    } catch (e, stackTrace) {
                      debugPrint('❌ [DashboardScreen] Error joining session for booking $bookingId: $e');
                      debugPrint('📌 [DashboardScreen] StackTrace:\n$stackTrace');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to join session: $e'),
                          backgroundColor: Colors.red.shade700,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.video_call_rounded),
                  label: const Text('Join Session Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor = const Color(0xFFEFF8FF);
    Color textColor = AppColors.primaryCyan;
    String label = status;

    if (status == 'COMPLETED') {
      bgColor = AppColors.mintBg;
      textColor = AppColors.onlineGreen;
      label = 'Completed';
    } else if (status == 'CONFIRMED') {
      bgColor = const Color(0xFFEFF8FF);
      textColor = AppColors.primaryCyan;
      label = 'Confirmed';
    } else if (status == 'IN_PROGRESS') {
      bgColor = const Color(0xFFFEF2F2);
      textColor = AppColors.rejectedRed;
      label = 'In Progress';
    } else if (status == 'PENDING_PAYMENT' || status == 'PENDING') {
      bgColor = const Color(0xFFFFFBEB);
      textColor = AppColors.pendingYellow;
      label = 'Pending Payment';
    } else if (status.startsWith('CANCELLED')) {
      bgColor = const Color(0xFFFEF2F2);
      textColor = AppColors.rejectedRed;
      label = 'Cancelled';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoString;
    }
  }
}
