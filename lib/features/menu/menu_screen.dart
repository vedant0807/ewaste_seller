import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';
import 'package:seller_ewaste/features/auth/login_screen.dart';
import 'package:seller_ewaste/features/dashboard/dashboard_screen.dart';
import 'package:seller_ewaste/features/orders/orders_screen.dart';
import 'package:seller_ewaste/features/menu/profile_screen.dart';
import 'package:seller_ewaste/features/menu/my_addresses_screen.dart';
import 'package:seller_ewaste/features/menu/wallet_screen.dart';
import 'package:seller_ewaste/features/menu/donate_ewaste_screen.dart';
import 'package:seller_ewaste/features/menu/corporate_inquiry_screen.dart';
import 'package:seller_ewaste/core/services/session_manager.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _name = 'User Name';
  String _phone = 'Phone Number';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await SessionManager().getUserName();
    final phone = await SessionManager().getPhoneNumber();
    if (mounted) {
      setState(() {
        _name = name != null && name.isNotEmpty ? name : 'User Name';
        _phone = phone != null && phone.isNotEmpty ? phone : 'Phone Number';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.dashboard, 'My Dashboard', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
      }),
      (Icons.receipt_long_rounded, 'My Orders', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersScreen()));
      }),
      (Icons.person_outline_rounded, 'My Profile', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
      }),
      (Icons.location_on_outlined, 'My Addresses', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MyAddressesScreen()));
      }),
      (Icons.account_balance_wallet_rounded, 'My Wallet', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
      }),
      // (Icons.favorite_rounded, 'Donate E-Waste', () {
      //   Navigator.pop(context);
      //   Navigator.push(context, MaterialPageRoute(builder: (_) => const DonateEwasteScreen()));
      // }),
      (Icons.business_rounded, 'Corporate Enquiry', () {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CorporateInquiryScreen()));
      }),
      (Icons.eco_rounded, 'My Certificates', () {}),
      // (Icons.help_outline_rounded, 'Help & Support', () {}),
      (Icons.logout_rounded, 'Logout', () async {
        await SessionManager().clearSession();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }),
    ];

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 33),
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
                        Text(
                          _name,
                          style: AppTextStyles.headingMedium,
                        ),
                        Text(_phone, style: AppTextStyles.bodySmall),
                      ],
                    ),
                    const Spacer(),
                    // Container(
                    //   padding: const EdgeInsets.symmetric(
                    //     horizontal: 10,
                    //     vertical: 4,
                    //   ),
                    //   decoration: BoxDecoration(
                    //     color: AppColors.primaryLight,
                    //     borderRadius: BorderRadius.circular(6),
                    //   ),
                    //   child: const Text(
                    //     'Free Plan',
                    //     style: TextStyle(
                    //       fontSize: 11,
                    //       color: AppColors.primaryDark,
                    //       fontWeight: FontWeight.w600,
                    //     ),
                    //   ),
                    // ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              ...items.map(
                (i) => ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: 4,
                  ),
                  leading: Icon(
                    i.$1,
                    color: i.$1 == Icons.logout_rounded
                        ? Colors.red
                        : AppColors.primary,
                    size: 24,
                  ),
                  title: Text(
                    i.$2,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: i.$1 == Icons.logout_rounded ? Colors.red : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: i.$1 != Icons.logout_rounded
                      ? const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted,
                          size: 20,
                        )
                      : null,
                  onTap: i.$3 as void Function()?,
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
