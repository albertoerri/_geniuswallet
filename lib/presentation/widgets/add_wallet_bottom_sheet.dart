import 'package:flutter/material.dart';
import '../../domain/models/network.dart';
import '../screens/create_wallet/create_wallet_config_screen.dart';
import '../screens/import_wallet/import_wallet_screen.dart';
import '../screens/import_wallet/import_wallets_options_screen.dart';
import 'crypto_icon.dart';

/// Shows a bottom action sheet with "Create Wallet", "Import Wallet", and "Cancel"
/// matching TokenPocket's add wallet prompt for a specific network or HD wallet.
Future<void> showAddWalletActionSheet(
  BuildContext context, {
  required Network network,
  bool isHD = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (modalContext) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Network Header
              Row(
                children: [
                  CryptoIcon(networkId: network.id, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    isHD ? 'HD Wallet' : network.name,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(modalContext).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Action Options Container
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    // Create Wallet Option
                    _buildActionItem(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBgColor: const Color(0xFF1E6FFF),
                      title: 'Create Wallet',
                      subtitle: 'Generate a new wallet with mnemonic phrase',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CreateWalletConfigScreen(
                              network: network,
                              isHD: isHD,
                            ),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, indent: 64, endIndent: 16, color: Color(0xFFE2E8F0)),

                    // Import Wallet Option
                    _buildActionItem(
                      icon: Icons.file_download_outlined,
                      iconBgColor: const Color(0xFF0EA5E9),
                      title: 'Import Wallet',
                      subtitle: isHD
                          ? 'Restore HD wallet with Recovery Phrase'
                          : 'Recovery Phrase, Private Key, Keystore',
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        if (isHD) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ImportWalletScreen(network: network),
                            ),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ImportWalletsOptionsScreen(network: network),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => Navigator.of(modalContext).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF1F5F9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildActionItem({
  required IconData icon,
  required Color iconBgColor,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconBgColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFFCBD5E1),
          ),
        ],
      ),
    ),
  );
}
