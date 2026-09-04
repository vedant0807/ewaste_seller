import 'package:flutter/material.dart';
import 'package:seller_ewaste/core/widgets/bottom_nav_bar.dart';
import 'package:seller_ewaste/features/dashboard/dashboard_screen.dart';
import 'package:seller_ewaste/features/menu/profile_screen.dart';
import 'package:seller_ewaste/features/menu/wallet_screen.dart';
import 'package:seller_ewaste/features/sell/sell_flow.dart';
import 'package:seller_ewaste/features/requests/requests_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavigateTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onOpenSellFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SellFlowEntryPoint()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      DashboardScreen(
        onNavigateToRequests: () => _onNavigateTab(1),
        onNavigateToWallet: () => _onNavigateTab(2),
        onNavigateToSell: _onOpenSellFlow,
      ),
      const RequestsScreen(),
      WalletScreen(isActive: _currentIndex == 2),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onNavigateTab,
        onSellTap: _onOpenSellFlow,
      ),
    );
  }
}
