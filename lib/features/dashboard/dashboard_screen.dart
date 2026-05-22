import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/menu/menu_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPage,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _DashboardHeader()),
            SliverToBoxAdapter(child: _DashboardCardsSection()),
            // SliverToBoxAdapter(child: _QuickActionsRow()),
            SliverToBoxAdapter(child: _RecentActivitySection()),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xl,
        AppSpacing.xl,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MenuScreen(),
                    ),
                  );
                },
                child: const Icon(
                  Icons.menu_rounded,
                  color: AppColors.textPrimary,
                  size: 28,
                ),
              ),
              GestureDetector(
                onTap: () => _showProfileSheet(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Dashboard',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Welcome back! Here\'s your overview.',
            style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showProfileSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfileSheet(),
    );
  }
}

class _ProfileSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.person_outline_rounded, 'My Profile'),
      (Icons.receipt_long_rounded, 'Transaction History'),
      (Icons.card_giftcard_rounded, 'My Rewards'),
      (Icons.eco_rounded, 'My Certificates'),
      (Icons.business_rounded, 'Corporate Enquiry'),
      (Icons.help_outline_rounded, 'Help & Support'),
      (Icons.logout_rounded, 'Logout'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // User info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rahul Sharma',
                      style: AppTextStyles.headingMedium,
                    ),
                    Text('+91 98765 43210', style: AppTextStyles.bodySmall),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Free Plan',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ...items.map(
            (i) => ListTile(
              leading: Icon(
                i.$1,
                color: i.$1 == Icons.logout_rounded
                    ? Colors.red
                    : AppColors.primary,
                size: 20,
              ),
              title: Text(
                i.$2,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: i.$1 == Icons.logout_rounded ? Colors.red : null,
                ),
              ),
              trailing: i.$1 != Icons.logout_rounded
                  ? const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textMuted,
                      size: 18,
                    )
                  : null,
              onTap: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DashboardCardsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        double childAspectRatio = constraints.maxWidth > 600 ? 1.4 : 1.15;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: const [
            _StatCard(
              icon: Icons.assignment_outlined,
              iconBgColor: Color(0xFF0F766E),
              iconColor: Colors.white,
              trendText: '+2 this week',
              trendColor: Color(0xFF10B981),
              trendIcon: Icons.trending_up_rounded,
              value: '12',
              title: 'Total Requests',
            ),
            _StatCard(
              icon: Icons.local_shipping_outlined,
              iconBgColor: Color(0xFFF97316),
              iconColor: Colors.white,
              trendText: 'Next: Tomorrow',
              trendColor: Color(0xFF10B981),
              trendIcon: Icons.trending_up_rounded,
              value: '3',
              title: 'Pending Pickups',
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBgColor: Color(0xFF10B981),
              iconColor: Colors.white,
              trendText: '+1 this week',
              trendColor: Color(0xFF10B981),
              trendIcon: Icons.trending_up_rounded,
              value: '8',
              title: 'Completed Orders',
            ),
            _StatCard(
              icon: Icons.currency_rupee_rounded,
              iconBgColor: Color(0xFF10B981),
              iconColor: Colors.white,
              trendText: '+₹3,200',
              trendColor: Color(0xFF10B981),
              trendIcon: Icons.trending_up_rounded,
              value: '₹24,500',
              title: 'Total Earnings',
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String trendText;
  final Color trendColor;
  final IconData trendIcon;
  final String value;
  final String title;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.trendText,
    required this.trendColor,
    required this.trendIcon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(trendIcon, color: trendColor, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        trendText,
                        style: TextStyle(
                          color: trendColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        Icons.sell_rounded,
        'Sell Device',
        AppColors.primary,
        AppColors.primaryLight,
      ),
      (
        Icons.schedule_rounded,
        'Schedule',
        const Color(0xFF3B82F6),
        const Color(0xFFDBEAFE),
      ),
      (
        Icons.eco_rounded,
        'Certificates',
        const Color(0xFF8B5CF6),
        const Color(0xFFEDE9FE),
      ),
      (
        Icons.card_giftcard_rounded,
        'Rewards',
        const Color(0xFFF59E0B),
        const Color(0xFFFEF3C7),
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: AppTextStyles.headingMedium),
          const SizedBox(height: 12),
          Row(
            children: actions
                .map(
                  (a) => Expanded(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: a.$4,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          children: [
                            Icon(a.$1, color: a.$3, size: 24),
                            const SizedBox(height: 6),
                            Text(
                              a.$2,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: a.$3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final activities = [
      _ActivityData(
        'MacBook Pro 2019',
        'REQ-1024',
        'Mar 4, 2026',
        'Under Verification',
        AppColors.statusPending,
        AppColors.statusPendingBg,
      ),
      _ActivityData(
        'iPhone 12',
        'REQ-1023',
        'Mar 3, 2026',
        'Collected',
        AppColors.statusInfo,
        AppColors.statusInfoBg,
      ),
      _ActivityData(
        'Dell Monitor 24"',
        'REQ-1022',
        'Mar 1, 2026',
        'Paid',
        AppColors.statusSuccess,
        AppColors.statusSuccessBg,
      ),
      _ActivityData(
        'HP Printer',
        'REQ-1021',
        'Feb 28, 2026',
        'Certificate Issued',
        AppColors.statusPurple,
        AppColors.statusPurpleBg,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        0,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Recent Activity', style: AppTextStyles.headingMedium),
              const Spacer(),
              Text(
                'View All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16, endIndent: 16),
              itemBuilder: (_, i) => _ActivityItem(data: activities[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityData {
  final String device;
  final String reqId;
  final String date;
  final String status;
  final Color statusColor;
  final Color statusBgColor;

  const _ActivityData(
    this.device,
    this.reqId,
    this.date,
    this.status,
    this.statusColor,
    this.statusBgColor,
  );
}

class _ActivityItem extends StatelessWidget {
  final _ActivityData data;
  const _ActivityItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      title: Text(
        data.device,
        style: AppTextStyles.headingMedium.copyWith(fontSize: 14),
      ),
      subtitle: Text(
        '${data.reqId} · ${data.date}',
        style: AppTextStyles.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
    );
  }
}
