import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../widgets/app_shimmer.dart';
import '../../widgets/app_drawer.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _fetchWalletData() async {
    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    
    String? token = authProvider.token;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('jwt_auth_token');
    }

    if (token != null && token.isNotEmpty) {
      await walletProvider.fetchWalletAndTransactions(token);
    } else {
      await walletProvider.fetchWalletAndTransactions('');
    }
  }

  Future<void> _handleApplyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;

    final authProvider = context.read<AuthProvider>();
    final walletProvider = context.read<WalletProvider>();
    final token = authProvider.token;

    if (token != null && token.isNotEmpty) {
      final success = await walletProvider.applyCoupon(token: token, code: code);
      if (!mounted) return;
      if (success) {
        _couponController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coupon applied successfully!'),
            backgroundColor: AppColors.onlineGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(walletProvider.errorMessage ?? 'Failed to apply coupon'),
            backgroundColor: AppColors.rejectedRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletProvider = context.watch<WalletProvider>();

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
            Icon(Icons.account_balance_wallet_outlined, color: AppColors.primaryNavy, size: 24),
            SizedBox(width: 8),
            Text(
              'Wallet & Earnings',
              style: TextStyle(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.primaryCyan),
            tooltip: 'Reload Wallet',
            onPressed: _fetchWalletData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchWalletData,
        color: AppColors.primaryCyan,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: walletProvider.isLoading
              ? _buildShimmerWalletLoading()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Balance Card
                    _buildBalanceCard(walletProvider),
                    const SizedBox(height: 14),

                    // Information Banner
                    _buildInformationBanner(),
                    const SizedBox(height: 20),

                    // Apply Coupon Card
                    _buildCouponCard(walletProvider),
                    const SizedBox(height: 24),

                    // Recent Transactions Title
                    const Text(
                      'Recent transactions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Transactions List
                    _buildTransactionsList(walletProvider),
                    const SizedBox(height: 24),
                  ],
                ),
        ),
      ),
    );
  }

  /// Top Balance Card using AppColors theme
  Widget _buildBalanceCard(WalletProvider walletProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.primaryCyan,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Wallet balance',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${walletProvider.balanceCredits} credits',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Information Banner themed with AppColors.mintBg
  Widget _buildInformationBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mintBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accentMint.withValues(alpha: 0.5)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.primaryCyan,
            size: 20,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Sessions you complete credit this wallet automatically, net of the platform\'s commission — see "Session earning" entries below. There\'s nothing to top up or send here; a customer paying for a booking (or an admin adjustment) is the only thing that adds credits to this wallet.',
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Apply Coupon Card themed with AppColors
  Widget _buildCouponCard(WalletProvider walletProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
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
          const Row(
            children: [
              Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.primaryNavy,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Apply a coupon',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Coupon code',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 46,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.borderGrey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primaryCyan),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: walletProvider.isApplyingCoupon ? null : _handleApplyCoupon,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryNavy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 46),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: walletProvider.isApplyingCoupon
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Apply',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Recent Transactions list themed with AppColors
  Widget _buildTransactionsList(WalletProvider walletProvider) {
    final transactions = walletProvider.transactions;

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderGrey),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: AppColors.textSecondary,
            ),
            SizedBox(height: 12),
            Text(
              'No wallet transactions found',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        return _buildTransactionCard(tx);
      },
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final String typeRaw = tx['type']?.toString() ?? 'TRANSACTION';
    final String typeLabel = typeRaw.replaceAll('_', ' ').toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    final String status = tx['status']?.toString().toUpperCase() ?? 'SUCCESS';
    final num credits = tx['creditsAmount'] ?? 0;
    final String description = tx['description']?.toString() ?? '';
    final String rawCreatedAt = tx['createdAt']?.toString() ?? '';

    String formattedDate = '';
    if (rawCreatedAt.isNotEmpty) {
      try {
        final dateTime = DateTime.parse(rawCreatedAt).toLocal();
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
      } catch (_) {
        formattedDate = rawCreatedAt;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
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
              // Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentMint.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: AppColors.onlineGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      typeLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mintBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 13,
                      color: AppColors.onlineGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toLowerCase().split(' ').map((w) => w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : '').join(' '),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onlineGreen,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Amount Credits
              Text(
                '$credits credits',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Formatted Date
          if (formattedDate.isNotEmpty)
            Text(
              formattedDate,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

          // Description
          if (description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shimmer loading layout matching Wallet AppColors
  Widget _buildShimmerWalletLoading() {
    return AppShimmer(
      isLoading: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card Shimmer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: const Row(
              children: [
                ShimmerCircle(radius: 26),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: 100, height: 14),
                    SizedBox(height: 8),
                    ShimmerBox(width: 140, height: 24),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Information Banner Shimmer
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.mintBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const SizedBox(
              width: double.infinity,
              height: 50,
              child: ShimmerBox(width: 300, height: 50),
            ),
          ),
          const SizedBox(height: 20),

          // Coupon Card Shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.borderGrey),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerBox(width: 140, height: 18),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ShimmerBox(width: 300, height: 42, borderRadius: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Transactions Shimmer
          const ShimmerBox(width: 180, height: 20),
          const SizedBox(height: 12),

          Container(
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
                    ShimmerBox(width: 140, height: 22, borderRadius: 16),
                    ShimmerBox(width: 80, height: 20),
                  ],
                ),
                SizedBox(height: 10),
                ShimmerBox(width: 160, height: 12),
                SizedBox(height: 6),
                ShimmerBox(width: 240, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
