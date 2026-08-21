import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_styles.dart';
import '../../core/utils/formatters.dart';
import '../controllers/language_controller.dart';
import '../controllers/wallet_controller.dart';
import '../widgets/custom_card.dart';
import 'auth/set_master_password_screen.dart';
import 'me/address_book_screen.dart';
import 'me/help_feedback_screen.dart';
import 'network/select_network_screen.dart';
import 'swap/swap_screen.dart';
import 'tools/more_tools_screen.dart';

class MarketPlaceholderScreen extends StatelessWidget {
  const MarketPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(lang.tr('tab_market'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.trending_up_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(lang.tr('tab_market'), style: AppStyles.heading3),
            const SizedBox(height: 8),
            const Text('Crypto prices and market analytics coming soon.', style: AppStyles.bodyMedium),
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
    final lang = context.watch<LanguageController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(lang.tr('tab_discover'))),
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

  void _showLanguageSelector(BuildContext context) {
    final langController = context.read<LanguageController>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final currentLang = context.watch<LanguageController>().currentLanguage;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      langController.tr('select_language'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(langController.tr('lang_en'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLang == AppLanguage.en
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    langController.setLanguage(AppLanguage.en);
                    Navigator.of(ctx).pop();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  title: Text(langController.tr('lang_zh'), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: currentLang == AppLanguage.zh
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    langController.setLanguage(AppLanguage.zh);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAboutDialog(BuildContext context, LanguageController lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.diamond_rounded, color: Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Genius Wallet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(lang.tr('app_version'), style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Text(
              lang.currentLanguage == AppLanguage.zh
                  ? 'Genius Wallet 是一款去中心化多链加密钱包，支持多链资产管理、Transit 闪兑与 Web3 DApp 浏览。'
                  : 'Genius Wallet is a decentralized multi-chain crypto wallet supporting asset management, Transit Swap, and Web3 DApp browsing.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            const Text('Website: https://geniuswallet.io', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.tr('btn_confirm'), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final wallets = walletController.wallets;
    final activeWallet = walletController.activeWallet;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(lang.tr('me_title'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
        backgroundColor: Colors.white,
        elevation: 0,
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
                          activeWallet?.name ?? lang.tr('genius_user'),
                          style: AppStyles.heading3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          activeWallet != null
                              ? Formatters.formatAddress(activeWallet.address)
                              : lang.tr('no_active_wallet'),
                          style: AppStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF059669)),
                        const SizedBox(width: 4),
                        Text(
                          lang.currentLanguage == AppLanguage.zh ? '安全 100分' : 'Safe 100%',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Wallets & Address Book Card
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
                    title: Text(lang.tr('manage_wallets'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('connected_wallets_count', params: {'count': '${wallets.length}'})),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SelectNetworkScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.contacts_rounded, color: AppColors.primary),
                    title: Text(lang.tr('address_book'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('address_book_sub')),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddressBookScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Settings & Security Card
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                    title: Text(lang.tr('security_password'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('security_sub')),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SetMasterPasswordScreen(isImport: false)),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.speed_rounded, color: AppColors.primary),
                    title: Text(lang.tr('node_settings'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('node_settings_sub')),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MoreToolsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                    title: Text(lang.tr('language_setting'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('language_current')),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () => _showLanguageSelector(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Support & About Card
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                    title: Text(lang.tr('help_and_feedback'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('help_and_feedback_sub')),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpFeedbackScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                    title: Text(lang.tr('about_app'), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(lang.tr('app_version')),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () => _showAboutDialog(context, lang),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

