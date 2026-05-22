import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
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
                  const Text('My Requests', style: AppTextStyles.displayMedium),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Text(
                      '4 Active',
                      style: TextStyle(
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
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
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
              child: TabBarView(
                controller: _tabs,
                children: [
                  _RequestsList(all: true),
                  _RequestsList(all: false, activeOnly: true),
                  _RequestsList(all: false, activeOnly: false),
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
  final bool all;
  final bool activeOnly;

  const _RequestsList({required this.all, this.activeOnly = true});

  @override
  Widget build(BuildContext context) {
    final requests = [
      _RequestData(
        'MacBook Pro 2019',
        'REQ-1024',
        'Mar 4, 2026',
        'Under Verification',
        AppColors.statusPending,
        AppColors.statusPendingBg,
        5,
        '₹8,500',
      ),
      _RequestData(
        'iPhone 12',
        'REQ-1023',
        'Mar 3, 2026',
        'Collected',
        AppColors.statusInfo,
        AppColors.statusInfoBg,
        4,
        '₹6,000',
      ),
      _RequestData(
        'Dell Monitor 24"',
        'REQ-1022',
        'Mar 1, 2026',
        'Paid',
        AppColors.statusSuccess,
        AppColors.statusSuccessBg,
        7,
        '₹4,200',
      ),
      _RequestData(
        'HP Printer',
        'REQ-1021',
        'Feb 28, 2026',
        'Certificate Issued',
        AppColors.statusPurple,
        AppColors.statusPurpleBg,
        7,
        '₹1,800',
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      itemCount: requests.length,
      itemBuilder: (_, i) => _RequestCard(data: requests[i]),
    );
  }
}

class _RequestData {
  final String device;
  final String reqId;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBgColor;
  final int progressStep;
  final String price;

  const _RequestData(
    this.device,
    this.reqId,
    this.date,
    this.status,
    this.statusColor,
    this.statusBgColor,
    this.progressStep,
    this.price,
  );
}

class _RequestCard extends StatelessWidget {
  final _RequestData data;
  const _RequestCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showRequestDetail(context, data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data.device, style: AppTextStyles.headingMedium),
                      const SizedBox(height: 2),
                      Text(
                        '${data.reqId} · ${data.date}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: data.statusBgColor,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    data.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: data.statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Progress Bar
            _TrackerProgress(currentStep: data.progressStep),
            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.currency_rupee_rounded,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    Text(
                      'Est. Value: ${data.price}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRequestDetail(BuildContext context, _RequestData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestDetailSheet(data: data),
    );
  }
}

class _TrackerProgress extends StatelessWidget {
  final int currentStep;
  const _TrackerProgress({required this.currentStep});

  static const _steps = [
    'Requested',
    'Approved',
    'Scheduled',
    'Collected',
    'Verification',
    'Paid',
    'Certificate',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            _steps.length,
            (i) => Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 3,
                      color: i < currentStep
                          ? AppColors.primary
                          : AppColors.bgMuted,
                    ),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i < currentStep
                          ? AppColors.primary
                          : i == currentStep
                          ? AppColors.primary
                          : AppColors.bgMuted,
                      shape: BoxShape.circle,
                      border: i == currentStep
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                  ),
                  if (i < _steps.length - 1)
                    Expanded(
                      child: Container(
                        height: 3,
                        color: i < currentStep - 1
                            ? AppColors.primary
                            : AppColors.bgMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RequestDetailSheet extends StatelessWidget {
  final _RequestData data;
  const _RequestDetailSheet({required this.data});

  static const _stages = [
    (Icons.send_rounded, 'Requested', 'Your request was submitted'),
    (Icons.check_circle_rounded, 'Approved', 'Approved by our team'),
    (Icons.calendar_today_rounded, 'Scheduled', 'Pickup date confirmed'),
    (Icons.local_shipping_rounded, 'Collected', 'Device picked up'),
    (Icons.search_rounded, 'Verification', 'Physical inspection'),
    (Icons.payments_rounded, 'Paid', 'Payment transferred'),
    (
      Icons.workspace_premium_rounded,
      'Certificate',
      'Green certificate issued',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(data.device, style: AppTextStyles.displayMedium),
            Text(
              '${data.reqId} · ${data.date}',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 20),
            ..._stages.asMap().entries.map((e) {
              final isDone = e.key < data.progressStep;
              final isCurrent = e.key == data.progressStep - 1;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDone
                              ? AppColors.primary
                              : isCurrent
                              ? AppColors.primaryLight
                              : AppColors.bgMuted,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          e.value.$1,
                          color: isDone
                              ? Colors.white
                              : isCurrent
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      if (e.key < _stages.length - 1)
                        Container(
                          width: 2,
                          height: 32,
                          color: isDone ? AppColors.primary : AppColors.bgMuted,
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.value.$2,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isDone
                                  ? AppColors.primary
                                  : isCurrent
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                            ),
                          ),
                          Text(e.value.$3, style: AppTextStyles.bodySmall),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
