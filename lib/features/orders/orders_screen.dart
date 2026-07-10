import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _orders = [];
  int _page = 1;
  bool _hasMore = true;
  bool _isLoading = false;
  String? _error;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchOrders(page: 1, isRefresh: true);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        _fetchOrders(page: _page + 1);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrders({int page = 1, bool isRefresh = false}) async {
    if (_isLoading) return;
    if (!isRefresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _page = 1;
        _hasMore = true;
        _error = null;
      } else {
        _page = page;
      }
    });

    try {
      final response = await ApiService().getOrders(page: _page, limit: 10);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> newOrders = [];
        
        if (data is List) {
           newOrders = data;
        } else if (data is Map && data.containsKey('data')) {
           newOrders = data['data'] as List<dynamic>? ?? [];
           _totalOrders = data['totalRecords'] as int? ?? _totalOrders;
           if (data.containsKey('hasNextPage')) {
             _hasMore = data['hasNextPage'] == true;
           } else {
             _hasMore = newOrders.length == 10;
           }
        } else {
           _hasMore = false;
        }

        if (mounted) {
          setState(() {
            if (isRefresh) {
              _orders = newOrders;
              if (data is! Map || !data.containsKey('totalRecords')) {
                _totalOrders = _orders.length;
              }
            } else {
              _orders.addAll(newOrders);
            }
            if (data is! Map || !data.containsKey('hasNextPage')) {
              _hasMore = newOrders.length == 10;
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load orders';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Orders Error: $e');
      if (mounted) {
        setState(() {
          _error = isRefresh ? 'Failed to fetch orders' : _error;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCard,
      appBar: AppBar(
        backgroundColor: AppColors.bgCard,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _fetchOrders(page: 1, isRefresh: true),
          color: AppColors.primary,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Marketplace Board & Sales',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Manage your active buyer sales, ship packages, and track completed recycling requests.',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  
                  // Recycling Orders Tab
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Recycling Orders ($_totalOrders)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (_error != null && _orders.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    )
                  else if (_orders.isEmpty && _isLoading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_orders.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('No orders found.', style: TextStyle(color: AppColors.textSecondary))),
                    )
                  else ...[
                    ..._orders.map((order) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                          child: _OrderCard(data: order),
                        )).toList(),
                        
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _OrderCard({required this.data});

  String _formatDate(String? isoString) {
    if (isoString == null) return '';
    try {
      final dt = DateTime.parse(isoString);
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final device = data['device'] ?? 'Unknown Device';
    final typeStr = data['category'] ?? '';
    final conditionStr = data['condition'] ?? '';
    final title = (typeStr.isNotEmpty || conditionStr.isNotEmpty)
        ? '$device (Type: $typeStr, Condition: $conditionStr)'
        : device;
        
    final ordId = data['requestNumber'] ?? '';
    final date = _formatDate(data['createdAt']);
    final price = data['finalPrice']?.toString() ?? data['estimatedPrice']?.toString() ?? '0';
    final status = data['status']?.toString() ?? 'Pending';
    final isCompleted = status.toLowerCase() == 'completed' || status.toLowerCase() == 'paid';
    
    final payoutMethod = data['payout']?['preferredMethod'] ?? 'Wallet';
    final invoiceNumber = data['invoiceNumber'] ?? ordId;
    final hasReceipt = data['receiptUrl'] != null || isCompleted;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Green top border line
          Container(
            height: 3,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 22,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$ordId  ·  $date',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isCompleted ? AppColors.statusSuccessBg : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isCompleted ? Icons.check_circle_outline_rounded : Icons.pending_actions_rounded,
                                    size: 14,
                                    color: isCompleted ? AppColors.statusSuccess : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isCompleted ? AppColors.statusSuccess : Colors.orange,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Detail Cards Row (wrap for mobile, row for larger)
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isWide = constraints.maxWidth > 600;
                    
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                          child: _PickupDetailsCard(data: data),
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                          child: hasReceipt 
                              ? _PaymentReceiptCard(method: payoutMethod, invoice: invoiceNumber, paidOn: date) 
                              : _GiftVoucherCard(), // Or show pending payment
                        ),
                        SizedBox(
                          width: isWide ? (constraints.maxWidth - 32) / 3 : double.infinity,
                          child: _CertificateCard(data: data),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PickupDetailsCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _PickupDetailsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    dynamic addrData = data['address'];
    Map<String, dynamic> addressObj = addrData is Map ? addrData as Map<String, dynamic> : {};
    final addrLine = addrData is String ? addrData : (addressObj['address'] ?? 'No Address');
    
    dynamic schedData = data['schedule'];
    Map<String, dynamic> sched = schedData is Map ? schedData as Map<String, dynamic> : {};
    final schedDate = schedData is String ? schedData : (sched['scheduledDate'] ?? '');
    final timeslot = sched['timeSlot'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3E8FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Color(0xFF9333EA),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Pickup Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            addrLine,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                schedDate,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timeslot,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 38), // Match height of other cards roughly
        ],
      ),
    );
  }
}

class _PaymentReceiptCard extends StatelessWidget {
  final String method;
  final String invoice;
  final String paidOn;

  const _PaymentReceiptCard({required this.method, required this.invoice, required this.paidOn});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Payment Receipt',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              children: [
                const TextSpan(text: 'Method: '),
                TextSpan(text: method, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            invoice,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Paid on $paidOn',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.download_rounded, size: 14, color: AppColors.textPrimary),
                SizedBox(width: 6),
                Text(
                  'Receipt',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftVoucherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED), // Orange light
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDD5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  size: 16,
                  color: Color(0xFFF97316), // Orange
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Gift Voucher',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              children: [
                TextSpan(text: 'Brand: '),
                TextSpan(text: 'Amazon Pay', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Issued on Feb 26, 2026',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Expires Feb 26, 2027',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'Includes +5% bonus value',
            style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF97316), // Orange
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.redeem_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  'View & Redeem',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _CertificateCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final certIssued = data['certificateIssued'] == true;
    final certId = data['certificateId'] ?? '';

    return Container(
      decoration: BoxDecoration(
        color: certIssued ? const Color(0xFFF8FAFC) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: certIssued ? null : Border.all(color: AppColors.border, style: BorderStyle.solid),
      ),
      padding: const EdgeInsets.all(16),
      child: certIssued ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Recycling Certificate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            certId.isNotEmpty ? certId : 'CERT-2026-001',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          const Text(
            'Issued by ReCircle Sell',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 48), // Spacer to align buttons
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(6),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.download_rounded, size: 14, color: AppColors.textPrimary),
                SizedBox(width: 6),
                Text(
                  'Certificate',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ) : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          SizedBox(height: 32),
          Icon(Icons.workspace_premium_outlined, color: Colors.grey, size: 32),
          SizedBox(height: 12),
          Text('Pending Certificate', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 13)),
          SizedBox(height: 4),
          Text('Will be issued shortly', style: TextStyle(color: Colors.grey, fontSize: 11)),
          SizedBox(height: 32),
        ],
      ),
    );
  }
}
