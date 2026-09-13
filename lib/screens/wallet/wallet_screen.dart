import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/transaction_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().firebaseUser;
      if (user != null) {
        context.read<WalletProvider>().listenToTransactions(user.uid);
      }
    });
  }

  void _showWithdrawModal(
      BuildContext context, double currentBalance, String defaultUpi) {
    final amountController = TextEditingController();
    final upiController = TextEditingController(text: defaultUpi);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Withdraw to UPI',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryNavy,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Available Balance: ₹${currentBalance.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Withdrawal Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Enter amount';
                    }
                    final amt = double.tryParse(val);
                    if (amt == null || amt <= 0) {
                      return 'Enter valid amount';
                    }
                    if (amt > currentBalance) {
                      return 'Exceeds available balance';
                    }
                    return null;
                  },

                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: upiController,
                  decoration: const InputDecoration(
                    labelText: 'UPI ID',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                  ),
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Enter valid UPI ID'
                      : null,
                ),
                const SizedBox(height: 24),
                Consumer<WalletProvider>(
                  builder: (context, walletProvider, _) {
                    return ElevatedButton(
                      onPressed: walletProvider.isRequestingPayout
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              final user =
                                  context.read<AuthProvider>().firebaseUser;
                              if (user == null) return;

                              final amt =
                                  double.parse(amountController.text.trim());
                              final upi = upiController.text.trim();

                              final success =
                                  await walletProvider.withdrawToUpi(
                                counsellorId: user.uid,
                                amount: amt,
                                upiId: upi,
                              );

                              if (ctx.mounted) {
                                Navigator.pop(ctx);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Payout request submitted successfully!'),
                                      backgroundColor: AppColors.onlineGreen,
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        walletProvider.errorMessage ??
                                            'Withdrawal failed',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: walletProvider.isRequestingPayout
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Confirm Withdrawal'),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final counsellor = authProvider.counsellor;
    final walletProvider = context.watch<WalletProvider>();

    final totalBalance = counsellor?.totalBalance ?? 0.0;
    final lifetimeEarnings = counsellor?.lifetimeEarnings ?? 0.0;
    final pendingPayouts = counsellor?.pendingPayouts ?? 0.0;
    final defaultUpi = counsellor?.upiId ?? '';

    final transactions = walletProvider.transactions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings & Wallet'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Available Balance Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryTeal, AppColors.primaryTealLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryTeal.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: totalBalance > 0
                          ? () => _showWithdrawModal(
                              context, totalBalance, defaultUpi)
                          : null,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Withdraw to UPI'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Metrics Cards Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Lifetime Earnings',
                    amount: lifetimeEarnings,
                    color: AppColors.onlineGreen,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Pending Payouts',
                    amount: pendingPayouts,
                    color: AppColors.pendingYellow,
                    icon: Icons.hourglass_empty,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Transaction History Header
            Text(
              'Transaction History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            if (walletProvider.isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child:
                      CircularProgressIndicator(color: AppColors.primaryTeal),
                ),
              )
            else if (transactions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'No transactions recorded yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final tx = transactions[index];
                  return _buildTransactionTile(tx);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(TransactionModel tx) {
    final isPayout = tx.type == TransactionType.payout;
    final color = isPayout ? Colors.orange[800] : AppColors.onlineGreen;
    final icon = isPayout ? Icons.south_west : Icons.north_east;
    final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(tx.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color?.withValues(alpha: 0.12),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          tx.description.isNotEmpty
              ? tx.description
              : (isPayout ? 'UPI Payout Withdrawal' : 'Session Fee Earning'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          formattedDate,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isPayout ? "-" : "+"}₹${tx.amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isPayout ? Colors.red : AppColors.onlineGreen,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: tx.status == TransactionStatus.completed
                    ? Colors.green[50]
                    : tx.status == TransactionStatus.pending
                        ? Colors.amber[50]
                        : Colors.red[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tx.status.name.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: tx.status == TransactionStatus.completed
                      ? Colors.green[800]
                      : tx.status == TransactionStatus.pending
                          ? Colors.amber[900]
                          : Colors.red[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
