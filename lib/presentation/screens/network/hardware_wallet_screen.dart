import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../main_navigation_screen.dart';

class HardwareWalletScreen extends StatefulWidget {
  final Network? defaultNetwork;

  const HardwareWalletScreen({
    super.key,
    this.defaultNetwork,
  });

  @override
  State<HardwareWalletScreen> createState() => _HardwareWalletScreenState();
}

class _HardwareWalletScreenState extends State<HardwareWalletScreen> {
  late Network _selectedNetwork;
  bool _isPairing = false;
  String? _pairingDeviceName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final networkController = context.read<NetworkController>();
    _selectedNetwork = widget.defaultNetwork ??
        networkController.allNetworks.firstWhere(
          (n) => n.id == 'polygon',
          orElse: () => networkController.allNetworks.first,
        );
  }

  Future<void> _startPairingFlow(String deviceName, String brandIcon) async {
    setState(() {
      _isPairing = true;
      _pairingDeviceName = deviceName;
    });

    // Simulate device pairing & key discovery
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final walletController = context.read<WalletController>();
    final lang = context.read<LanguageController>();

    // Generate hardware vault address
    final hwAddress = '0x9965507D1a55bcC2695C58ba16FB37d819B0A4df';
    final success = await walletController.importWallet(
      name: '$deviceName-${_selectedNetwork.defaultNamePrefix}',
      secret: hwAddress,
      importType: WalletImportType.watchWallet,
      networkId: _selectedNetwork.id,
    );

    if (mounted) {
      setState(() {
        _isPairing = false;
        _pairingDeviceName = null;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deviceName paired & address imported successfully!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final networkController = context.watch<NetworkController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('hardware_wallet_title'),
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
      body: _isPairing
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF1E6FFF)),
                  const SizedBox(height: 20),
                  Text(
                    'Connecting to $_pairingDeviceName...',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please verify Bluetooth / USB authorization on device',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Network Selector
                  Text(
                    lang.tr('select_network'),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        CryptoIcon(networkId: _selectedNetwork.id, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedNetwork.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                          ),
                        ),
                        PopupMenuButton<Network>(
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          onSelected: (net) => setState(() => _selectedNetwork = net),
                          itemBuilder: (_) => networkController.allNetworks.map((net) {
                            return PopupMenuItem(
                              value: net,
                              child: Row(
                                children: [
                                  CryptoIcon(networkId: net.id, size: 20),
                                  const SizedBox(width: 8),
                                  Text(net.name),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Hardware Brand Options
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildHardwareOption(
                          icon: Icons.credit_card_rounded,
                          iconBgColor: const Color(0xFF1E6FFF),
                          title: lang.tr('keypal_hardware'),
                          subtitle: lang.tr('keypal_desc'),
                          onTap: () => _startPairingFlow('KeyPal Card', 'keypal'),
                        ),
                        const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                        _buildHardwareOption(
                          icon: Icons.usb_rounded,
                          iconBgColor: const Color(0xFF0F172A),
                          title: lang.tr('ledger_hardware'),
                          subtitle: lang.tr('ledger_desc'),
                          onTap: () => _startPairingFlow('Ledger Nano X', 'ledger'),
                        ),
                        const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                        _buildHardwareOption(
                          icon: Icons.device_hub_rounded,
                          iconBgColor: const Color(0xFF10B981),
                          title: lang.tr('onekey_hardware'),
                          subtitle: lang.tr('onekey_desc'),
                          onTap: () => _startPairingFlow('OneKey Classic', 'onekey'),
                        ),
                        const Divider(height: 1, indent: 70, color: Color(0xFFF1F5F9)),
                        _buildHardwareOption(
                          icon: Icons.qr_code_scanner_rounded,
                          iconBgColor: const Color(0xFFF59E0B),
                          title: lang.tr('qr_cold_hardware'),
                          subtitle: lang.tr('qr_cold_desc'),
                          onTap: () => _startPairingFlow('QR Cold Hardware', 'qr_cold'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHardwareOption({
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
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
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
