import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/formatters.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/custom_card.dart';
import 'network/select_network_screen.dart';
import 'swap/swap_screen.dart';

class MarketPlaceholderScreen extends StatelessWidget {
  const MarketPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Market')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('Market Overview', style: AppStyles.heading3),
            SizedBox(height: 8),
            Text('Crypto prices and market analytics coming soon.', style: AppStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class TradePlaceholderScreen extends StatelessWidget {
  const TradePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SwapScreen(isStandalonePage: false);
  }
}

class DiscoverPlaceholderScreen extends StatelessWidget {
  const DiscoverPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Discover')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_rounded, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text('DApps & Web3 Browser', style: AppStyles.heading3),
            SizedBox(height: 8),
            Text('Explore decentralized applications and protocols.', style: AppStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();
    final wallets = walletController.wallets;
    final activeWallet = walletController.activeWallet;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Me', style: AppStyles.heading3),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // User / Profile Header Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBackground,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeWallet?.name ?? 'Genius User',
                          style: AppStyles.heading3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeWallet != null
                              ? Formatters.formatAddress(activeWallet.address)
                              : 'No active wallet',
                          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Wallets Management Section
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                    title: const Text('Manage Wallets', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${wallets.length} wallet(s) connected'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SelectNetworkScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                    title: const Text('Security & Vault', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Hardware-backed encryption'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    title: const Text('About Genius Wallet', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Version 1.0.0'),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
