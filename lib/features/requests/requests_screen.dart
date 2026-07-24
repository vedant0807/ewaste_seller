import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/features/requests/request_detail_screen.dart';
import 'package:seller_ewaste/features/main/main_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final response = await ApiService().getMyRequests();
      debugPrint('MY REQUESTS RAW BODY: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> parsedRequests = [];
        
        if (data is List) {
          parsedRequests = data;
        } else if (data is Map) {
          if (data.containsKey('requests')) {
            parsedRequests = data['requests'] as List<dynamic>;
          } else if (data.containsKey('data')) {
            parsedRequests = data['data'] as List<dynamic>;
          }
        }

        if (mounted) {
          setState(() {
            _requests = parsedRequests;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load requests';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('MyRequests Error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to fetch requests';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        title: Text('My Requests', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
        actions: [
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '${_requests.where((r) => (r['statusStep'] as int? ?? 1) < 6).length} Active',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 8),
              child: Text(
                'Track the progress of your sell requests.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
            ),
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 4),
            //   child: Container(
            //     padding: const EdgeInsets.all(12),
            //     decoration: BoxDecoration(
            //       color: const Color(0xFFFFF3E0), // Light orange background for note
            //       borderRadius: BorderRadius.circular(AppRadius.md),
            //       border: Border.all(color: const Color(0xFFFFCC80)),
            //     ),
            //     child: Row(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 20),
            //         const SizedBox(width: 12),
            //         Expanded(
            //           child: Text(
            //             'The amount shown is an approximate value. The final amount will be confirmed after we inspect your item.',
            //             style: AppTextStyles.bodySmall.copyWith(
            //               color: const Color(0xFFE65100),
            //               height: 1.4,fontWeight: FontWeight.bold,fontSize: 10
            //             ),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // ),

            // Tabs
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            //   child: Container(
            //     decoration: BoxDecoration(
            //       color: AppColors.bgMuted,
            //       borderRadius: BorderRadius.circular(AppRadius.lg),
            //     ),
            //     child: TabBar(
            //       controller: _tabs,
            //       indicator: BoxDecoration(
            //         color: AppColors.primary,
            //         borderRadius: BorderRadius.circular(AppRadius.md),
            //       ),
            //       indicatorSize: TabBarIndicatorSize.tab,
            //       labelColor: Colors.white,
            //       unselectedLabelColor: AppColors.textSecondary,
            //       labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            //       dividerColor: Colors.transparent,
            //       padding: const EdgeInsets.all(4),
            //       tabs: const [
            //         Tab(text: 'All'),
            //         Tab(text: 'Active'),
            //         Tab(text: 'Completed'),
            //       ],
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                      : TabBarView(
                          controller: _tabs,
                          children: [
                            _RequestsList(requests: _requests, all: true, onRefresh: _fetchRequests),
                            _RequestsList(requests: _requests, all: false, activeOnly: true, onRefresh: _fetchRequests),
                            _RequestsList(requests: _requests, all: false, activeOnly: false, onRefresh: _fetchRequests),
                          ],
                        ),
            ),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen(initialIndex: 0)),
            (route) => false,
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _RequestsList extends StatelessWidget {
  final List<dynamic> requests;
  final bool all;
  final bool activeOnly;
  final Future<void> Function() onRefresh;

  const _RequestsList({
    required this.requests,
    required this.all,
    this.activeOnly = true,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = requests.where((req) {
      if (all) return true;
      final step = req['statusStep'] as int? ?? 1;
      if (activeOnly) return step < 6;
      return step >= 6; // completed
    }).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      child: filtered.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const Center(
                    child: Text('No requests found.', style: AppTextStyles.bodyLarge),
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
              itemCount: filtered.length,
              itemBuilder: (_, i) => _RequestCard(
                data: filtered[i] as Map<String, dynamic>,
                initiallyExpanded: i == 0,
                onRefresh: onRefresh,
              ),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool initiallyExpanded; // Kept for signature compatibility if needed, but unused
  final Future<void> Function()? onRefresh;
  
  const _RequestCard({required this.data, this.initiallyExpanded = false, this.onRefresh});



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
    final device = data['device'] ?? 'Unknown Device';
    final reqId = data['requestNumber'] ?? '';
    final date = _formatDate(data['createdAt']);
    final price = data['estimatedPrice']?.toString() ?? '0';
    final payoutMethod = data['payout']?['preferredMethod'] ?? 'Wallet';
    final status = data['status']?.toString().toUpperCase() ?? 'PLACED';

    return GestureDetector(
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => RequestDetailScreen(data: data)));
        if (onRefresh != null) {
          onRefresh!();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppColors.border),
        ),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$reqId-$date',
                          maxLines: 1,

                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),

                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9), // Light green
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 4),
                                Text(
                                  '$payoutMethod',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '₹$price',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      SizedBox(height: 4,),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: status == 'REJECTED' ? Colors.red.withValues(alpha: 0.1) : AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: status == 'REJECTED' ? Colors.red : AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFF57C00), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The amount shown is an approximate value. The final amount will be confirmed after we inspect your item.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: const Color(0xFFE65100),
                          height: 1.4,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

