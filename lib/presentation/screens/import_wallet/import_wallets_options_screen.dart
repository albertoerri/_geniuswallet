import 'package:flutter/material.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import 'import_wallet_screen.dart';

class ImportWalletsOptionsScreen extends StatelessWidget {
  final Network network;

  const ImportWalletsOptionsScreen({
    super.key,
    required this.network,
  });

  void _navigateToImport(BuildContext context, WalletImportType importType) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportWalletScreen(
          network: network,
          initialImportType: importType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Import Wallets',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            // Top Card: Phrase, Private Key, Keystore, Sync
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildOptionItem(
                    icon: Icons.edit_note_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: 'Recovery Phrase',
                    subtitle: 'Restore wallet through Recovery Phrase',
                    onTap: () => _navigateToImport(context, WalletImportType.recoveryPhrase),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.key_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: 'Private Key',
                    subtitle: 'Restore wallet through Private Key',
                    onTap: () => _navigateToImport(context, WalletImportType.privateKey),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.lock_outline_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: 'Keystore',
                    subtitle: 'Restore wallet through Keystore file',
                    onTap: () => _navigateToImport(context, WalletImportType.recoveryPhrase),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.sync_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: 'Sync Wallet',
                    subtitle: "Sync other EVM network's wallet",
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sync Wallet feature coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Card: Cold Wallet, Watch Wallet
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildOptionItem(
                    icon: Icons.account_balance_wallet_outlined,
                    iconBgColor: const Color(0xFF10B981),
                    title: 'Cold Wallet',
                    subtitle: 'Import wallet offline and isolate from network',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cold Wallet support coming soon!')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.remove_red_eye_outlined,
                    iconBgColor: const Color(0xFF10B981),
                    title: 'Watch Wallet',
                    subtitle: 'Supports wallet addresses and EIP-4527, compatible with cold wallets.',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Watch Wallet support coming soon!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
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
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
