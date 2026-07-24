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
  bool _showRefreshHint = true;

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

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showRefreshHint = false;
        });
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
                      : RefreshIndicator(
                          key: _refreshIndicatorKey,
                          onRefresh: _handleRefresh,
                          color: AppColors.primary,
                          child: _buildContent(),
                        ),
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
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pull to refresh hint
          if (_showRefreshHint)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.primary.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Text(
                    'Pull down to refresh...',
                    style: TextStyle(color: AppColors.primary.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
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
                      onPressed: () async {
                        final res = await showDialog(
                          context: context,
                          builder: (ctx) => _WithdrawFundsDialog(availableBalance: available is num ? available : 0),
                        );
                        if (res == true && mounted) {
                          _fetchWallet();
                        }
                      },
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
              /* Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Credits'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Debits'),
                ],
              ), */
            ],
          ),
          const SizedBox(height: 16),
          
          // Transaction List
          if (_isLoadingTransactions && _transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            ..._buildTransactionList(),
            
          if (_isLoadingTransactions && _transactions.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
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
      final type = t['entryType'] ?? t['type'];
      if (_filter == 'Credits') return type == 'credit';
      if (_filter == 'Debits') return type == 'debit';
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
      final type = t['entryType'] ?? t['type'];
      final isCredit = type == 'credit';
      final title = t['title'] ?? t['item'] ?? 'Transaction';
      final sku = t['sku'] ?? '';
      final date = _formatDate(t['occurredAt'] ?? t['createdAt']);
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
            color: Colors.black.withOpacity(0.2),
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
                  setState(() => _isLoadingProfile = false);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save UPI ID')));
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
