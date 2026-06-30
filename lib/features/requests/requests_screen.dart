import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.xl,
                AppSpacing.md,
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('My Requests', style: AppTextStyles.displayMedium),
                      const SizedBox(height: 4),
                      Text(
                        'Track the progress of your sell requests.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (!_isLoading && _error == null)
                    Container(
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
                ],
              ),
            ),

            // Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgMuted,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: TabBar(
                  controller: _tabs,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: const [
                    Tab(text: 'All'),
                    Tab(text: 'Active'),
                    Tab(text: 'Completed'),
                  ],
                ),
              ),
            ),
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
          ],
        ),
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
              itemBuilder: (_, i) => _RequestCard(data: filtered[i] as Map<String, dynamic>),
            ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _RequestCard({required this.data});

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
    final step = data['statusStep'] as int? ?? 1;
    final payoutMethod = data['payout']?['preferredMethod'] ?? 'Wallet';

    return GestureDetector(
      onTap: () => _showRequestDetail(context, data),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$reqId  ·  $date',
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
                              const Icon(Icons.currency_rupee_rounded, size: 10, color: Color(0xFF2E7D32)),
                              const SizedBox(width: 4),
                              Text(
                                'Paid in $payoutMethod',
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
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (data['status']?.toString().toLowerCase() == 'rejected')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Request Rejected',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              _TrackerProgress(currentStep: step, payoutMethod: payoutMethod),
          ],
        ),
      ),
    );
  }

  void _showRequestDetail(BuildContext context, Map<String, dynamic> data) {
    // We can keep the detail sheet empty for now or format it similarly
    // It wasn't in the screenshot, but we shouldn't break the feature.
  }
}

class _TrackerProgress extends StatelessWidget {
  final int currentStep;
  final String payoutMethod;

  const _TrackerProgress({required this.currentStep, required this.payoutMethod});

  @override
  Widget build(BuildContext context) {
    final steps = [
      (label: 'Requested', color: const Color(0xFF6B7280), icon: Icons.check_rounded),
      (label: 'Approved', color: const Color(0xFF3B82F6), icon: Icons.check_rounded),
      (label: 'Scheduled', color: const Color(0xFFF59E0B), icon: Icons.check_rounded),
      (label: 'Collected', color: const Color(0xFF8B5CF6), icon: Icons.check_rounded),
      (label: 'Paid', color: const Color(0xFF10B981), icon: Icons.currency_rupee_rounded),
      (label: 'Certificate', color: const Color(0xFFD1D5DB), icon: Icons.workspace_premium_rounded),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final isCompleted = i < currentStep - 1;
        final isCurrent = i == currentStep - 1;
        final isFuture = i > currentStep - 1;
        
        final stepData = steps[i];
        final nodeColor = isFuture ? const Color(0xFFE5E7EB) : stepData.color;
        
        final leftLineColor = i == 0 ? Colors.transparent : (i < currentStep ? const Color(0xFF10B981) : const Color(0xFFE5E7EB));
        final rightLineColor = i == steps.length - 1 ? Colors.transparent : (i < currentStep - 1 ? const Color(0xFF10B981) : const Color(0xFFE5E7EB));

        return Expanded(
          child: Column(
            children: [
              SizedBox(
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Container(height: 2, color: leftLineColor)),
                        Expanded(child: Container(height: 2, color: rightLineColor)),
                      ],
                    ),
                    Container(
                      width: isCurrent ? 36 : 24,
                      height: isCurrent ? 36 : 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent ? nodeColor.withValues(alpha: 0.2) : Colors.transparent,
                      ),
                      child: Center(
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isFuture ? Colors.white : nodeColor,
                            border: isFuture ? Border.all(color: nodeColor, width: 2) : null,
                          ),
                          child: Icon(
                            isCompleted ? Icons.check_rounded : (isCurrent ? stepData.icon : null),
                            size: 14,
                            color: isFuture ? Colors.transparent : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stepData.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                  color: isCurrent ? nodeColor : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
