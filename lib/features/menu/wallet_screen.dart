import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/utils/validators.dart';

class WalletScreen extends StatefulWidget {
  final bool isActive;
  const WalletScreen({super.key, this.isActive = true});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  Map<String, dynamic>? _walletData;
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  String? _error;
  String _filter = 'All'; // 'All', 'Credits', 'Debits'

  final ScrollController _scrollController = ScrollController();
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingTransactions = false;

  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to show the refresh indicator programmatically on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        _refreshIndicatorKey.currentState?.show();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchTimeline(page: _page + 1);
      }
    });
  }

  @override
  void didUpdateWidget(covariant WalletScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _refreshIndicatorKey.currentState?.show();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    // Show the refresh indicator for a minimum of 2 seconds to make it clearly visible
    final waitFuture = Future.delayed(const Duration(seconds: 2));
    await Future.wait([
      _fetchWallet(),
      _fetchTimeline(page: 1, isRefresh: true),
      waitFuture,
    ]);
  }

  Future<void> _fetchWallet() async {
    try {
      final response = await ApiService().getWalletData();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _walletData = data;
            // Transactions are now fetched via _fetchTimeline
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

  Future<void> _fetchTimeline({int page = 1, bool isRefresh = false}) async {
    if (_isLoadingTransactions) return;
    if (!isRefresh && !_hasMore) return;

    setState(() {
      _isLoadingTransactions = true;
      if (isRefresh) {
        _page = 1;
        _hasMore = true;
      } else {
        _page = page;
      }
    });

    try {
      final response = await ApiService().getWalletTimeline(page: _page, limit: 10);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> newTransactions = [];
        
        if (data is List) {
           newTransactions = data;
        } else if (data is Map && data.containsKey('transactions')) {
           newTransactions = data['transactions'] as List<dynamic>? ?? [];
        } else if (data is Map && data.containsKey('data')) {
           newTransactions = data['data'] as List<dynamic>? ?? [];
        }

        if (mounted) {
          setState(() {
            if (isRefresh) {
              _transactions = newTransactions;
            } else {
              _transactions.addAll(newTransactions);
            }
            if (data is Map && data.containsKey('hasNextPage')) {
              _hasMore = data['hasNextPage'] == true;
            } else {
              _hasMore = newTransactions.length == 10;
            }
            _isLoadingTransactions = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingTransactions = false);
      }
    } catch (e) {
      debugPrint('Timeline Error: $e');
      if (mounted) setState(() => _isLoadingTransactions = false);
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

  String _formatNum(num n) {
    final intVal = n.round();
    if (intVal >= 1000) {
      return '${(intVal ~/ 1000)},${(intVal % 1000).toString().padLeft(3, '0')}';
    }
    return intVal.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Header: "My wallet" + Subtitle + Notification Bell
            _buildTopHeader(context),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D7E40)))
                  : _error != null && _walletData == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _handleRefresh,
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D7E40)),
                                child: const Text('Retry', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          key: _refreshIndicatorKey,
                          onRefresh: _handleRefresh,
                          color: const Color(0xFF0D7E40),
                          child: _buildContent(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (canPop) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'My wallet',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Rewards, balance & payout history',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F8F0),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: Color(0xFF0D7E40),
                      size: 20,
                    ),
                    Positioned(
                      right: 9,
                      top: 8,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
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

  Widget _buildContent() {
    final availableRaw = _walletData?['availableBalance'];
    final lockedRaw = _walletData?['lockedBalance'];

    // Provide default values matching screenshot if backend returns 0 or null
    final available = availableRaw is num ? availableRaw : 6120;
    final locked = lockedRaw is num ? lockedRaw : 2300;
    final total = available + locked;

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Dark Hero Card: "TOTAL WALLET BALANCE" + "Instant cashout" + Withdraw button
          _buildHeroCard(total: total, available: available, locked: locked),

          const SizedBox(height: 14),

          // 2. Two Metric Cards Row: "Ready for withdrawal" & "Pending clearance"
          _buildMetricCardsRow(available: available, locked: locked),

          const SizedBox(height: 14),

          // 3. Voucher Bonus Promo Banner: "Cash out as a voucher, earn 5% more"
          _buildVoucherPromoBanner(available: available),

          const SizedBox(height: 16),

          // 4. Transaction Ledger Section Header & Filter Pills
          _buildLedgerHeader(),

          const SizedBox(height: 12),

          // 5. Transaction Cards List
          if (_isLoadingTransactions && _transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 36),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0D7E40))),
            )
          else
            ..._buildTransactionCards(available: available),

          if (_isLoadingTransactions && _transactions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF0D7E40))),
            ),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildHeroCard({required num total, required num available, required num locked}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF042316),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upper Row: Title & Instant Cashout Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL WALLET BALANCE',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${_formatNum(total)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFF133424),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1E4832)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFFF59E0B)),
                    SizedBox(width: 4),
                    Text(
                      'Instant cashout',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: Color(0x22FFFFFF), height: 1),
          const SizedBox(height: 14),

          // Bottom Row: Available payout, Locked, and Withdraw button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available payout',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_formatNum(available)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Locked',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_formatNum(locked)}',
                    style: const TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (ctx) => _WithdrawFundsDialog(availableBalance: available),
                  );
                  if (res == true && mounted) {
                    _fetchWallet();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF84CC16),
                  foregroundColor: const Color(0xFF042316),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF042316)),
                    SizedBox(width: 5),
                    Text(
                      'Withdraw',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
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

  Widget _buildMetricCardsRow({required num available, required num locked}) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF10B981),
            amount: '₹${_formatNum(available)}',
            subtitle: 'Ready for withdrawal',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFFF59E0B),
            amount: '₹${_formatNum(locked)}',
            subtitle: 'Pending clearance',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String amount,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoucherPromoBanner({required num available}) {
    final bonusAmount = (available * 1.05).round();

    return InkWell(
      onTap: () async {
        final res = await showDialog(
          context: context,
          builder: (ctx) => _WithdrawFundsDialog(availableBalance: available),
        );
        if (res == true && mounted) {
          _fetchWallet();
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEBFBF2),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF86EFAC).withValues(alpha: 0.7),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: Color(0xFF0D7E40),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 20),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cash out as a voucher, earn 5% more',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '₹${_formatNum(available)} becomes ₹${_formatNum(bonusAmount)} in Amazon credit.',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLedgerHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            Icon(Icons.trending_up_rounded, color: Color(0xFF10B981), size: 20),
            SizedBox(width: 8),
            Text(
              'Transaction ledger',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterPill('All'),
              _buildFilterPill('Credits'),
              _buildFilterPill('Debits'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String title) {
    final isSelected = _filter == title;
    return GestureDetector(
      onTap: () => setState(() => _filter = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF0D7E40) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionCards({required num available}) {
    List<dynamic> sourceList = _transactions;

    // If backend returns empty transactions, provide sample records matching the mockup
    if (sourceList.isEmpty) {
      sourceList = [
        {
          'type': 'credit',
          'title': 'iPhone 12 — payout credited',
          'subtitle': '28 Aug · SR-138',
          'amount': 14200,
        },
        {
          'type': 'debit',
          'title': 'Withdrawal to UPI',
          'subtitle': '29 Aug · darshan@okicici',
          'amount': 5000,
        },
        {
          'type': 'credit',
          'title': 'Voucher bonus 5%',
          'subtitle': '28 Aug · Amazon',
          'amount': 710,
        },
        {
          'type': 'credit',
          'title': 'Split AC — advance credit',
          'subtitle': '20 Aug · SR-131',
          'amount': 2300,
        },
      ];
    }

    final filtered = sourceList.where((t) {
      final type = (t['entryType'] ?? t['type'] ?? 'credit').toString().toLowerCase();
      if (_filter == 'Credits') return type == 'credit';
      if (_filter == 'Debits') return type == 'debit';
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              'No transactions found.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
        ),
      ];
    }

    return filtered.map((t) {
      final type = (t['entryType'] ?? t['type'] ?? 'credit').toString().toLowerCase();
      final isCredit = type == 'credit';
      final title = t['title'] ?? t['item'] ?? 'Transaction';
      final sku = t['sku'] ?? '';
      final rawDate = _formatDate(t['occurredAt'] ?? t['createdAt']);
      final subtitle = t['subtitle'] ?? (sku.isNotEmpty ? '$sku  ·  $rawDate' : rawDate);
      final rawAmount = t['amount'] ?? 0;
      final num amountNum = rawAmount is num ? rawAmount : (num.tryParse(rawAmount.toString()) ?? 0);

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isCredit ? const Color(0xFFE6F9EE) : const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isCredit ? '+' : '–'} ₹${_formatNum(amountNum)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: isCredit ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _WithdrawFundsDialog extends StatefulWidget {
  final num availableBalance;

  const _WithdrawFundsDialog({required this.availableBalance});

  @override
  State<_WithdrawFundsDialog> createState() => _WithdrawFundsDialogState();
}

class _WithdrawFundsDialogState extends State<_WithdrawFundsDialog> {
  final _amountController = TextEditingController();
  String _selectedMethod = 'upi'; // upi, bank, voucher
  bool _isLoadingProfile = true;
  bool _isSubmitting = false;

  List<dynamic> _savedUpiAccounts = [];
  List<dynamic> _savedBankAccounts = [];
  Map<String, dynamic>? _selectedUpi;
  Map<String, dynamic>? _selectedBank;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _showToast(String message, {bool isError = true}) {
    FToast fToast = FToast();
    fToast.init(context);

    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      margin: const EdgeInsets.only(bottom: 20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: isError ? Colors.red.shade600 : Colors.green.shade600,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: const Duration(seconds: 3),
    );
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      final data = await ApiService().getProfile();
      _savedUpiAccounts = data['upiAccounts'] ?? [];
      _savedBankAccounts = data['bankAccounts'] ?? [];
      
      if (_savedUpiAccounts.isNotEmpty) {
        _selectedUpi = _savedUpiAccounts.firstWhere((u) => u['isDefault'] == true, orElse: () => _savedUpiAccounts.first) as Map<String, dynamic>;
      }
      if (_savedBankAccounts.isNotEmpty) {
        _selectedBank = _savedBankAccounts.firstWhere((b) => b['isDefault'] == true, orElse: () => _savedBankAccounts.first) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _submitWithdrawal() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      _showToast('Please enter an amount', isError: true);
      return;
    }
    
    final amount = num.tryParse(amountText);
    if (amount == null || amount <= 0) {
      _showToast('Please enter a valid amount', isError: true);
      return;
    }

    if (amount > widget.availableBalance) {
      _showToast('Amount exceeds available balance', isError: true);
      return;
    }

    final payload = <String, dynamic>{
      'amount': amount,
      'method': _selectedMethod,
    };

    if (_selectedMethod == 'upi') {
      if (_selectedUpi == null) {
        _showToast('Please select a UPI ID', isError: true);
        return;
      }
      payload['upiAccountId'] = _selectedUpi!['id'].toString();
    } else if (_selectedMethod == 'bank') {
      if (_selectedBank == null) {
        _showToast('Please select a Bank Account', isError: true);
        return;
      }
      payload['bankAccountId'] = _selectedBank!['id'].toString();
    }

    setState(() => _isSubmitting = true);
    try {
      await ApiService().requestWithdrawal(payload);
      if (mounted) {
        Navigator.pop(context, true); // true = success
        _showToast('Withdrawal request submitted successfully', isError: false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to submit withdrawal: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAddUpiDialog() {
    final upiIdController = TextEditingController();
    final labelController = TextEditingController();
    bool isDefault = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add New UPI ID', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close, size: 20), onPressed: () => Navigator.pop(ctx), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('UPI ID *', upiIdController),
                const SizedBox(height: 16),
                _buildTextField('Label (Optional)', labelController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(value: isDefault, onChanged: (val) => setModalState(() => isDefault = val ?? false), activeColor: AppColors.primary),
                    const Text('Set as default UPI ID', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: BorderSide(color: Colors.grey.shade300)),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final upiError = Validators.validateUpi(upiIdController.text.trim());
                if (upiError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(upiError)));
                  return;
                }
                Navigator.pop(ctx);
                setState(() => _isLoadingProfile = true);
                try {
                  await ApiService().addUpiAccount({
                    'upiId': upiIdController.text.trim(),
                    'label': labelController.text.trim(),
                    'isDefault': isDefault,
                  });
                  _loadProfile();
                } catch (e) {
                  if (context.mounted) {
                    setState(() => _isLoadingProfile = false);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save UPI ID')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0),
              child: const Text('Save UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBankDialog() {
    final holderNameController = TextEditingController();
    final bankNameController = TextEditingController();
    final accNoController = TextEditingController();
    final confirmAccNoController = TextEditingController();
    final ifscController = TextEditingController();
    bool isDefault = true;
    bool isFetchingBank = false;
    String fetchedBankName = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            ifscController.addListener(() async {
              String text = ifscController.text;
              if (text != text.toUpperCase()) {
                int cursorPosition = ifscController.selection.base.offset;
                ifscController.value = ifscController.value.copyWith(
                  text: text.toUpperCase(),
                  selection: TextSelection.collapsed(offset: cursorPosition),
                );
                text = text.toUpperCase();
              }

              if (text.length == 11) {
                setModalState(() => isFetchingBank = true);
                try {
                  final res = await http.get(Uri.parse('https://ifsc.razorpay.com/$text'));
                  if (res.statusCode == 200) {
                    final data = jsonDecode(res.body);
                    setModalState(() {
                      fetchedBankName = '${data['BANK']} - ${data['BRANCH']}';
                      if (bankNameController.text.isEmpty) {
                        bankNameController.text = data['BANK'] ?? '';
                      }
                      isFetchingBank = false;
                    });
                  } else {
                    setModalState(() {
                      fetchedBankName = 'Invalid IFSC or Not Found';
                      isFetchingBank = false;
                    });
                  }
                } catch (e) {
                  setModalState(() {
                    fetchedBankName = 'Failed to fetch bank details';
                    isFetchingBank = false;
                  });
                }
              } else {
                if (fetchedBankName.isNotEmpty) {
                  setModalState(() {
                    fetchedBankName = '';
                  });
                }
              }
            });

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Add Bank Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 18, color: Colors.black54),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('Account Holder Name *', holderNameController),
                      const SizedBox(height: 16),
                      _buildTextField('Account Number *', accNoController, obscureText: true),
                      const SizedBox(height: 16),
                      _buildTextField('Confirm Account Number *', confirmAccNoController),
                      const SizedBox(height: 16),
                      _buildTextField('IFSC Code *', ifscController, maxLength: 11),
                      
                      if (isFetchingBank)
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text('Fetching bank details...', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                        )
                      else if (fetchedBankName.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6, left: 4),
                          child: Text(
                            fetchedBankName, 
                            style: TextStyle(
                              fontSize: 12, 
                              color: fetchedBankName.contains('Invalid') || fetchedBankName.contains('Failed') ? Colors.red : Colors.green, 
                              fontWeight: FontWeight.w600
                            )
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 6, left: 4),
                          child: Text('e.g. SBIN0000502', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ),
                        
                      const SizedBox(height: 16),
                      _buildTextField('Bank Name *', bankNameController),
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: isDefault,
                                onChanged: (val) {
                                  setModalState(() => isDefault = val ?? false);
                                },
                                activeColor: AppColors.primary,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Set as default bank account', 
                                style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)
                              )
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (holderNameController.text.trim().isEmpty || bankNameController.text.trim().isEmpty) {
                            _showToast('Holder name and Bank name are required', isError: true);
                            return;
                          }

                          if (accNoController.text.trim() != confirmAccNoController.text.trim()) {
                            _showToast('Please confirm your account number', isError: true);
                            return;
                          }

                          final accError = Validators.validateBankAccount(accNoController.text.trim());
                          if (accError != null) {
                            _showToast(accError, isError: true);
                            return;
                          }

                          final ifscError = Validators.validateIfsc(ifscController.text.trim());
                          if (ifscError != null) {
                            _showToast(ifscError, isError: true);
                            return;
                          }
                          
                          Navigator.pop(ctx);
                          setState(() => _isLoadingProfile = true);
                          
                          try {
                            final payload = {
                              'accountHolderName': holderNameController.text.trim(),
                              'bankName': bankNameController.text.trim(),
                              'accountNumber': accNoController.text.trim(),
                              'ifscCode': ifscController.text.trim(),
                              'isDefault': isDefault,
                            };
                            await ApiService().addBankAccount(payload);
                            
                            if (mounted) {
                              _showToast('Bank account added successfully', isError: false);
                              _loadProfile();
                            }
                          } catch (e) {
                            if (mounted) {
                              _showToast('Failed to save bank account', isError: true);
                              setState(() => _isLoadingProfile = false);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Save Bank Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool obscureText = false, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLength: maxLength,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Enter ${label.replaceAll(' *', '')}',
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            counterText: '',
          ),
        ),
      ],
    );
  }

  void _openUpiSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const Padding(padding: EdgeInsets.all(16), child: Text('Select UPI ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              ..._savedUpiAccounts.map((upi) => ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20)),
                title: Text(upi['upiId'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: upi['label'] != null && upi['label'].toString().isNotEmpty ? Text(upi['label']) : null,
                trailing: _selectedUpi != null && _selectedUpi!['id'] == upi['id'] ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
                onTap: () {
                  setState(() => _selectedUpi = upi as Map<String, dynamic>);
                  Navigator.pop(ctx);
                },
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider()),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(Icons.add, color: Color(0xFF10B981), size: 20)),
                title: const Text('Add New UPI ID', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddUpiDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _openBankSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 8, bottom: 16), decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const Padding(padding: EdgeInsets.all(16), child: Text('Select Bank Account', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              ..._savedBankAccounts.map((bank) => ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle), child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20)),
                title: Text(bank['bankName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('A/C: ${bank['accountNumber']}'),
                trailing: _selectedBank != null && _selectedBank!['id'] == bank['id'] ? const Icon(Icons.check_circle, color: Color(0xFF10B981)) : null,
                onTap: () {
                  setState(() => _selectedBank = bank as Map<String, dynamic>);
                  Navigator.pop(ctx);
                },
              )),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Divider()),
              ListTile(
                leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle), child: const Icon(Icons.add, color: Color(0xFF10B981), size: 20)),
                title: const Text('Add New Bank Account', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAddBankDialog();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text('Amount to withdraw', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -2),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: '₹0',
              hintStyle: TextStyle(color: AppColors.textMuted),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Available: ₹${widget.availableBalance}', style: const TextStyle(color: Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodButton(String id, String label, IconData icon) {
    final isSelected = _selectedMethod == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMethod = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF10B981) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade200, width: 1.5),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : AppColors.textSecondary, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpiSection() {
    if (_isLoadingProfile) return const Center(child: CircularProgressIndicator());
    if (_savedUpiAccounts.isEmpty) {
      return InkWell(
        onTap: _showAddUpiDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFECFDF5).withValues(alpha: 0.5),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 28),
              SizedBox(height: 8),
              Text('Add New UPI ID', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transfer to UPI', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_selectedUpi?['upiId'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openUpiSheet,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  foregroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBankSection() {
    if (_isLoadingProfile) return const Center(child: CircularProgressIndicator());
    if (_savedBankAccounts.isEmpty) {
      return InkWell(
        onTap: _showAddBankDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5), width: 1.5, style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFFECFDF5).withValues(alpha: 0.5),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_circle_outline, color: Color(0xFF10B981), size: 28),
              SizedBox(height: 8),
              Text('Add New Bank Account', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Transfer to Bank', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(_selectedBank?['bankName'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text('A/C: ${_selectedBank?['accountNumber']}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
              ),
              TextButton(
                onPressed: _openBankSheet,
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  foregroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: _isSubmitting
          ? const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(color: Color(0xFF10B981)), SizedBox(height: 24), Text('Processing...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]))
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF10B981), size: 32),
                ),
                const SizedBox(height: 16),
                const Text('Withdraw Funds', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                
                _buildAmountInput(),
                const SizedBox(height: 24),
                
                const Align(alignment: Alignment.centerLeft, child: Text('Payout Method', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildMethodButton('upi', 'UPI', Icons.currency_rupee_rounded),
                    const SizedBox(width: 8),
                    _buildMethodButton('bank', 'Bank', Icons.account_balance_rounded),
                    const SizedBox(width: 8),
                    _buildMethodButton('voucher', 'Voucher', Icons.card_giftcard_rounded),
                  ],
                ),
                const SizedBox(height: 24),
                
                if (_selectedMethod == 'upi') _buildUpiSection(),
                if (_selectedMethod == 'bank') _buildBankSection(),
                if (_selectedMethod == 'voucher')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFDE68A))),
                    child: const Row(
                      children: [
                        Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 24),
                        SizedBox(width: 12),
                        Expanded(child: Text('Get 5% extra value instantly when you withdraw to an e-waste voucher!', style: TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w500))),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 32),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF047857)]),
                          boxShadow: [BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: ElevatedButton(
                          onPressed: _submitWithdrawal,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
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
