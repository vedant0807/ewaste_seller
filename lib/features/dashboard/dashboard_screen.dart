import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:seller_ewaste/core/services/api_service.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';
import 'package:seller_ewaste/features/menu/profile_screen.dart';
import 'package:seller_ewaste/features/menu/wallet_screen.dart';
import 'package:seller_ewaste/features/menu/menu_screen.dart';
import 'package:seller_ewaste/features/requests/requests_screen.dart';
import 'package:seller_ewaste/features/requests/request_detail_screen.dart';
import 'package:seller_ewaste/features/sell/sell_flow.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRequests;
  final VoidCallback? onNavigateToWallet;
  final VoidCallback? onNavigateToSell;
  final VoidCallback? onNavigateToProfile;

  const DashboardScreen({
    super.key,
    this.onNavigateToRequests,
    this.onNavigateToWallet,
    this.onNavigateToSell,
    this.onNavigateToProfile,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _summary;
  String _userName = 'Darshan';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchSummary();
  }

  Future<void> _loadUserInfo() async {
    try {
      final name = await SessionManager().getUserName();
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() {
          _userName = name.trim();
        });
      }
    } catch (_) {}
  }

  Future<void> _fetchSummary() async {
    try {
      final data = await ApiService().getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = data;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) {
        setState(() {
          // If we already have data, don't clobber it with an error screen
          if (_summary == null) {
            _error = 'Failed to load dashboard data';
          }
          _isLoading = false;
        });
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  void _goToRequests() {
    if (widget.onNavigateToRequests != null) {
      widget.onNavigateToRequests!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RequestsScreen()),
      );
    }
  }

  void _goToWallet() {
    if (widget.onNavigateToWallet != null) {
      widget.onNavigateToWallet!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const WalletScreen()),
      );
    }
  }

  void _goToSell() {
    if (widget.onNavigateToSell != null) {
      widget.onNavigateToSell!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SellFlowEntryPoint()),
      );
    }
  }

  void _goToProfile() {
    if (widget.onNavigateToProfile != null) {
      widget.onNavigateToProfile!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0D7E40)),
        ),
      );
    }

    if (_error != null && _summary == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => _isLoading = true);
                    _fetchSummary();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D7E40),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final summaryData = _summary ?? <String, dynamic>{};

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        drawer: MenuScreen(
          onNavigateToDashboard: () {},
          onNavigateToRequests: widget.onNavigateToRequests,
          onNavigateToWallet: widget.onNavigateToWallet,
          onNavigateToProfile: _goToProfile,
        ),
        backgroundColor: const Color(0xFFF4F7F5),
        body: RefreshIndicator(
          color: const Color(0xFF0D7E40),
          onRefresh: _fetchSummary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Green Header with Greetings, Impact Pill & Avatar
                _buildHeader(context),

                // 2. Overlapping / Hero Average Seller Card
                Transform.translate(
                  offset: const Offset(0, -32),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildHeroCard(context),
                  ),
                ),

                // 3. 2x2 Metric Cards Grid
                Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildMetricGrid(context, summaryData),
                  ),
                ),

                // 4. "Sell an item now" CTA Button
                Transform.translate(
                  offset: const Offset(0, -6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: _buildSellCTAButton(context),
                  ),
                ),

                const SizedBox(height: 12),

                // 5. "Recent activity" Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildRecentActivitySection(context, summaryData),
                ),

                const SizedBox(height: 16),

                // 6. "Earn 5% extra with vouchers" Promo Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildVoucherPromoCard(context),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Green Header with Greeting, Username, Avatar and Impact Pill
  Widget _buildHeader(BuildContext context) {
    final initialLetter = _userName.isNotEmpty ? _userName[0].toUpperCase() : 'D';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 54, // extra space for hero card overlap
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0D7E40),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Menu Drawer Icon, Greeting & Avatar
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _userName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          '👋',
                          style: TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _goToProfile,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2EA663),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      initialLetter,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Impact Pill Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.eco_outlined,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white,
                        height: 1.3,
                      ),
                      children: [
                        TextSpan(text: "You've recycled "),
                        TextSpan(
                          text: "14 kg ",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: "of e-waste — that's "),
                        TextSpan(
                          text: "21 kg of CO₂ ",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        TextSpan(text: "saved."),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Hero Earnings Banner Card
  Widget _buildHeroCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3D Electronics Graphic Image
          Image.asset(
            'assets/dashboard_banner.jpg',
            height: 135,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 135,
              color: const Color(0xFF0A4F2A),
              child: const Center(
                child: Icon(Icons.devices_other_rounded, size: 48, color: Colors.white54),
              ),
            ),
          ),

          // Card Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Average seller earns ₹2,850 per item',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Free doorstep pickup • Instant estimate • Secure payment',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2x2 Metric Cards Grid
  Widget _buildMetricGrid(BuildContext context, Map<String, dynamic> summary) {
    // Format values
    final totalRequests = summary['totalRequests'] != null
        ? summary['totalRequests'].toString()
        : '12';

    final pendingPickupsRaw = summary['pendingPickups'];
    final pendingPickups = pendingPickupsRaw != null
        ? (int.tryParse(pendingPickupsRaw.toString()) != null && int.parse(pendingPickupsRaw.toString()) < 10
            ? '0$pendingPickupsRaw'
            : pendingPickupsRaw.toString())
        : '02';

    final walletBalance = summary['availableEarnings'] != null
        ? '₹${summary['availableEarnings']}'
        : (summary['walletBalance'] != null ? '₹${summary['walletBalance']}' : '₹8,420');

    final withdrawn = summary['totalDebited'] != null
        ? '₹${summary['totalDebited']}'
        : (summary['withdrawn'] != null ? '₹${summary['withdrawn']}' : '₹5,000');

    return Row(
      children: [
        // Column 1
        Expanded(
          child: Column(
            children: [
              _MetricCard(
                icon: Icons.inventory_2_outlined,
                iconBgColor: const Color(0xFFE8F8EE),
                iconColor: const Color(0xFF10B981),
                value: totalRequests,
                label: 'Total Requests',
                onTap: _goToRequests,
              ),
              const SizedBox(height: 12),
              _MetricCard(
                icon: Icons.account_balance_wallet_outlined,
                iconBgColor: const Color(0xFFEBF4FE),
                iconColor: const Color(0xFF3B82F6),
                value: walletBalance,
                label: 'Wallet Balance',
                onTap: _goToWallet,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Column 2
        Expanded(
          child: Column(
            children: [
              _MetricCard(
                icon: Icons.local_shipping_outlined,
                iconBgColor: const Color(0xFFFFF3E6),
                iconColor: const Color(0xFFF97316),
                value: pendingPickups,
                label: 'Pending Pickups',
                onTap: _goToRequests,
              ),
              const SizedBox(height: 12),
              _MetricCard(
                icon: Icons.north_east_rounded,
                iconBgColor: const Color(0xFFFEF5E7),
                iconColor: const Color(0xFFF59E0B),
                value: withdrawn,
                label: 'Withdrawn',
                onTap: _goToWallet,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// "Sell an item now" CTA Button
  Widget _buildSellCTAButton(BuildContext context) {
    return InkWell(
      onTap: _goToSell,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF042316),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Lime green circle button with arrow
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                color: Color(0xFF84CC16),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF042316),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Text Column
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Sell an item now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Get an instant price range in 60s',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            // Right Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF64748B),
              size: 24,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  /// "Recent activity" Section
  Widget _buildRecentActivitySection(
      BuildContext context, Map<String, dynamic> summary) {
    final recentRaw = summary['recentRequests'] as List<dynamic>?;
    final hasRealRequests = recentRaw != null && recentRaw.isNotEmpty;

    // Default sample activities matching the screenshots exactly
    final defaultActivities = [
      {
        'title': 'Laptop — Apple',
        'subtitle': 'SR-145 • Pickup Thu, 2–4 PM',
        'price': '₹2,975 – ₹4,025',
        'status': 'Requested',
        'statusBg': const Color(0xFFFEF3C7),
        'statusColor': const Color(0xFFD97706),
        'icon': Icons.inventory_2_outlined,
      },
      {
        'title': 'iPhone 12 — 128GB',
        'subtitle': 'SR-138 • Collected 28 Aug',
        'price': '₹14,200',
        'status': 'Paid',
        'statusBg': const Color(0xFFDCFCE7),
        'statusColor': const Color(0xFF16A34A),
        'icon': Icons.smartphone_rounded,
      },
      {
        'title': 'Split AC — 1.5 Ton',
        'subtitle': 'SR-131 • Scheduled 05 Sept',
        'price': '₹6,100 – ₹7,300',
        'status': 'Scheduled',
        'statusBg': const Color(0xFFDBEAFE),
        'statusColor': const Color(0xFF2563EB),
        'icon': Icons.calendar_today_rounded,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: "Recent activity" and "View all"
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent activity',
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
            GestureDetector(
              onTap: _goToRequests,
              child: const Text(
                'View all',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D7E40),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Activity Cards List
        if (hasRealRequests)
          ...recentRaw.take(4).map((item) {
            final r = item as Map<String, dynamic>;
            final device = (r['device']?.toString() ?? '').isNotEmpty
                ? r['device'].toString()
                : 'Request #${r['id'] ?? ''}';
            final reqNo = r['requestNumber'] ?? 'SR-${r['id'] ?? ''}';
            final dateStr = r['createdAt'] != null
                ? _formatShortDate(r['createdAt'].toString())
                : '';
            final subtitle = dateStr.isNotEmpty ? '$reqNo • $dateStr' : reqNo;

            final estPrice = r['estimatedPrice'];
            final finalPrice = r['finalPrice'];
            final displayPrice = finalPrice != null
                ? '₹$finalPrice'
                : (estPrice != null ? '₹$estPrice' : '');

            final status = r['status']?.toString() ?? 'Requested';
            final badgeStyle = _getStatusBadgeStyle(status);
            final deviceIcon = _getDeviceIcon(device);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _ActivityCard(
                icon: deviceIcon,
                title: device,
                subtitle: subtitle,
                price: displayPrice,
                status: status,
                statusBg: badgeStyle.bg,
                statusColor: badgeStyle.color,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(data: r),
                    ),
                  );
                },
              ),
            );
          })
        else
          ...defaultActivities.map((act) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _ActivityCard(
                icon: act['icon'] as IconData,
                title: act['title'] as String,
                subtitle: act['subtitle'] as String,
                price: act['price'] as String,
                status: act['status'] as String,
                statusBg: act['statusBg'] as Color,
                statusColor: act['statusColor'] as Color,
                onTap: _goToRequests,
              ),
            );
          }),
      ],
    );
  }

  /// "Earn 5% extra with vouchers" Promo Card
  Widget _buildVoucherPromoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Voucher illustration
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFEDF8F1),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              'assets/voucher_promo.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Center(
                child: Icon(Icons.card_giftcard_rounded,
                    color: Color(0xFF10B981), size: 36),
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Right: Text & Know more button
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Earn 5% extra with vouchers',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose voucher payout and get bonus value instantly.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _goToWallet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Know more',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return isoString;
    }
  }

  _BadgeStyle _getStatusBadgeStyle(String status) {
    final s = status.toUpperCase();
    if (s.contains('PAID') || s.contains('COMPLETED')) {
      return _BadgeStyle(const Color(0xFFDCFCE7), const Color(0xFF16A34A));
    } else if (s.contains('SCHEDULED')) {
      return _BadgeStyle(const Color(0xFFDBEAFE), const Color(0xFF2563EB));
    } else if (s.contains('CANCEL')) {
      return _BadgeStyle(const Color(0xFFFEE2E2), const Color(0xFFDC2626));
    }
    // Default: Requested / Pending
    return _BadgeStyle(const Color(0xFFFEF3C7), const Color(0xFFD97706));
  }

  IconData _getDeviceIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('phone') || t.contains('iphone') || t.contains('mobile')) {
      return Icons.smartphone_rounded;
    }
    if (t.contains('ac') || t.contains('air') || t.contains('schedule')) {
      return Icons.calendar_today_rounded;
    }
    return Icons.inventory_2_outlined;
  }
}

class _BadgeStyle {
  final Color bg;
  final Color color;
  _BadgeStyle(this.bg, this.color);
}

/// Stat / Metric Card Widget
class _MetricCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String value;
  final String label;
  final VoidCallback onTap;

  const _MetricCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon container
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ),
            const SizedBox(height: 14),
            // Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.1,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent Activity List Item Card
class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String price;
  final String status;
  final Color statusBg;
  final Color statusColor;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.status,
    required this.statusBg,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 13.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Device category icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F8EE),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Icon(icon, color: const Color(0xFF10B981), size: 22),
              ),
            ),
            const SizedBox(width: 12),
            // Details: Title, Subtitle, Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (price.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D7E40),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status badge pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
