import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_styles.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';
import '../transfer/send_screen.dart';

class DAppItem {
  final String name;
  final String category;
  final String url;
  final String description;
  final String network;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const DAppItem({
    required this.name,
    required this.category,
    required this.url,
    required this.description,
    required this.network,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });
}

class SearchHubScreen extends StatefulWidget {
  const SearchHubScreen({super.key});

  @override
  State<SearchHubScreen> createState() => _SearchHubScreenState();
}

class _SearchHubScreenState extends State<SearchHubScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  int _selectedCategoryIndex = 0; // 0: All, 1: Tokens, 2: DApps, 3: Networks

  List<String> _recentSearches = ['Uniswap', 'USDT', 'PancakeSwap', 'Polygon', 'AAVE'];

  final List<String> _trendingSearches = [
    'Uniswap',
    'USDT',
    'PancakeSwap',
    'QuickSwap',
    'AAVE',
    'Polygon',
    'BNB Chain',
    'Base',
    'Safe',
    'OpenSea',
  ];

  final List<DAppItem> _allDApps = const [
    DAppItem(
      name: 'Uniswap V3',
      category: 'DEX',
      url: 'https://app.uniswap.org',
      description: 'Decentralized automated liquidity & trading protocol',
      network: 'Ethereum / Polygon / Base',
      icon: Icons.swap_horiz_rounded,
      iconColor: Color(0xFFFF007A),
      iconBg: Color(0xFFFFF0F7),
    ),
    DAppItem(
      name: 'PancakeSwap',
      category: 'DEX',
      url: 'https://pancakeswap.finance',
      description: 'Leading DEX on BNB Smart Chain & multi-chains',
      network: 'BNB Chain / Base',
      icon: Icons.cake_rounded,
      iconColor: Color(0xFFD1884F),
      iconBg: Color(0xFFFFF7ED),
    ),
    DAppItem(
      name: 'QuickSwap',
      category: 'DEX',
      url: 'https://quickswap.exchange',
      description: 'Next-gen DEX on Polygon with low gas fees',
      network: 'Polygon',
      icon: Icons.flash_on_rounded,
      iconColor: Color(0xFF3B82F6),
      iconBg: Color(0xFFEFF6FF),
    ),
    DAppItem(
      name: 'Aave V3',
      category: 'DeFi',
      url: 'https://app.aave.com',
      description: 'Open source liquidity protocol for lending & borrowing',
      network: 'Multi-Chain',
      icon: Icons.account_balance_rounded,
      iconColor: Color(0xFF8B5CF6),
      iconBg: Color(0xFFF5F3FF),
    ),
    DAppItem(
      name: 'OpenSea',
      category: 'NFT',
      url: 'https://opensea.io',
      description: 'World largest Web3 marketplace for NFTs and crypto collectibles',
      network: 'Multi-Chain',
      icon: Icons.storefront_rounded,
      iconColor: Color(0xFF2081E2),
      iconBg: Color(0xFFF0F7FF),
    ),
    DAppItem(
      name: 'Stargate Finance',
      category: 'Bridge',
      url: 'https://stargate.finance',
      description: 'Fully composable native asset bridge built on LayerZero',
      network: 'Multi-Chain',
      icon: Icons.alt_route_rounded,
      iconColor: Color(0xFF10B981),
      iconBg: Color(0xFFECFDF5),
    ),
    DAppItem(
      name: 'Safe (Gnosis Safe)',
      category: 'Tools',
      url: 'https://app.safe.global',
      description: 'Most trusted smart contract multi-signature vault infrastructure',
      network: 'Multi-Chain',
      icon: Icons.shield_rounded,
      iconColor: Color(0xFF0284C7),
      iconBg: Color(0xFFF0F9FF),
    ),
    DAppItem(
      name: '1inch Network',
      category: 'DEX',
      url: 'https://app.1inch.io',
      description: 'DEX aggregator offering best routing across liquidity sources',
      network: 'Multi-Chain',
      icon: Icons.trending_up_rounded,
      iconColor: Color(0xFF1E293B),
      iconBg: Color(0xFFF1F5F9),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 10) {
        _recentSearches = _recentSearches.sublist(0, 10);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final walletController = context.watch<WalletController>();
    final query = _searchController.text.trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // Top Search Bar
            _buildSearchBar(context, lang),

            // Category Filter Tabs
            _buildCategoryTabs(lang),

            // Search Content / Results
            Expanded(
              child: query.isEmpty
                  ? _buildEmptyStateView(context, lang)
                  : _buildSearchResultsView(
                      context,
                      lang,
                      query,
                      networkController,
                      assetController,
                      walletController,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, LanguageController lang) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
            ),
          ),

          // Search Field Container
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 22, color: Color(0xFF64748B)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _onSearchSubmit,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: lang.tr('search_placeholder'),
                        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.cancel_rounded, size: 20, color: Color(0xFF94A3B8)),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Search or Cancel Button
          GestureDetector(
            onTap: () {
              if (_searchController.text.isNotEmpty) {
                _onSearchSubmit(_searchController.text);
              } else {
                Navigator.of(context).pop();
              }
            },
            child: Text(
              _searchController.text.isNotEmpty ? lang.tr('search_hub_title') : lang.tr('cancel'),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs(LanguageController lang) {
    final tabs = [
      lang.tr('search_all'),
      lang.tr('search_tokens'),
      lang.tr('search_dapps'),
      lang.tr('search_networks'),
    ];

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = _selectedCategoryIndex == index;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryIndex = index;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Text(
                  tabs[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyStateView(BuildContext context, LanguageController lang) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.tr('recent_searches'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _recentSearches.clear();
                    });
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        lang.tr('clear_history'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((item) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = item;
                    _onSearchSubmit(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // 2. Trending Searches
          Row(
            children: [
              const Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Text(
                lang.tr('trending_searches'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _trendingSearches.map((item) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = item;
                  _onSearchSubmit(item);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 3. Recommended Web3 DApps
          Text(
            lang.tr('tab_discover'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 10),
          ..._allDApps.map((dapp) => _buildDAppCard(context, dapp, lang)),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(
    BuildContext context,
    LanguageController lang,
    String query,
    NetworkController networkController,
    AssetController assetController,
    WalletController walletController,
  ) {
    final lower = query.toLowerCase();

    // Check if query is EVM address or transaction hash
    final isEvmAddress = query.startsWith('0x') && query.length >= 10;
    final isUrl = lower.contains('.') && (lower.startsWith('http') || !lower.contains(' '));

    // Match Tokens
    final matchedTokens = assetController.tokens.where((t) {
      return t.symbol.toLowerCase().contains(lower) ||
          t.name.toLowerCase().contains(lower) ||
          (t.contractAddress != null && t.contractAddress!.toLowerCase().contains(lower));
    }).toList();

    // Match DApps
    final matchedDApps = _allDApps.where((d) {
      return d.name.toLowerCase().contains(lower) ||
          d.category.toLowerCase().contains(lower) ||
          d.description.toLowerCase().contains(lower) ||
          d.url.toLowerCase().contains(lower);
    }).toList();

    // Match Networks
    final matchedNetworks = networkController.allNetworks.where((n) {
      return n.name.toLowerCase().contains(lower) ||
          n.symbol.toLowerCase().contains(lower) ||
          n.id.toLowerCase().contains(lower);
    }).toList();

    final showTokens = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 1;
    final showDApps = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 2;
    final showNetworks = _selectedCategoryIndex == 0 || _selectedCategoryIndex == 3;

    final hasResults = (showTokens && matchedTokens.isNotEmpty) ||
        (showDApps && matchedDApps.isNotEmpty) ||
        (showNetworks && matchedNetworks.isNotEmpty) ||
        isEvmAddress ||
        isUrl;

    if (!hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              lang.tr('no_search_results'),
              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Direct Web URL Direct Visit Card
        if (isUrl) ...[
          CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Visit Website / DApp',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        query.startsWith('http') ? query : 'https://$query',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _openDAppDialog(
                    context,
                    DAppItem(
                      name: query,
                      category: 'Web',
                      url: query.startsWith('http') ? query : 'https://$query',
                      description: 'Direct browser link',
                      network: 'Web3',
                      icon: Icons.language_rounded,
                      iconColor: AppColors.primary,
                      iconBg: const Color(0xFFEFF6FF),
                    ),
                    lang,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(lang.tr('open_dapp'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        // 2. Direct EVM Address Card
        if (isEvmAddress) ...[
          CustomCard(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.send_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recipient EVM Address',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        query,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SendScreen(initialRecipient: query),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(lang.tr('action_send'), style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        // 3. Matched Tokens Section
        if (showTokens && matchedTokens.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Text(
              lang.tr('search_tokens'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          ...matchedTokens.map((token) {
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CryptoIcon(networkId: token.networkId, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              token.symbol,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                token.networkId.toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          token.name,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${token.priceUsd.toStringAsFixed(token.priceUsd < 1 ? 4 : 2)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${token.change24h >= 0 ? '+' : ''}${token.change24h.toStringAsFixed(2)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: token.change24h >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],

        // 4. Matched DApps Section
        if (showDApps && matchedDApps.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              lang.tr('search_dapps'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          ...matchedDApps.map((dapp) => _buildDAppCard(context, dapp, lang)),
        ],

        // 5. Matched Networks Section
        if (showNetworks && matchedNetworks.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Text(
              lang.tr('search_networks'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
            ),
          ),
          ...matchedNetworks.map((net) {
            return CustomCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CryptoIcon(networkId: net.id, size: 36),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          net.name,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          'Chain ID: ${net.chainId} • ${net.symbol}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildDAppCard(BuildContext context, DAppItem dapp, LanguageController lang) {
    return CustomCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: dapp.iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(dapp.icon, color: dapp.iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dapp.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        dapp.category,
                        style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  dapp.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _openDAppDialog(context, dapp, lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              lang.tr('open_dapp'),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openDAppDialog(BuildContext context, DAppItem dapp, LanguageController lang) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: dapp.iconBg, borderRadius: BorderRadius.circular(12)),
                    child: Icon(dapp.icon, color: dapp.iconColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dapp.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        Text(
                          dapp.url,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dapp.description,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Supported Chains: ${dapp.network}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: dapp.url));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.tr('copied'))),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(lang.tr('copy')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening ${dapp.name} in Web3 browser...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(lang.tr('open_dapp')),
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
}
