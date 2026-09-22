import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_api_service.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/app_drawer.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final AuthApiService _apiService = AuthApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _bookings = [];
  String _selectedStatusKey = 'ALL';

  final Map<String, String> _statusOptions = {
    'ALL': 'All statuses',
    'PENDING_PAYMENT': 'Pending Payment',
    'CONFIRMED': 'Confirmed',
    'IN_PROGRESS': 'In Progress',
    'COMPLETED': 'Completed',
    'CANCELLED_BY_CUSTOMER': 'Cancelled By Customer',
    'CANCELLED_BY_COUNSELLOR': 'Cancelled By Counsellor',
    'RESCHEDULED': 'Rescheduled',
    'NO_SHOW_CUSTOMER': 'No Show Customer',
    'NO_SHOW_COUNSELLOR': 'No Show Counsellor',
  };

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('jwt_auth_token');
      }

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication token missing. Please log in again.';
        });
        return;
      }

      final data = await _apiService.getCounsellorBookings(
        token: token,
        status: _selectedStatusKey != 'ALL' ? _selectedStatusKey : null,
      );

      setState(() {
        _bookings = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('🐛 [BookingsScreen Error] $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load bookings: $e';
      });
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null || isoString.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt).toLowerCase();
    } catch (_) {
      return isoString;
    }
  }

  String _formatPrice(dynamic amount, String? currency) {
    if (amount == null) return '₹0.00';
    num val = 0;
    if (amount is num) {
      val = amount;
    } else {
      val = num.tryParse(amount.toString()) ?? 0;
    }
    final inRupees = val / 100.0;
    final symbol = (currency == 'INR' || currency == null) ? '₹' : currency;
    return '$symbol${inRupees.toStringAsFixed(2)}';
  }

  Widget _buildStatusBadge(String? status) {
    final s = (status ?? 'PENDING').toUpperCase();

    Color bgColor = const Color(0xFFEFF8FF);
    Color textColor = AppColors.primaryCyan;
    Color borderColor = AppColors.primaryCyan.withValues(alpha: 0.2);
    IconData icon = Icons.info_outline;
    String label = _statusOptions[s] ?? s;

    if (s == 'COMPLETED') {
      bgColor = AppColors.mintBg;
      textColor = AppColors.onlineGreen;
      borderColor = AppColors.accentMint.withValues(alpha: 0.5);
      icon = Icons.check_circle_outline;
      label = 'Completed';
    } else if (s == 'CONFIRMED') {
      bgColor = const Color(0xFFEFF8FF);
      textColor = AppColors.primaryCyan;
      borderColor = AppColors.primaryCyan.withValues(alpha: 0.3);
      icon = Icons.check_circle_outline;
      label = 'Confirmed';
    } else if (s == 'IN_PROGRESS') {
      bgColor = const Color(0xFFFEF2F2);
      textColor = AppColors.rejectedRed;
      borderColor = AppColors.rejectedRed.withValues(alpha: 0.3);
      icon = Icons.play_circle_outline;
      label = 'In Progress';
    } else if (s == 'PENDING_PAYMENT') {
      bgColor = const Color(0xFFFFFBEB);
      textColor = AppColors.pendingYellow;
      borderColor = AppColors.pendingYellow.withValues(alpha: 0.3);
      icon = Icons.access_time;
      label = 'Pending Payment';
    } else if (s.startsWith('CANCELLED')) {
      bgColor = const Color(0xFFFEF2F2);
      textColor = AppColors.rejectedRed;
      borderColor = AppColors.rejectedRed.withValues(alpha: 0.3);
      icon = Icons.cancel_outlined;
      label = s == 'CANCELLED_BY_CUSTOMER'
          ? 'Cancelled By Customer'
          : 'Cancelled By Counsellor';
    } else if (s == 'RESCHEDULED') {
      bgColor = const Color(0xFFF4F3FF);
      textColor = AppColors.audioCallAccent;
      borderColor = AppColors.audioCallAccent.withValues(alpha: 0.3);
      icon = Icons.sync_rounded;
      label = 'Rescheduled';
    } else if (s.startsWith('NO_SHOW')) {
      bgColor = AppColors.backgroundLight;
      textColor = AppColors.textSecondary;
      borderColor = AppColors.borderGrey;
      icon = Icons.person_off_outlined;
      label = s == 'NO_SHOW_CUSTOMER' ? 'No Show Customer' : 'No Show Counsellor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDetailsModal(BuildContext context, Map<String, dynamic> bookingSummary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BookingDetailsSheet(
        bookingSummary: bookingSummary,
        apiService: _apiService,
        formatDateTime: _formatDateTime,
        formatPrice: _formatPrice,
        buildStatusBadge: _buildStatusBadge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredBookings = _selectedStatusKey == 'ALL'
        ? _bookings
        : _bookings.where((b) => (b['status']?.toString().toUpperCase() ?? '') == _selectedStatusKey).toList();

    return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded, color: AppColors.primaryNavy, size: 26),
            tooltip: 'Open Menu',
            onPressed: () {
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        title: const Row(
          children: [
            Icon(Icons.event_note_outlined, color: AppColors.primaryNavy, size: 24),
            SizedBox(width: 8),
            Text(
              'Bookings',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryCyan.withValues(alpha: 0.3)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatusKey,
                    icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primaryCyan, size: 20),
                    style: const TextStyle(
                      color: AppColors.primaryNavy,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != _selectedStatusKey) {
                        setState(() {
                          _selectedStatusKey = newValue;
                        });
                        _fetchBookings();
                      }
                    },
                    items: _statusOptions.entries.map<DropdownMenuItem<String>>((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBookings,
        color: AppColors.primaryCyan,
        child: _isLoading
            ? ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderGrey),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppShimmer(child: ShimmerBox(width: 120, height: 18, borderRadius: 4)),
                          AppShimmer(child: ShimmerBox(width: 100, height: 24, borderRadius: 12)),
                        ],
                      ),
                      SizedBox(height: 8),
                      AppShimmer(child: ShimmerBox(width: 160, height: 14, borderRadius: 4)),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          AppShimmer(child: ShimmerBox(width: 60, height: 16, borderRadius: 4)),
                          SizedBox(width: 12),
                          AppShimmer(child: ShimmerBox(width: 60, height: 16, borderRadius: 4)),
                          Spacer(),
                          AppShimmer(child: ShimmerBox(width: 70, height: 32, borderRadius: 8)),
                        ],
                      ),
                    ],
                  ),
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.rejectedRed),
                          const SizedBox(height: 12),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _fetchBookings,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryNavy,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : filteredBookings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy_outlined, size: 64, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text(
                              'No bookings found',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBookings.length,
                        itemBuilder: (context, index) {
                          final booking = filteredBookings[index];
                          final categoryName = booking['category']?['name']?.toString() ?? 'General';
                          final scheduledStart = booking['scheduledStartAt']?.toString();
                          final formattedStart = _formatDateTime(scheduledStart);
                          final mode = (booking['consultationMode']?.toString() ?? 'AUDIO').toUpperCase();
                          final isVideo = mode == 'VIDEO';
                          final priceStr = _formatPrice(booking['priceAmount'], booking['currency']?.toString());
                          final status = booking['status']?.toString();

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderGrey),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  categoryName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryNavy,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formattedStart,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      isVideo ? Icons.videocam_outlined : Icons.call_outlined,
                                      size: 16,
                                      color: isVideo ? AppColors.videoCallAccent : AppColors.audioCallAccent,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isVideo ? 'Video' : 'Audio',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: isVideo ? AppColors.videoCallAccent : AppColors.audioCallAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      priceStr,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryNavy,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    _buildStatusBadge(status),
                                    const Spacer(),
                                    InkWell(
                                      onTap: () => _showBookingDetailsModal(context, booking),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.mintBg,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: AppColors.accentMint.withValues(alpha: 0.5)),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'View',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primaryNavy,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Icon(Icons.chevron_right, size: 16, color: AppColors.primaryCyan),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}

class _BookingDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> bookingSummary;
  final AuthApiService apiService;
  final String Function(String?) formatDateTime;
  final String Function(dynamic, String?) formatPrice;
  final Widget Function(String?) buildStatusBadge;

  const _BookingDetailsSheet({
    required this.bookingSummary,
    required this.apiService,
    required this.formatDateTime,
    required this.formatPrice,
    required this.buildStatusBadge,
  });

  @override
  State<_BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<_BookingDetailsSheet> {
  bool _loadingDetails = true;
  Map<String, dynamic>? _fullDetails;

  @override
  void initState() {
    super.initState();
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    final bookingId = widget.bookingSummary['id']?.toString();
    if (bookingId == null || bookingId.isEmpty) {
      setState(() {
        _fullDetails = widget.bookingSummary;
        _loadingDetails = false;
      });
      return;
    }

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      String? token = authProvider.token;
      if (token == null || token.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        token = prefs.getString('jwt_auth_token');
      }

      if (token != null && token.isNotEmpty) {
        final details = await widget.apiService.getBookingDetails(
          token: token,
          bookingId: bookingId,
        );
        if (mounted && details.isNotEmpty) {
          setState(() {
            _fullDetails = details;
            _loadingDetails = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('🐛 [BookingDetails Error] $e');
    }

    if (mounted) {
      setState(() {
        _fullDetails = widget.bookingSummary;
        _loadingDetails = false;
      });
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = _fullDetails ?? widget.bookingSummary;
    final bookingId = b['id']?.toString() ?? '';
    final categoryName = b['category']?['name']?.toString() ?? 'Career';
    final counsellorName = b['counsellor']?['displayName']?.toString() ?? 'N/A';
    final customerName = b['customer']?['displayName']?.toString() ?? 'N/A';
    final mode = (b['consultationMode']?.toString() ?? 'AUDIO').toUpperCase();
    final modeText = mode == 'VIDEO' ? 'Video' : 'Audio';

    final startStr = widget.formatDateTime(b['scheduledStartAt']?.toString());
    final endStr = widget.formatDateTime(b['scheduledEndAt']?.toString());
    final scheduledWindow = '$startStr → $endStr';

    final priceStr = widget.formatPrice(b['priceAmount'], b['currency']?.toString());
    final status = b['status']?.toString();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.dividerGrey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.event_note_outlined, color: AppColors.primaryNavy, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Booking #$bookingId',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryNavy,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              widget.buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),
          if (_loadingDetails)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primaryCyan),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGrey),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Category', categoryName),
                  const Divider(height: 1, color: AppColors.borderGrey),
                  _buildDetailRow('Counsellor', counsellorName),
                  const Divider(height: 1, color: AppColors.borderGrey),
                  _buildDetailRow('Customer', customerName),
                  const Divider(height: 1, color: AppColors.borderGrey),
                  _buildDetailRow('Mode', modeText),
                  const Divider(height: 1, color: AppColors.borderGrey),
                  _buildDetailRow('Scheduled', scheduledWindow),
                  const Divider(height: 1, color: AppColors.borderGrey),
                  _buildDetailRow('Price', priceStr),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
