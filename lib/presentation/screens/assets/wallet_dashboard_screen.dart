import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/token.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/add_wallet_bottom_sheet.dart';
import '../../widgets/crypto_icon.dart';
import '../main_navigation_screen.dart';
import '../network/select_network_screen.dart';
import '../scan/scan_qr_screen.dart';
import '../search/search_hub_screen.dart';
import '../swap/swap_screen.dart';
import '../tools/more_tools_screen.dart';
import '../transfer/receive_screen.dart';
import '../transfer/send_screen.dart';
import '../wallet/wallet_details_screen.dart';

class WalletDashboardScreen extends StatefulWidget {
  final ValueChanged<int>? onSelectTab;
  const WalletDashboardScreen({super.key, this.onSelectTab});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  bool _hideBalance = false;
  String? _lastLoadedWalletId;
  String? _selectedDrawerNetworkId;

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

          const Spacer(),

          // Search icon
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22, color: Color(0xFF1E293B)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchHubScreen()),
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScanQrScreen()),
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
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            activeWallet.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
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
                  ),
                  const SizedBox(width: 8),

                  // Three dots options button (Clean without red dot)
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
                      child: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 24),
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
    final lang = context.watch<LanguageController>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionTile(
          icon: Icons.swap_horiz_rounded,
          label: lang.tr('action_send'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SendScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.arrow_downward_rounded,
          label: lang.tr('action_receive'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ReceiveScreen()),
            );
          },
        ),
        _buildActionTile(
          icon: Icons.sync_rounded,
          label: lang.tr('action_swap'),
          onTap: () {
            if (widget.onSelectTab != null) {
              widget.onSelectTab!(2);
            } else {
              MainNavigationScreen.of(context)?.switchTab(2);
            }
          },
        ),
        _buildActionTile(
          icon: Icons.grid_view_rounded,
          label: lang.tr('action_more_tools'),
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
    final lang = context.watch<LanguageController>();
    final selectedTab = assetController.selectedSubTab;

    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (selectedTab == 0) {
              _showAssetFilterMenu(context, assetController, lang);
            } else {
              assetController.setSubTab(0);
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    lang.tr('tab_assets'),
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
          key: const Key('dashboard_add_token_button'),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFF64748B)),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            final networkController = context.read<NetworkController>();
            final walletController = context.read<WalletController>();
            final activeWallet = walletController.activeWallet;
            final network = networkController.allNetworks.firstWhere(
              (n) => n.id.toLowerCase() == (activeWallet?.networkId.toLowerCase() ?? ''),
              orElse: () => networkController.allNetworks.first,
            );
            _showAddTokenBottomSheet(context, assetController, network, lang);
          },
        ),
      ],
    );
  }

  Widget _buildTokenList(BuildContext context, AssetController assetController, dynamic network) {
    final lang = context.watch<LanguageController>();
    final selectedTab = assetController.selectedSubTab;

    if (selectedTab == 1) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            const Icon(Icons.hub_rounded, size: 48, color: Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(
              lang.tr('explore_defi'),
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Trade, lend, stake and earn yields on top Web3 protocols',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                MainNavigationScreen.of(context)?.switchTab(2); // Swap
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 16),
              label: Text(lang.tr('trade_now')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    if (selectedTab == 2) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            const Icon(Icons.collections_rounded, size: 48, color: Color(0xFF8B5CF6)),
            const SizedBox(height: 12),
            Text(
              lang.tr('explore_nft'),
              style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Discover and trade top digital collectibles & NFT items',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SearchHubScreen()),
                );
              },
              icon: const Icon(Icons.search_rounded, size: 16),
              label: const Text('OpenSea / Magic Eden'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    final tokens = assetController.displayedTokens;

    if (tokens.isEmpty && assetController.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
        ),
      );
    }

    if (tokens.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(
              lang.tr('no_search_results'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    return Column(
      children: tokens.map((token) {
        return GestureDetector(
          onTap: () => _showTokenDetailSheet(context, token, network, lang),
          child: Container(
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
          ),
        );
      }).toList(),
    );
  }

  // --- 1. Token Details Bottom Sheet ---
  void _showTokenDetailSheet(
    BuildContext context,
    dynamic token,
    dynamic network,
    LanguageController lang,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CryptoIcon(networkId: token.symbol, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          token.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          '${token.symbol} • ${network.name}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Balance & Fiat Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Text(
                      _hideBalance ? '******' : token.formattedBalance,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _hideBalance ? '******' : '≈ ${token.formattedFiat}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${lang.tr('sort_last_price')}: ${token.formattedPrice}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: token.isPositiveChange ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            token.formattedChange,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (token.contractAddress != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code_rounded, size: 16, color: Color(0xFF64748B)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Contract: ${token.contractAddress}',
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: token.contractAddress!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(lang.tr('copied'))),
                          );
                        },
                        child: const Icon(Icons.copy_rounded, size: 15, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SendScreen(initialTokenSymbol: token.symbol),
                          ),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 16),
                      label: Text(lang.tr('action_send')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ReceiveScreen()),
                        );
                      },
                      icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                      label: Text(lang.tr('action_receive')),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SwapScreen(isStandalonePage: true)),
                        );
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: Text(lang.tr('action_swap')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. Add Custom Token / Token Management Sheet ---
  void _showAddTokenBottomSheet(
    BuildContext context,
    AssetController assetController,
    dynamic network,
    LanguageController lang,
  ) {
    final contractController = TextEditingController();
    final symbolController = TextEditingController();
    final decimalsController = TextEditingController(text: '18');
    int activeTab = 0; // 0: Popular, 1: Custom

    final popularList = [
      {'symbol': 'USDT', 'name': 'Tether USD', 'address': '0xc2132D05D31c914a87C6611C10748AEb04B58e8F', 'price': 1.0, 'dec': 6},
      {'symbol': 'USDC', 'name': 'USD Coin', 'address': '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359', 'price': 1.0, 'dec': 6},
      {'symbol': 'WETH', 'name': 'Wrapped Ether', 'address': '0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619', 'price': 3450.0, 'dec': 18},
      {'symbol': 'DAI', 'name': 'Dai Stablecoin', 'address': '0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063', 'price': 1.0, 'dec': 18},
      {'symbol': 'UNI', 'name': 'Uniswap', 'address': '0xb33EaAd8d922B1083446DC23f610c2567fB5180f', 'price': 7.85, 'dec': 18},
      {'symbol': 'LINK', 'name': 'Chainlink', 'address': '0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39', 'price': 12.4, 'dec': 18},
      {'symbol': 'QUICK', 'name': 'QuickSwap', 'address': '0xB5C064F955D8e7F38fE0460C556a72987494eE17', 'price': 0.048, 'dec': 18},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.tr('add_token_title'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tab switcher: Popular / Custom
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => activeTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 0 ? AppColors.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                lang.tr('popular_tokens'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: activeTab == 0 ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setSheetState(() => activeTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: activeTab == 1 ? AppColors.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                lang.tr('custom_token'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: activeTab == 1 ? Colors.white : const Color(0xFF64748B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (activeTab == 0) ...[
                    // Popular Tokens List
                    ...popularList.map((pop) {
                      final isAdded = assetController.tokens.any((t) => t.symbol == pop['symbol']);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CryptoIcon(networkId: pop['symbol'] as String, size: 36),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pop['name'] as String,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  Text(
                                    pop['symbol'] as String,
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isAdded,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                if (val) {
                                  assetController.addCustomToken(
                                    Token(
                                      id: (pop['symbol'] as String).toLowerCase(),
                                      networkId: network.id,
                                      symbol: pop['symbol'] as String,
                                      name: pop['name'] as String,
                                      balance: 0.0,
                                      priceUsd: (pop['price'] as num).toDouble(),
                                      fiatValue: 0.0,
                                      decimals: pop['dec'] as int,
                                      contractAddress: pop['address'] as String,
                                      isNative: false,
                                    ),
                                  );
                                }
                                setSheetState(() {});
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    // Custom Token Form
                    Text(
                      lang.tr('token_contract_address'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contractController,
                      style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      onChanged: (val) {
                        if (val.length > 20 && symbolController.text.isEmpty) {
                          setSheetState(() {
                            symbolController.text = 'MYTOKEN';
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: '0x...',
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
                    const SizedBox(height: 14),
                    Text(
                      lang.tr('token_symbol'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: symbolController,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: 'e.g. USDT',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        prefixIcon: const Icon(Icons.short_text_rounded, size: 20, color: Color(0xFF64748B)),
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
                    const SizedBox(height: 14),
                    Text(
                      lang.tr('token_decimals'),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: decimalsController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: '18',
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        prefixIcon: const Icon(Icons.numbers_rounded, size: 20, color: Color(0xFF64748B)),
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final sym = symbolController.text.trim();
                          if (sym.isNotEmpty) {
                            assetController.addCustomToken(
                              Token(
                                id: sym.toLowerCase(),
                                networkId: network.id,
                                symbol: sym.toUpperCase(),
                                name: sym,
                                balance: 0.0,
                                priceUsd: 1.0,
                                fiatValue: 0.0,
                                decimals: int.tryParse(decimalsController.text) ?? 18,
                                contractAddress: contractController.text.trim().isEmpty ? null : contractController.text.trim(),
                                isNative: false,
                              ),
                            );
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(lang.tr('token_added_success'))),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(lang.tr('add_token_btn')),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 3. Asset Filter Menu (Assets ▾ Dropdown) ---
  void _showAssetFilterMenu(
    BuildContext context,
    AssetController assetController,
    LanguageController lang,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.tr('filter_assets'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text(lang.tr('hide_small_balances'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  value: assetController.hideSmallBalances,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    assetController.toggleHideSmallBalances();
                    setSheetState(() {});
                  },
                ),
                SwitchListTile(
                  title: Text(lang.tr('sort_by_value'), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                  value: assetController.sortByBalance,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    assetController.toggleSortByBalance();
                    setSheetState(() {});
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }  Widget _buildWalletDrawer(
    BuildContext context,
    WalletController walletController,
    NetworkController networkController,
    AssetController assetController,
  ) {
    // 1. Get networks that user currently has wallets for
    final existingNetworkIds = walletController.wallets
        .map((w) => w.networkId.toLowerCase())
        .toSet();
    
    final userNetworks = networkController.allNetworks
        .where((net) => existingNetworkIds.contains(net.id.toLowerCase()))
        .toList();

    // Default selected drawer network to active wallet's network or first available
    final currentActiveNetworkId = walletController.activeWallet?.networkId.toLowerCase();
    if (_selectedDrawerNetworkId == null ||
        !existingNetworkIds.contains(_selectedDrawerNetworkId!.toLowerCase())) {
      _selectedDrawerNetworkId = currentActiveNetworkId ?? (userNetworks.isNotEmpty ? userNetworks.first.id : 'polygon');
    }

    final selectedNetwork = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == _selectedDrawerNetworkId?.toLowerCase(),
      orElse: () => userNetworks.isNotEmpty ? userNetworks.first : networkController.allNetworks.first,
    );

    // 2. Filter wallets by currently selected network in the drawer
    final networkWallets = walletController.wallets
        .where((w) => w.networkId.toLowerCase() == selectedNetwork.id.toLowerCase())
        .toList();

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Rail: Only networks user has wallets for
            Container(
              width: 64,
              color: const Color(0xFFF8FAFC),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    ...userNetworks.map((net) {
                      final isSelected = (_selectedDrawerNetworkId ?? '').toLowerCase() == net.id.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDrawerNetworkId = net.id;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: const Color(0xFF2563EB), width: 2.5)
                                  : Border.all(color: Colors.transparent, width: 2.5),
                            ),
                            child: CryptoIcon(networkId: net.id, size: 36),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    // Add chain / network button
                    IconButton(
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF64748B), size: 28),
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
            ),

            // Right Area: Wallet List strictly for Selected Chain
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

                    // Chain Name + Add Wallet button for this chain
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedNetwork.name,
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
                            showAddWalletActionSheet(context, network: selectedNetwork);
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.add_circle_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Filtered Wallet Cards
                    Expanded(
                      child: networkWallets.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.account_balance_wallet_outlined, size: 48, color: Color(0xFF94A3B8)),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No wallets on ${selectedNetwork.name}',
                                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      showAddWalletActionSheet(context, network: selectedNetwork);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('Add Wallet', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              children: networkWallets.map((wallet) {
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
