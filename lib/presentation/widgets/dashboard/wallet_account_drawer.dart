import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';
import '../../screens/wallet/wallet_details_screen.dart';

class WalletAccountDrawer extends StatelessWidget {
  final VoidCallback onAddWallet;

  const WalletAccountDrawer({super.key, required this.onAddWallet});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();

    final wallets = walletController.wallets;
    final activeWallet = walletController.activeWallet;
    final selectedNetwork = networkController.selectedNetwork;

    final filteredWallets = selectedNetwork != null
        ? wallets.where((w) => w.networkId.toLowerCase() == selectedNetwork.id.toLowerCase()).toList()
        : wallets;

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('my_wallets'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF2563EB), size: 24),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onAddWallet();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Expanded(
              child: filteredWallets.isEmpty
                  ? Center(
                      child: Text(
                        lang.tr('no_wallets_for_network'),
                        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: filteredWallets.length,
                      itemBuilder: (context, index) {
                        final w = filteredWallets[index];
                        final isSelected = activeWallet?.id == w.id;

                        return CustomCard(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          onTap: () {
                            walletController.switchActiveWallet(w.id);
                            Navigator.of(context).pop();
                          },
                          child: Row(
                            children: [
                              CryptoIcon(networkId: w.networkId, size: 36),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.name,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      Formatters.formatAddress(w.address),
                                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              IconButton(
                                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => WalletDetailsScreen(wallet: w)),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
