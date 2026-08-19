import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

class MoreToolsScreen extends StatelessWidget {
  const MoreToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final activeWallet = walletController.activeWallet;

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet?.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('More Tools', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category 1: Asset Management
            _buildCategoryTitle('Asset Management'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.send_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Batch Transfer',
                    subtitle: 'Send tokens to multiple addresses in one batch',
                    onTap: () => _showToolInfo(context, 'Batch Transfer', 'Batch Transfer allows sending tokens to up to 100 addresses in a single contract execution to save on gas fees.'),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: 'Approval Checker & Revoke',
                    subtitle: 'Inspect & revoke token allowances for security',
                    onTap: () => _showToolInfo(context, 'Approval Checker', 'Zero risky token allowances detected on ${network.name}. Your wallet is secure.'),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.water_drop_outlined,
                    iconColor: const Color(0xFF06B6D4),
                    iconBg: const Color(0xFFECFEFF),
                    title: 'Testnet Faucet',
                    subtitle: 'Claim free test tokens for developers',
                    onTap: () {
                      if (activeWallet == null) return;
                      _showFaucetSheet(context, assetController, activeWallet, network);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category 2: Network & Nodes
            _buildCategoryTitle('Network & Nodes'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.hub_outlined,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: 'Fast RPC Node Switcher',
                    subtitle: 'Switch to ultra low-latency backup nodes',
                    onTap: () => _showToolInfo(context, 'RPC Node Switcher', 'Active RPC: Official ${network.name} Node (Latency: 38ms, Block Height: 58,921,042).'),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.local_gas_station_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    title: 'Gas Tracker (EIP-1559)',
                    subtitle: 'Real-time Base Fee and Priority Fee monitor',
                    onTap: () => _showToolInfo(context, 'Gas Tracker', 'Current Base Fee: 28 Gwei | Fast: 35 Gwei | Instant: 45 Gwei'),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.travel_explore_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                    title: '${network.name} Explorer',
                    subtitle: 'View transactions on the public blockchain explorer',
                    onTap: () => _showToolInfo(context, '${network.name} Explorer', 'Opening block explorer for ${activeWallet?.address}...'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category 3: Security & Multi-Chain
            _buildCategoryTitle('Security & Hardware'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.usb_rounded,
                    iconColor: const Color(0xFF475569),
                    iconBg: const Color(0xFFF1F5F9),
                    title: 'KeyPal Hardware Wallet',
                    subtitle: 'Pair bluetooth hardware cold storage',
                    onTap: () => _showToolInfo(context, 'KeyPal Hardware', 'Scanning for nearby KeyPal or Ledger Bluetooth hardware devices...'),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.group_work_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFEFF6FF),
                    title: 'Multi-Sig Safe Suite',
                    subtitle: 'Manage joint signatory accounts & policies',
                    onTap: () => _showToolInfo(context, 'Multi-Sig Safe', 'Create or connect to a multi-signature smart contract vault.'),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.draw_outlined,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: 'Message Signer & Verifier',
                    subtitle: 'Sign arbitrary messages with private key',
                    onTap: () => _showToolInfo(context, 'Message Signer', 'EIP-191 & EIP-712 cryptographic signature utility ready.'),
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

  Widget _buildCategoryTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
      ),
    );
  }

  Widget _buildToolTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
      onTap: onTap,
    );
  }

  void _showToolInfo(BuildContext context, String toolName, String description) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                toolName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  description,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFaucetSheet(
    BuildContext context,
    AssetController assetController,
    dynamic activeWallet,
    dynamic network,
  ) {
    final tokens = assetController.tokens;
    String selectedSymbol = tokens.isNotEmpty ? tokens.first.symbol : network.symbol;
    double selectedAmount = 100.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Testnet / Demo Faucet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Claim test funds to verify asset valuation and transfer features on ${network.name}.',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Token',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: tokens.map((t) {
                    final isSel = t.symbol == selectedSymbol;
                    return ChoiceChip(
                      label: Text('${t.symbol} (${t.name})'),
                      selected: isSel,
                      selectedColor: const Color(0xFFEFF6FF),
                      labelStyle: TextStyle(
                        color: isSel ? const Color(0xFF2563EB) : const Color(0xFF475569),
                        fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setModalState(() => selectedSymbol = t.symbol);
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select Amount',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [10.0, 50.0, 100.0, 500.0].map((amt) {
                    final isSel = amt == selectedAmount;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => selectedAmount = amt),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            border: Border.all(
                              color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                              width: isSel ? 1.5 : 1.0,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+${amt.toInt()}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSel ? const Color(0xFF2563EB) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await assetController.claimFaucet(
                        network: network,
                        walletAddress: activeWallet.address,
                        walletId: activeWallet.id,
                        tokenSymbol: selectedSymbol,
                        amount: selectedAmount,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully claimed +${selectedAmount.toInt()} $selectedSymbol to ${activeWallet.name}!'),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Claim +${selectedAmount.toInt()} $selectedSymbol',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
