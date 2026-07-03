import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletData;
  List<dynamic> _transactions = [];
  bool _isLoading = true;
  String? _error;
  String _filter = 'All'; // 'All', 'Credits', 'Debits'

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final response = await ApiService().getWalletData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _walletData = data;
            _transactions = data['transactions'] as List<dynamic>? ?? [];
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load wallet data';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Wallet Error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch wallet data';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        title: Text('My Wallet', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
              child: Text(
                'Instant payouts after pickup. Withdraw to UPI or Bank Accounts seamlessly.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final available = _walletData?['availableBalance'] ?? 0;
    final locked = _walletData?['lockedBalance'] ?? 0;
    // The screenshot shows 300, which is the available balance or total. We'll use total.
    final total = (available is num ? available : 0) + (locked is num ? locked : 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'TOTAL BALANCE',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹$total',
                      style: const TextStyle(
                        color: Color(0xFF047857),
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildBalancePill(
                          title: 'AVAILABLE',
                          amount: '₹$available',
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF10B981),
                          bgColor: const Color(0xFFECFDF5),
                        ),
                        _buildBalancePill(
                          title: 'LOCKED (PENDING CLEARANCE)',
                          amount: '₹$locked',
                          icon: Icons.lock_outline_rounded,
                          color: const Color(0xFF6B7280),
                          bgColor: const Color(0xFFF9FAFB),
                        ),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.vertical_align_bottom_rounded, size: 16),
                      label: const Text('Withdraw Balance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Clearance takes 1-3 days after item verification.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          // Transaction History Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Credits'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Debits'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Transaction List
          ..._buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isActive = _filter == label;
    return GestureDetector(
      onTap: () {
        setState(() => _filter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBalancePill({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(amount, style: TextStyle(fontSize: 13, color: color == const Color(0xFF6B7280) ? AppColors.textPrimary : color, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTransactionList() {
    final filtered = _transactions.where((t) {
      if (_filter == 'Credits') return t['type'] == 'credit';
      if (_filter == 'Debits') return t['type'] == 'debit';
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text('No transactions found.', style: TextStyle(color: AppColors.textSecondary)),
          ),
        )
      ];
    }

    return filtered.map((t) {
      final isCredit = t['type'] == 'credit';
      final title = t['item'] ?? 'Transaction';
      final sku = t['sku'] ?? '';
      final date = _formatDate(t['createdAt']);
      final amount = t['amount']?.toString() ?? '0';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isCredit ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
                color: isCredit ? const Color(0xFF10B981) : Colors.red,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sku.isNotEmpty ? '$sku  ·  $date' : date,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : '-'} ₹$amount',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: isCredit ? const Color(0xFF10B981) : Colors.red,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Completed',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }
}
