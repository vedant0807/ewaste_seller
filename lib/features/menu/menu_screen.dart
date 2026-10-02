import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';
import 'package:seller_ewaste/features/auth/login_screen.dart';
import 'package:seller_ewaste/features/orders/orders_screen.dart';
import 'package:seller_ewaste/features/menu/profile_screen.dart';
import 'package:seller_ewaste/features/menu/my_addresses_screen.dart';
import 'package:seller_ewaste/features/menu/wallet_screen.dart';
import 'package:seller_ewaste/features/menu/corporate_inquiry_screen.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback? onNavigateToDashboard;
  final VoidCallback? onNavigateToRequests;
  final VoidCallback? onNavigateToWallet;
  final VoidCallback? onNavigateToProfile;

  const MenuScreen({
    super.key,
    this.onNavigateToDashboard,
    this.onNavigateToRequests,
    this.onNavigateToWallet,
    this.onNavigateToProfile,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await SessionManager().clearSession();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawerWidth = MediaQuery.of(context).size.width * 0.82;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Header: ebuyer4u Logo + Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/seller-logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEEF2F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF475569),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Navigation Menu Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 1. My Dashboard
                      _buildMenuItem(
                        icon: Icons.grid_view_rounded,
                        title: 'My Dashboard',
                        isActive: true,
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onNavigateToDashboard != null) {
                            widget.onNavigateToDashboard!();
                          }
                        },
                      ),
                      const SizedBox(height: 6),

                      // 2. My Orders
                      _buildMenuItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'My Orders',
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onNavigateToRequests != null) {
                            widget.onNavigateToRequests!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OrdersScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 6),

                      // 3. My Profile
                      _buildMenuItem(
                        icon: Icons.person_outline_rounded,
                        title: 'My Profile',
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onNavigateToProfile != null) {
                            widget.onNavigateToProfile!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const ProfileScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 6),

                      // 4. My Addresses
                      _buildMenuItem(
                        icon: Icons.location_on_outlined,
                        title: 'My Addresses',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyAddressesScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 6),

                      // 5. My Wallet
                      _buildMenuItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'My Wallet',
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onNavigateToWallet != null) {
                            widget.onNavigateToWallet!();
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WalletScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 6),

                      // 6. Corporate Enquiry
                      _buildMenuItem(
                        icon: Icons.apartment_rounded,
                        title: 'Corporate Enquiry',
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CorporateInquiryScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // Bottom Section: Eco Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Every recycle\nmakes a difference 🌿',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Thank you for helping\nbuild a cleaner planet.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/eco_planet.jpg',
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Bottom Section: Logout Button
              InkWell(
                onTap: _handleLogout,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Color(0xFFEF4444),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F8F0) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFD1F2E2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF0D7E40) : const Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                  color: isActive ? const Color(0xFF0D7E40) : const Color(0xFF1E293B),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? const Color(0xFF0D7E40) : const Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
