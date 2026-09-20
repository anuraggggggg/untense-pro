import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/consultation_request_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/counsellor_provider.dart';
import '../../providers/request_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().firebaseUser;
      if (user != null) {
        context.read<RequestProvider>().listenToRequests(user.uid);
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

    final requests = requestProvider.requests;

    final pendingChat = requests
        .where((r) =>
            r.requestType == RequestType.chat &&
            r.status == RequestStatus.pending)
        .toList();
    final pendingAudio = requests
        .where((r) =>
            r.requestType == RequestType.audio &&
            r.status == RequestStatus.pending)
        .toList();
    final pendingVideo = requests
        .where((r) =>
            r.requestType == RequestType.video &&
            r.status == RequestStatus.pending)
        .toList();
    final allPending =
        requests.where((r) => r.status == RequestStatus.pending).toList();

    final isOnline = counsellor?.isOnline ?? false;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
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
            onPressed: () => context.go('/wallet'),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.primaryNavy),
            onPressed: () => context.read<AuthProvider>().signOut(),
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
                      counsellorProvider.toggleOnlineStatus(
                          counsellor.uid, val);
                    }
                  },
                ),
              ],
            ),
          ),

          // Real-time Request Queues Tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primaryNavy,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primaryCyan,
            tabs: [
              Tab(text: 'All (${allPending.length})'),
              Tab(text: 'Chat (${pendingChat.length})'),
              Tab(text: 'Audio (${pendingAudio.length})'),
              Tab(text: 'Video (${pendingVideo.length})'),
            ],
          ),

          // Requests List Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRequestList(allPending),
                _buildRequestList(pendingChat),
                _buildRequestList(pendingAudio),
                _buildRequestList(pendingVideo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<ConsultationRequestModel> requestList) {
    if (requestList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'No active requests in queue',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requestList.length,
      itemBuilder: (context, index) {
        final req = requestList[index];
        return _buildRequestCard(req);
      },
    );
  }

  Widget _buildRequestCard(ConsultationRequestModel request) {
    Color badgeColor;
    IconData iconData;
    String typeLabel;

    switch (request.requestType) {
      case RequestType.audio:
        badgeColor = AppColors.audioCallAccent;
        iconData = Icons.call_outlined;
        typeLabel = 'Audio Call';
        break;
      case RequestType.video:
        badgeColor = AppColors.videoCallAccent;
        iconData = Icons.videocam_outlined;
        typeLabel = 'Video Call';
        break;
      case RequestType.chat:
        badgeColor = AppColors.chatAccent;
        iconData = Icons.chat_bubble_outline;
        typeLabel = 'Text Chat';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        request.clientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Fee: ₹${request.feeAmount.toStringAsFixed(0)} • Requested just now',
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
                    typeLabel,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Accept / Decline Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context
                        .read<RequestProvider>()
                        .declineRequest(request.id),
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Decline',
                        style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final reqProvider = context.read<RequestProvider>();
                      await reqProvider.acceptRequest(request.id);

                      if (!mounted) return;

                      if (request.requestType == RequestType.audio) {
                        context.push('/audio-call', extra: {
                          'channelId': request.channelId,
                          'clientName': request.clientName,
                          'agoraToken': request.agoraToken,
                        });
                      } else if (request.requestType == RequestType.video) {
                        context.push('/video-call', extra: {
                          'channelId': request.channelId,
                          'clientName': request.clientName,
                          'agoraToken': request.agoraToken,
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Accepted Chat request with ${request.clientName}')),
                        );
                      }
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryNavy,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
