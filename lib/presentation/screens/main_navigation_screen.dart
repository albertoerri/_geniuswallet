import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../controllers/language_controller.dart';
import '../controllers/wallet_controller.dart';
import 'assets/wallet_dashboard_screen.dart';
import 'assets/welcome_screen.dart';
import 'discover/discover_screen.dart';
import 'market/market_screen.dart';
import 'placeholder_screens.dart';
import 'swap/swap_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavigationScreen({super.key, this.initialIndex = 0});

  static _MainNavigationScreenState? of(BuildContext context) {
    return context.findAncestorStateOfType<_MainNavigationScreenState>();
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final hasWallets = walletController.hasWallets;

    final List<Widget> pages = [
      hasWallets
          ? WalletDashboardScreen(onSelectTab: switchTab)
          : const WelcomeScreen(),
      const MarketScreen(),
      const SwapScreen(isStandalonePage: false),
      const DiscoverScreen(),
      const MeScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: AppColors.cardBorder.withValues(alpha: 0.6),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textMuted,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.diamond_outlined, size: 22),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.diamond_rounded, size: 22),
              ),
              label: lang.tr('tab_assets'),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.show_chart_rounded, size: 22),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.show_chart_rounded, size: 22),
              ),
              label: lang.tr('tab_market'),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.swap_horiz_rounded, size: 22),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.swap_horiz_rounded, size: 22),
              ),
              label: lang.tr('tab_trade'),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.language_rounded, size: 22),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.language_rounded, size: 22),
              ),
              label: lang.tr('tab_discover'),
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_outline_rounded, size: 22),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_rounded, size: 22),
              ),
              label: lang.tr('tab_me'),
            ),
          ],
        ),
      ),
    );
  }
}
