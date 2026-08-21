import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import 'cold_wallet_screen.dart';
import 'import_wallet_screen.dart';
import 'sync_wallet_screen.dart';
import 'watch_wallet_screen.dart';

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
    final lang = context.watch<LanguageController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('import_wallets_title'),
          style: const TextStyle(
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
                    title: lang.tr('recovery_phrase'),
                    subtitle: lang.tr('recovery_phrase_sub'),
                    onTap: () => _navigateToImport(context, WalletImportType.recoveryPhrase),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.key_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: lang.tr('private_key'),
                    subtitle: lang.tr('private_key_sub'),
                    onTap: () => _navigateToImport(context, WalletImportType.privateKey),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.lock_outline_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: lang.tr('keystore'),
                    subtitle: lang.tr('keystore_sub'),
                    onTap: () => _navigateToImport(context, WalletImportType.keystore),
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.sync_rounded,
                    iconBgColor: const Color(0xFF1E6FFF),
                    title: lang.tr('sync_wallet'),
                    subtitle: lang.tr('sync_wallet_sub'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SyncWalletScreen(network: network),
                        ),
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
                    title: lang.tr('cold_wallet'),
                    subtitle: lang.tr('cold_wallet_sub'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ColdWalletScreen(network: network),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                  _buildOptionItem(
                    icon: Icons.remove_red_eye_outlined,
                    iconBgColor: const Color(0xFF10B981),
                    title: lang.tr('watch_wallet'),
                    subtitle: lang.tr('watch_wallet_sub'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WatchWalletScreen(network: network),
                        ),
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
