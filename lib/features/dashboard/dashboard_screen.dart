import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/menu/menu_screen.dart';
import 'package:seller_ewaste/core/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    try {
      final data = await ApiService().getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load dashboard data';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.bgPage,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
            ],
          )
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgPage,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const MenuScreen()));
          },
        ),
        title: Text('Dashboard', style: AppTextStyles.headingMedium.copyWith(color: Colors.white)),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: 8),
                child: Text('Welcome back! Here\'s your overview.', style: AppTextStyles.bodyMedium.copyWith(fontSize: 14)),
              ),
            ),
            if (_summary != null)
              SliverToBoxAdapter(child: _DashboardCardsSection(summary: _summary!)),
            if (_summary!['recentRequests'] != null && (_summary!['recentRequests'] as List).isNotEmpty)
              SliverToBoxAdapter(child: _RecentRequestsSection(requests: _summary!['recentRequests'] as List<dynamic>)),
          ],
        ),
      ),
    );
  }
}


class _DashboardCardsSection extends StatelessWidget {
  final Map<String, dynamic> summary;

  const _DashboardCardsSection({required this.summary});

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
          children: [
            _StatCard(
              icon: Icons.list_alt_rounded,
              iconBgColor: const Color(0xFFF59E0B),
              iconColor: Colors.white,
              value: '${summary['totalRequests'] ?? 0}',
              title: 'Total Requests',
            ),
            _StatCard(
              icon: Icons.local_shipping_outlined,
              iconBgColor: const Color(0xFF8B5CF6),
              iconColor: Colors.white,
              value: '${summary['pendingPickups'] ?? 0}',
              title: 'Pending Pickups',
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconBgColor: const Color(0xFF10B981),
              iconColor: Colors.white,
              value: '${summary['completedOrders'] ?? 0}',
              title: 'Completed Orders',
            ),
            _StatCard(
              icon: Icons.account_balance_wallet_outlined,
              iconBgColor: const Color(0xFF3B82F6),
              iconColor: Colors.white,
              value: '₹${summary['availableEarnings'] ?? 0}',
              title: 'Available Earnings',
            ),
            _StatCard(
              icon: Icons.money_off_rounded,
              iconBgColor: const Color(0xFFEF4444),
              iconColor: Colors.white,
              value: '₹${summary['totalDebited'] ?? 0}',
              title: 'Total Debited',
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
  final String value;
  final String title;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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

class _RecentRequestsSection extends StatelessWidget {
  final List<dynamic> requests;

  const _RecentRequestsSection({required this.requests});

  String _formatDate(String isoString) {
    if (isoString.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Activity', style: AppTextStyles.headingMedium),
            const SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Divider(height: 1, color: AppColors.border),
              ),
              itemBuilder: (context, i) {
                final r = requests[i] as Map<String, dynamic>;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (r['device']?.toString() ?? '').isNotEmpty
                                ? r['device'].toString()
                                : 'Request ${r['id']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${r['requestNumber'] ?? ''} · ${_formatDate(r['createdAt']?.toString() ?? '')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFDE68A).withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        r['status']?.toString() ?? '',
                        style: const TextStyle(
                          color: Color(0xFFD97706),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
