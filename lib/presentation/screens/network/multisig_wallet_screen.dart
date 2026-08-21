import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../main_navigation_screen.dart';

class MultiSigWalletScreen extends StatefulWidget {
  final Network? defaultNetwork;

  const MultiSigWalletScreen({
    super.key,
    this.defaultNetwork,
  });

  @override
  State<MultiSigWalletScreen> createState() => _MultiSigWalletScreenState();
}

class _MultiSigWalletScreenState extends State<MultiSigWalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Network _selectedNetwork;

  // Create Mode Controllers
  final TextEditingController _createNameController = TextEditingController(text: 'MultiSig-Safe-1');
  int _threshold = 2;
  final List<TextEditingController> _ownerControllers = [
    TextEditingController(text: '0x71C80e460be01bc0ffFe8166D44122d64020967A'),
    TextEditingController(text: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'),
    TextEditingController(text: '0x2629668d28AFeFf5a54388481232B4c61989e486'),
  ];

  // Import Mode Controllers
  final TextEditingController _importAddressController = TextEditingController();
  final TextEditingController _importNameController = TextEditingController(text: 'MultiSig-Imported');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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

  @override
  void dispose() {
    _tabController.dispose();
    _createNameController.dispose();
    for (final c in _ownerControllers) {
      c.dispose();
    }
    _importAddressController.dispose();
    _importNameController.dispose();
    super.dispose();
  }

  void _addOwnerField() {
    if (_ownerControllers.length < 10) {
      setState(() {
        _ownerControllers.add(TextEditingController());
      });
    }
  }

  void _removeOwnerField(int index) {
    if (_ownerControllers.length > 2) {
      setState(() {
        final removed = _ownerControllers.removeAt(index);
        removed.dispose();
        if (_threshold > _ownerControllers.length) {
          _threshold = _ownerControllers.length;
        }
      });
    }
  }

  Future<void> _handleCreateMultiSig() async {
    final lang = context.read<LanguageController>();
    final walletController = context.read<WalletController>();

    final owners = _ownerControllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();
    if (owners.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 2 owner addresses are required'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await walletController.createMultiSigWallet(
      name: _createNameController.text.trim(),
      networkId: _selectedNetwork.id,
      threshold: _threshold,
      owners: owners,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(walletController.errorMessage ?? lang.tr('error')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _handleImportMultiSig() async {
    final lang = context.read<LanguageController>();
    final walletController = context.read<WalletController>();

    final contractAddress = _importAddressController.text.trim();
    if (contractAddress.isEmpty || !contractAddress.startsWith('0x') || contractAddress.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 42-character MultiSig contract address (0x...)'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final success = await walletController.createMultiSigWallet(
      name: _importNameController.text.trim(),
      networkId: _selectedNetwork.id,
      threshold: 2,
      owners: [contractAddress],
      contractAddress: contractAddress,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(walletController.errorMessage ?? lang.tr('error')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final networkController = context.watch<NetworkController>();
    final walletController = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('multisig_wallet_title'),
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E6FFF),
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: const Color(0xFF1E6FFF),
          indicatorWeight: 3,
          tabs: [
            Tab(text: lang.tr('multisig_create')),
            Tab(text: lang.tr('multisig_import')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Create MultiSig View
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Network Selector Row
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

                const SizedBox(height: 16),

                // Name Input
                Text(
                  lang.tr('wallet_name'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _createNameController,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: lang.tr('multisig_name_hint'),
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Threshold Selector M-of-N
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.tr('multisig_threshold_label'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_threshold / ${_ownerControllers.length}',
                        style: const TextStyle(
                          color: Color(0xFF1E6FFF),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Slider(
                  value: _threshold.toDouble(),
                  min: 1,
                  max: _ownerControllers.length.toDouble(),
                  divisions: _ownerControllers.length - 1 > 0 ? _ownerControllers.length - 1 : 1,
                  activeColor: const Color(0xFF1E6FFF),
                  onChanged: (val) {
                    setState(() => _threshold = val.toInt());
                  },
                ),

                const SizedBox(height: 16),

                // Member Addresses
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.tr('multisig_owners_label'),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                    ),
                    TextButton.icon(
                      onPressed: _addOwnerField,
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(lang.tr('add_member')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ..._ownerControllers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final controller = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFFE2E8F0),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: controller,
                            style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: '0x...',
                              hintStyle: const TextStyle(fontSize: 13, fontFamily: 'sans-serif', color: Color(0xFF94A3B8)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                              ),
                            ),
                          ),
                        ),
                        if (_ownerControllers.length > 2)
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFEF4444), size: 20),
                            onPressed: () => _removeOwnerField(index),
                          ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: walletController.isLoading ? null : _handleCreateMultiSig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6FFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: walletController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            lang.tr('btn_deploy_multisig'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // 2. Import MultiSig View
          SingleChildScrollView(
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

                const SizedBox(height: 16),

                // Contract Address
                Text(
                  lang.tr('multisig_contract_address'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _importAddressController,
                  style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: lang.tr('multisig_contract_hint'),
                    hintStyle: const TextStyle(fontSize: 14, fontFamily: 'sans-serif', color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(Icons.token_rounded, size: 20, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Name Input
                Text(
                  lang.tr('wallet_name'),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _importNameController,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: lang.tr('enter_wallet_name_hint'),
                    hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF64748B)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Import button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: walletController.isLoading ? null : _handleImportMultiSig,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E6FFF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: walletController.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            lang.tr('btn_import_multisig'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
