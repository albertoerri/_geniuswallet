import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/add_wallet_bottom_sheet.dart';
import '../../widgets/crypto_icon.dart';
import '../network/select_network_screen.dart';
import '../swap/swap_screen.dart';
import '../tools/more_tools_screen.dart';
import '../transfer/receive_screen.dart';
import '../transfer/send_screen.dart';
import '../wallet/wallet_details_screen.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  bool _hideBalance = false;
  String? _lastLoadedWalletId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAssets());
  }

  void _initAssets({bool force = false}) {
    if (!mounted) return;
    final walletController = context.read<WalletController>();
    final networkController = context.read<NetworkController>();
    final assetController = context.read<AssetController>();
    final active = walletController.activeWallet;

    if (active != null) {
      final network = networkController.allNetworks.firstWhere(
        (n) => n.id.toLowerCase() == active.networkId.toLowerCase(),
        orElse: () => networkController.allNetworks.first,
      );
      _lastLoadedWalletId = active.id;
      assetController.loadAssets(
        network: network,
        walletAddress: active.address,
        walletId: active.id,
        forceRefresh: force,
      );
      assetController.preloadWalletBalances(
        wallets: walletController.wallets,
        networks: networkController.allNetworks,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final activeWallet = walletController.activeWallet;

    if (activeWallet == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    if (_lastLoadedWalletId != activeWallet.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initAssets());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      drawer: _buildWalletDrawer(context, walletController, networkController, assetController),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            _buildTopAppBar(context),

            // Scrollable Content
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF2563EB),
                onRefresh: () async {
                  await assetController.loadAssets(
                    network: network,
                    walletAddress: activeWallet.address,
                    walletId: activeWallet.id,
                    forceRefresh: true,
                  );
                  await assetController.preloadWalletBalances(
                    wallets: walletController.wallets,
                    networks: networkController.allNetworks,
                  );
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Solid Blue Wallet Card
                      _buildActiveWalletCard(context, activeWallet, network, assetController),

                      const SizedBox(height: 16),

                      // 4 Quick Action Buttons
                      _buildQuickActions(context, activeWallet),

                      const SizedBox(height: 20),

                      // Asset Sub-tabs (Assets ▾, DeFi, NFT, (+))
                      _buildAssetTabs(context, assetController),

                      const SizedBox(height: 12),

                      // Token List
                      _buildTokenList(context, assetController, network),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF7F8FA),
      child: Row(
        children: [
          // Drawer menu button
          Builder(
            builder: (ctx) => GestureDetector(
              onTap: () => Scaffold.of(ctx).openDrawer(),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.menu_rounded, size: 26, color: Color(0xFF1E293B)),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Green online dot
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),

          // Node pill: "Click to switch node"
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Node: Fast RPC (Block Latency: 42ms)')),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF475569),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Click to switch node',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const Spacer(),

          // Search icon
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22, color: Color(0xFF1E293B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search tokens or dApps')),
              );
            },
          ),

          // Add wallet icon
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, size: 22, color: Color(0xFF1E293B)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SelectNetworkScreen()),
              );
            },
          ),

          // Scan QR icon
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Color(0xFF1E293B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan QR Code')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveWalletCard(
    BuildContext context,
    dynamic activeWallet,
    dynamic network,
    AssetController assetController,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background watermark icon
          const Positioned(
            right: 0,
            bottom: -6,
            child: Opacity(
              opacity: 0.12,
              child: Icon(Icons.diamond_rounded, size: 90, color: Colors.white),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Wallet Name, Truncated Address Chip with Copy, Triple Dots Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        activeWallet.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: activeWallet.address));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Address copied to clipboard!')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                Formatters.formatAddress(activeWallet.address),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.copy_rounded, size: 12, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Three dots options button with red indicator dot
                  GestureDetector(
                    key: const Key('wallet_details_button'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => WalletDetailsScreen(wallet: activeWallet),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
                          Positioned(
                            top: -1,
                            right: -1,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF4D4F),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Balance Row
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _hideBalance = !_hideBalance),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _hideBalance ? '******' : assetController.formatUsd(assetController.totalBalanceUsd),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        _hideBalance ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, dynamic activeWallet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionTile(
          icon: Icons.swap_horiz_rounded,
          label: 'Send',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SendScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.arrow_downward_rounded,
          label: 'Receive',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReceiveScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.sync_rounded,
          label: 'Swap',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SwapScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.grid_view_rounded,
          label: 'More Tools',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MoreToolsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: const Color(0xFF334155)),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetTabs(BuildContext context, AssetController assetController) {
    final selectedTab = assetController.selectedSubTab;
    return Row(
      children: [
        GestureDetector(
          onTap: () => assetController.setSubTab(0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Assets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: selectedTab == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: selectedTab == 0 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    size: 18,
                    color: selectedTab == 0 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              if (selectedTab == 0)
                Container(
                  width: 28,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => assetController.setSubTab(1),
          child: Text(
            'DeFi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: selectedTab == 1 ? FontWeight.w700 : FontWeight.w500,
              color: selectedTab == 1 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: () => assetController.setSubTab(2),
          child: Text(
            'NFT',
            style: TextStyle(
              fontSize: 15,
              fontWeight: selectedTab == 2 ? FontWeight.w700 : FontWeight.w500,
              color: selectedTab == 2 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFF64748B)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Custom Token Management')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTokenList(BuildContext context, AssetController assetController, dynamic network) {
    final selectedTab = assetController.selectedSubTab;

    if (selectedTab == 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: const [
            Icon(Icons.layers_clear_rounded, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No DeFi positions found',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (selectedTab == 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: const [
            Icon(Icons.collections_rounded, size: 48, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              'No NFTs in this wallet',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final tokens = assetController.tokens;

    if (tokens.isEmpty && assetController.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
        ),
      );
    }

    return Column(
      children: tokens.map((token) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              CryptoIcon(networkId: token.symbol, size: 38),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      token.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          token.formattedPrice,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          token.formattedChange,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: token.isPositiveChange ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _hideBalance ? '***' : token.formattedBalance,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _hideBalance ? '***' : token.formattedFiat,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWalletDrawer(
    BuildContext context,
    WalletController walletController,
    NetworkController networkController,
    AssetController assetController,
  ) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Row(
          children: [
            // Left Rail: Chain Icons
            Container(
              width: 64,
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  ...networkController.allNetworks.take(6).map((net) {
                    final isCurrentChain = walletController.activeWallet?.networkId.toLowerCase() == net.id.toLowerCase();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: GestureDetector(
                        onTap: () {
                          // Switch chain focus
                        },
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: isCurrentChain ? Border.all(color: const Color(0xFF2563EB), width: 2) : null,
                          ),
                          child: CryptoIcon(networkId: net.id, size: 36),
                        ),
                      ),
                    );
                  }),
                  const Spacer(),
                  // Add chain button
                  IconButton(
                    icon: const Icon(Icons.add_rounded, color: Color(0xFF64748B)),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SelectNetworkScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Right Area: Wallet List for Selected Chain
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Wallet List + Close button
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Wallet List',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Chain Name + Add button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            walletController.activeWallet?.name ?? 'Wallets',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          key: const Key('drawer_add_wallet_button'),
                          onTap: () {
                            Navigator.of(context).pop();
                            final currentNetwork = networkController.allNetworks.firstWhere(
                              (n) => n.id.toLowerCase() == walletController.activeWallet?.networkId.toLowerCase(),
                              orElse: () => networkController.allNetworks.first,
                            );
                            showAddWalletActionSheet(context, network: currentNetwork);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Wallet Cards
                    Expanded(
                      child: ListView(
                        children: walletController.wallets.map((wallet) {
                          final isSelected = wallet.id == walletController.activeWallet?.id;
                          final walletBalance = assetController.getWalletBalance(wallet.id);
                          return GestureDetector(
                            onTap: () {
                              walletController.switchActiveWallet(wallet.id);
                              final currentNetwork = networkController.allNetworks.firstWhere(
                                (n) => n.id.toLowerCase() == wallet.networkId.toLowerCase(),
                                orElse: () => networkController.allNetworks.first,
                              );
                              _lastLoadedWalletId = wallet.id;
                              assetController.loadAssets(
                                network: currentNetwork,
                                walletAddress: wallet.address,
                                walletId: wallet.id,
                                forceRefresh: true,
                              );
                              Navigator.of(context).pop();
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B), // Dark card matching TP drawer
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          wallet.name,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          Formatters.formatAddress(wallet.address),
                                          style: const TextStyle(
                                            color: Color(0xFF94A3B8),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isSelected)
                                        const Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                      const SizedBox(height: 4),
                                      Text(
                                        _hideBalance ? '***' : assetController.formatUsd(walletBalance),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => WalletDetailsScreen(wallet: wallet),
                                        ),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Icon(Icons.more_vert_rounded, color: Color(0xFF94A3B8), size: 20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
