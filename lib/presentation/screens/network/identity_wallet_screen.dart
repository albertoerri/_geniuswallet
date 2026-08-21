import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../create_wallet/create_wallet_config_screen.dart';
import '../import_wallet/import_wallet_screen.dart';
import '../main_navigation_screen.dart';

class IdentityWalletScreen extends StatefulWidget {
  final bool? isImport;

  const IdentityWalletScreen({
    super.key,
    this.isImport,
  });

  @override
  State<IdentityWalletScreen> createState() => _IdentityWalletScreenState();
}

class _IdentityWalletScreenState extends State<IdentityWalletScreen> {
  final TextEditingController _nameController = TextEditingController(text: 'Identity-1');
  final Set<String> _selectedChains = {
    'polygon',
    'binancesmartchain',
    'ethereum',
    'base',
    'arbitrum',
    'optimism',
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleCreateIdentity() {
    final networkController = context.read<NetworkController>();
    final defaultNetwork = networkController.allNetworks.firstWhere(
      (n) => n.id == 'polygon',
      orElse: () => networkController.allNetworks.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateWalletConfigScreen(
          network: defaultNetwork,
          isHD: true,
        ),
      ),
    );
  }

  void _handleImportIdentity() {
    final networkController = context.read<NetworkController>();
    final defaultNetwork = networkController.allNetworks.firstWhere(
      (n) => n.id == 'polygon',
      orElse: () => networkController.allNetworks.first,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImportWalletScreen(
          network: defaultNetwork,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final networkController = context.watch<NetworkController>();
    final availableNetworks = networkController.allNetworks;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('identity_wallet_title'),
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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E6FFF), Color(0xFF3B82F6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E6FFF).withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.apps_rounded, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                lang.tr('identity_wallet_title'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            lang.tr('identity_wallet_desc'),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Chain Selection Header
                    Text(
                      lang.tr('select_chains_to_create'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Supported Chains List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: availableNetworks.length,
                        separatorBuilder: (_, __) => const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final net = availableNetworks[index];
                          final isSelected = _selectedChains.contains(net.id.toLowerCase());

                          return ListTile(
                            leading: CryptoIcon(networkId: net.id, size: 36),
                            title: Text(
                              net.name,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            subtitle: Text(
                              net.symbol,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                            ),
                            trailing: Checkbox(
                              value: isSelected,
                              activeColor: const Color(0xFF1E6FFF),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedChains.add(net.id.toLowerCase());
                                  } else {
                                    if (_selectedChains.length > 1) {
                                      _selectedChains.remove(net.id.toLowerCase());
                                    }
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleCreateIdentity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        lang.tr('create_wallet'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: _handleImportIdentity,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        lang.tr('import_wallet'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
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
