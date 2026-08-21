import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/language_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';
import '../search/search_hub_screen.dart';

class DAppItem {
  final String id;
  final String name;
  final String category; // 'defi', 'nft', 'tools', 'social'
  final String network;
  final String url;
  final String descriptionEn;
  final String descriptionZh;
  final IconData iconData;
  final Color iconBg;

  const DAppItem({
    required this.id,
    required this.name,
    required this.category,
    required this.network,
    required this.url,
    required this.descriptionEn,
    required this.descriptionZh,
    required this.iconData,
    required this.iconBg,
  });
}

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _selectedCategory = 'all';
  String _selectedChain = 'all';
  final Set<String> _bookmarkedDApps = {'uniswap', 'quickswap', 'opensea'};

  final List<DAppItem> _allDApps = const [
    DAppItem(
      id: 'uniswap',
      name: 'Uniswap V3',
      category: 'defi',
      network: 'Ethereum / Polygon',
      url: 'https://app.uniswap.org',
      descriptionEn: 'The most popular decentralized trading protocol with concentrated liquidity.',
      descriptionZh: '全球最顶级的去中心化交易所，提供最高效的流动性做市与闪兑。',
      iconData: Icons.swap_horizontal_circle_rounded,
      iconBg: Color(0xFFFF007A),
    ),
    DAppItem(
      id: 'quickswap',
      name: 'QuickSwap',
      category: 'defi',
      network: 'Polygon',
      url: 'https://quickswap.exchange',
      descriptionEn: 'Leading DEX on Polygon PoS & Polygon zkEVM with ultra-low gas fees.',
      descriptionZh: 'Polygon 生态头部 DEX，极速低滑点交易并享超低 Gas 费。',
      iconData: Icons.flash_on_rounded,
      iconBg: Color(0xFF0070F3),
    ),
    DAppItem(
      id: 'aave',
      name: 'Aave V3',
      category: 'defi',
      network: 'Multi-chain',
      url: 'https://app.aave.com',
      descriptionEn: 'Non-custodial liquidity protocol to earn interest on deposits & borrow assets.',
      descriptionZh: '非托管流动性借贷市场，存入资产赚取利息或进行无抵押闪电贷。',
      iconData: Icons.account_balance_rounded,
      iconBg: Color(0xFFB6509E),
    ),
    DAppItem(
      id: 'opensea',
      name: 'OpenSea',
      category: 'nft',
      network: 'Multi-chain',
      url: 'https://opensea.io',
      descriptionEn: 'World’s first and largest Web3 marketplace for NFTs and crypto collectibles.',
      descriptionZh: '全球最大的 NFT 与数字藏品交易市场，探索独特的 Web3 艺术品。',
      iconData: Icons.storefront_rounded,
      iconBg: Color(0xFF2081E2),
    ),
    DAppItem(
      id: 'magiceden',
      name: 'Magic Eden',
      category: 'nft',
      network: 'Solana / Polygon',
      url: 'https://magiceden.io',
      descriptionEn: 'Cross-chain NFT marketplace and gaming launchpad.',
      descriptionZh: '领先的跨链 NFT 交易市场与链游 Launchpad 平台。',
      iconData: Icons.auto_awesome_rounded,
      iconBg: Color(0xFFE42575),
    ),
    DAppItem(
      id: 'revoke',
      name: 'Revoke.cash',
      category: 'tools',
      network: 'Multi-chain',
      url: 'https://revoke.cash',
      descriptionEn: 'Protect your assets by managing and revoking your token allowances.',
      descriptionZh: '一键排查并撤销高风险智能合约代币无限授权，守护资产安全。',
      iconData: Icons.gpp_good_rounded,
      iconBg: Color(0xFF10B981),
    ),
    DAppItem(
      id: 'etherscan',
      name: 'Etherscan',
      category: 'tools',
      network: 'Ethereum',
      url: 'https://etherscan.io',
      descriptionEn: 'The leading block explorer and analytics platform for Ethereum.',
      descriptionZh: '以太坊区块链主流浏览器与链上智能合约分析平台。',
      iconData: Icons.travel_explore_rounded,
      iconBg: Color(0xFF3B82F6),
    ),
    DAppItem(
      id: 'polygonscan',
      name: 'Polygonscan',
      category: 'tools',
      network: 'Polygon',
      url: 'https://polygonscan.com',
      descriptionEn: 'Block Explorer and Analytics Platform for Polygon Network.',
      descriptionZh: 'Polygon 网络官方区块浏览器，查询链上交易与合约源码。',
      iconData: Icons.search_rounded,
      iconBg: Color(0xFF8247E5),
    ),
    DAppItem(
      id: 'debank',
      name: 'DeBank',
      category: 'tools',
      network: 'Multi-chain',
      url: 'https://debank.com',
      descriptionEn: 'The real Web3-native messenger & best Web3 portfolio tracker.',
      descriptionZh: '全网最精准的 Web3 资产看板与多链钱包收益跟踪工具。',
      iconData: Icons.pie_chart_rounded,
      iconBg: Color(0xFFF97316),
    ),
    DAppItem(
      id: 'lens',
      name: 'Lens Protocol',
      category: 'social',
      network: 'Polygon',
      url: 'https://lens.xyz',
      descriptionEn: 'The open-source Web3 social graph protocol built on Polygon.',
      descriptionZh: '构建于 Polygon 上的开源 Web3 社交图谱协议，数据由用户自主掌控。',
      iconData: Icons.people_alt_rounded,
      iconBg: Color(0xFF00501E),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final isZh = lang.currentLanguage == AppLanguage.zh;

    final filteredDApps = _allDApps.where((dapp) {
      if (_selectedCategory != 'all' && dapp.category != _selectedCategory) {
        return false;
      }
      if (_selectedChain != 'all' &&
          !dapp.network.toLowerCase().contains(_selectedChain.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          lang.tr('discover_title'),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF1E293B)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SearchHubScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Search Bar Trigger
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SearchHubScreen()),
                  );
                },
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Text(
                        lang.tr('search_dapp_or_url'),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Ecosystem Filter Chips
            _buildEcosystemChips(),

            const SizedBox(height: 8),

            // Featured Carousel Banners
            _buildFeaturedCarousel(isZh),

            const SizedBox(height: 16),

            // Category Segmented Tabs
            _buildCategoryTabs(lang),

            const SizedBox(height: 12),

            // DApp List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredDApps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (ctx, i) {
                  final dapp = filteredDApps[i];
                  return _buildDAppCard(context, dapp, isZh, lang);
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEcosystemChips() {
    final chains = [
      {'id': 'all', 'name': 'All Chains'},
      {'id': 'polygon', 'name': 'Polygon'},
      {'id': 'ethereum', 'name': 'Ethereum'},
      {'id': 'multi-chain', 'name': 'Multi-Chain'},
      {'id': 'solana', 'name': 'Solana'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: chains.map((c) {
          final isSel = _selectedChain == c['id'];
          return GestureDetector(
            onTap: () => setState(() => _selectedChain = c['id']!),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSel ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                c['name']!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                  color: isSel ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFeaturedCarousel(bool isZh) {
    final banners = [
      {
        'title': 'Transit Cross-chain Swap',
        'sub': isZh ? '聚合全网流动性，1秒闪兑' : 'Aggregate all DEX liquidity in 1 click',
        'color': const Color(0xFF2563EB),
        'icon': Icons.swap_horiz_rounded,
      },
      {
        'title': 'Polygon PoS 2.0 Hub',
        'sub': isZh ? '超低 Gas 费体验 Layer2 生态' : 'Experience next-gen low gas DeFi',
        'color': const Color(0xFF7C3AED),
        'icon': Icons.flash_on_rounded,
      },
      {
        'title': 'Web3 Security Radar',
        'sub': isZh ? '智能检测授权与蜜罐代币' : 'Scan approvals & honeypot risks',
        'color': const Color(0xFF059669),
        'icon': Icons.security_rounded,
      },
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: banners.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final b = banners[i];
          return Container(
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [(b['color'] as Color), (b['color'] as Color).withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (b['color'] as Color).withValues(alpha: 0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        b['title'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        b['sub'] as String,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(b['icon'] as IconData, color: Colors.white, size: 24),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryTabs(LanguageController lang) {
    final categories = [
      {'id': 'all', 'label': lang.tr('category_all')},
      {'id': 'defi', 'label': lang.tr('category_defi')},
      {'id': 'nft', 'label': lang.tr('category_nft')},
      {'id': 'tools', 'label': lang.tr('category_tools')},
      {'id': 'social', 'label': lang.tr('category_social')},
    ];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((cat) {
            final isSel = _selectedCategory == cat['id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat['id']!),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSel ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  cat['label']!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                    color: isSel ? AppColors.primary : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDAppCard(
    BuildContext context,
    DAppItem dapp,
    bool isZh,
    LanguageController lang,
  ) {
    final isBookmarked = _bookmarkedDApps.contains(dapp.id);

    return CustomCard(
      padding: const EdgeInsets.all(14),
      child: InkWell(
        onTap: () => _showDAppLaunchSheet(context, dapp, isZh, lang),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: dapp.iconBg.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(dapp.iconData, color: dapp.iconBg, size: 26),
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          dapp.network,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isZh ? dapp.descriptionZh : dapp.descriptionEn,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isBookmarked ? Icons.star_rounded : Icons.star_outline_rounded,
                color: isBookmarked ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                size: 22,
              ),
              onPressed: () {
                setState(() {
                  if (isBookmarked) {
                    _bookmarkedDApps.remove(dapp.id);
                  } else {
                    _bookmarkedDApps.add(dapp.id);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDAppLaunchSheet(
    BuildContext context,
    DAppItem dapp,
    bool isZh,
    LanguageController lang,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: dapp.iconBg.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(dapp.iconData, color: dapp.iconBg, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dapp.name,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dapp.url,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
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
                      isZh ? dapp.descriptionZh : dapp.descriptionEn,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.shield_outlined, size: 14, color: Color(0xFF10B981)),
                        const SizedBox(width: 4),
                        Text(
                          'Network: ${dapp.network}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Security warning tip
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 18, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        lang.tr('dapp_warning'),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Open DApp Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(lang.tr('dapp_visit_notice', params: {'dapp': dapp.name})),
                        backgroundColor: const Color(0xFF2563EB),
                      ),
                    );
                  },
                  child: Text(
                    lang.tr('dapp_launch_btn'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
