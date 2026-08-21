import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../widgets/add_wallet_bottom_sheet.dart';
import '../../widgets/crypto_icon.dart';
import '../create_wallet/create_wallet_config_screen.dart';
import '../import_wallet/import_wallet_screen.dart';
import '../import_wallet/import_wallets_options_screen.dart';
import 'hardware_wallet_screen.dart';
import 'identity_wallet_screen.dart';
import 'multisig_wallet_screen.dart';

class SelectNetworkScreen extends StatefulWidget {
  final bool? isImport;

  const SelectNetworkScreen({
    super.key,
    this.isImport,
  });

  @override
  State<SelectNetworkScreen> createState() => _SelectNetworkScreenState();
}

class _SelectNetworkScreenState extends State<SelectNetworkScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSelectNetwork(Network network) {
    if (widget.isImport == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImportWalletsOptionsScreen(network: network),
        ),
      );
    } else if (widget.isImport == false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateWalletConfigScreen(network: network, isHD: false),
        ),
      );
    } else {
      showAddWalletActionSheet(context, network: network, isHD: false);
    }
  }

  void _onSelectHDWallet(Network? defaultNetwork) {
    if (defaultNetwork == null) return;
    if (widget.isImport == true) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ImportWalletScreen(network: defaultNetwork),
        ),
      );
    } else if (widget.isImport == false) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CreateWalletConfigScreen(network: defaultNetwork, isHD: true),
        ),
      );
    } else {
      showAddWalletActionSheet(context, network: defaultNetwork, isHD: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final networkController = context.watch<NetworkController>();
    final networks = networkController.networks;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('select_network_title'),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card: HD Wallet, MultiSig, Hardware
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildTopOption(
                    icon: Icons.apps_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: lang.tr('hd_wallet'),
                    hasHelp: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => IdentityWalletScreen(isImport: widget.isImport),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildTopOption(
                    icon: Icons.hub_rounded,
                    iconColor: const Color(0xFF0284C7),
                    title: lang.tr('multisig_wallet'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const MultiSigWalletScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                  _buildTopOption(
                    icon: Icons.phonelink_lock_rounded,
                    iconColor: const Color(0xFF3B82F6),
                    title: lang.tr('hardware_wallet'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const HardwareWalletScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // "SingleNetwork" Section Label
            Text(
              lang.tr('single_network'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 10),

            // Single Network Card with Search and Chain List
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => networkController.search(val),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: lang.tr('search_network_hint'),
                          hintStyle: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF64748B),
                            size: 22,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Chain list
                  if (networks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No networks found',
                        style: TextStyle(color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    ...List.generate(networks.length, (index) {
                      final net = networks[index];
                      return Column(
                        children: [
                          InkWell(
                            onTap: () => _onSelectNetwork(net),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  CryptoIcon(networkId: net.id, size: 36),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      net.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFFCBD5E1),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (index < networks.length - 1)
                            const Divider(height: 1, indent: 66, color: Color(0xFFF1F5F9)),
                        ],
                      );
                    }),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTopOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    bool hasHelp = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (hasHelp) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.help_outline_rounded,
                      size: 15,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ],
              ),
            ),
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
