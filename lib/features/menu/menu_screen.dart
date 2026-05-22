import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/theme/app_theme.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: AppTextStyles.headingMedium.copyWith(fontSize: 18),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                  onTap: () {},
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
