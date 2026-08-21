import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/market_item.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/market_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/sparkline_chart.dart';
import '../swap/swap_screen.dart';
import '../transfer/send_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  final List<Map<String, String>> _ecosystems = [
    {'id': 'all', 'name': 'All'},
    {'id': 'polygon', 'name': 'Polygon'},
    {'id': 'bnb', 'name': 'BNB Chain'},
    {'id': 'ethereum', 'name': 'Ethereum'},
    {'id': 'solana', 'name': 'Solana'},
    {'id': 'defi', 'name': 'DeFi'},
    {'id': 'meme', 'name': 'Meme'},
    {'id': 'ai', 'name': 'AI'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final market = context.watch<MarketController>();
    final items = market.displayedItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header with Global Market Stats & Search Toggle
            _buildTopHeader(context, lang, market),

            // 2. Main Market Tabs (Watchlist, Hot, Gainers, Losers, New, Ecosystem)
            _buildMainTabs(lang, market),

            // 3. Ecosystem Sub-Filter (shown when Ecosystem tab or All is active)
            if (market.currentTab == MarketTab.ecosystem) _buildEcosystemFilters(market),

            // 4. Column Headers & Sort Bar
            _buildSortHeader(lang, market),

            // 5. Token List Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: market.refreshMarket,
                color: AppColors.primary,
                child: items.isEmpty
                    ? _buildEmptyState(lang, market)
                    : ListView.builder(
                        itemCount: items.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildMarketItemRow(context, item, index + 1, lang, market);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopHeader(BuildContext context, LanguageController lang, MarketController market) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                lang.tr('tab_market'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              // Search icon toggle
              IconButton(
                icon: Icon(
                  _isSearching ? Icons.close_rounded : Icons.search_rounded,
                  color: const Color(0xFF1E293B),
                  size: 22,
                ),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      market.setSearchQuery('');
                    }
                  });
                },
              ),
            ],
          ),

          // Search Field (when toggled)
          if (_isSearching) ...[
            const SizedBox(height: 8),
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      onChanged: (val) => market.setSearchQuery(val),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        hintText: lang.tr('search_market_hint'),
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
                        market.setSearchQuery('');
                      },
                      child: const Icon(Icons.cancel_rounded, size: 18, color: Color(0xFF94A3B8)),
                    ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          // Global Market Overview Pills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatPill(
                  lang.tr('global_market_cap'),
                  '\$2.68T',
                  '+${market.marketCapChange24h}%',
                  true,
                ),
                Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),
                _buildStatPill(
                  lang.tr('global_24h_vol'),
                  '\$89.5B',
                  null,
                  false,
                ),
                Container(height: 18, width: 1, color: const Color(0xFFE2E8F0)),
                _buildStatPill(
                  lang.tr('btc_dominance'),
                  '${market.btcDominance}%',
                  null,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String label, String value, String? change, bool isPositive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        const SizedBox(height: 1),
        Row(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),
            if (change != null) ...[
              const SizedBox(width: 3),
              Text(
                change,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildMainTabs(LanguageController lang, MarketController market) {
    final tabs = [
      {'tab': MarketTab.watchlist, 'label': lang.tr('market_watchlist')},
      {'tab': MarketTab.hot, 'label': lang.tr('market_hot')},
      {'tab': MarketTab.gainers, 'label': lang.tr('market_gainers')},
      {'tab': MarketTab.losers, 'label': lang.tr('market_losers')},
      {'tab': MarketTab.newListings, 'label': lang.tr('market_new')},
      {'tab': MarketTab.ecosystem, 'label': lang.tr('market_ecosystem')},
    ];

    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((t) {
            final isSelected = market.currentTab == t['tab'];
            return GestureDetector(
              onTap: () => market.setTab(t['tab'] as MarketTab),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Text(
                  t['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEcosystemFilters(MarketController market) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _ecosystems.map((eco) {
            final isSelected = market.selectedEcosystem == eco['id'];
            return GestureDetector(
              onTap: () => market.setEcosystem(eco['id']!),
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  eco['name']!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? AppColors.primary : const Color(0xFF64748B),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSortHeader(LanguageController lang, MarketController market) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // 1. Name / Volume
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => market.toggleSort(MarketSortField.name),
            child: Row(
              children: [
                Text(
                  lang.tr('sort_name_vol'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
                _buildSortIcon(market, MarketSortField.name),
              ],
            ),
          ),
          const Spacer(),
          // 2. Last Price
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => market.toggleSort(MarketSortField.price),
            child: Row(
              children: [
                Text(
                  lang.tr('sort_last_price'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
                _buildSortIcon(market, MarketSortField.price),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // 3. 24h Change
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => market.toggleSort(MarketSortField.change),
            child: Row(
              children: [
                Text(
                  lang.tr('sort_24h_change'),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
                ),
                _buildSortIcon(market, MarketSortField.change),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortIcon(MarketController market, MarketSortField field) {
    if (market.sortField != field) {
      return const Icon(Icons.unfold_more_rounded, size: 14, color: Color(0xFFCBD5E1));
    }
    return Icon(
      market.sortOrder == MarketSortOrder.ascending ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
      size: 16,
      color: AppColors.primary,
    );
  }

  Widget _buildMarketItemRow(
    BuildContext context,
    MarketItem item,
    int index,
    LanguageController lang,
    MarketController market,
  ) {
    final isPos = item.change24h >= 0;

    return CustomCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      onTap: () => _showTokenDetailSheet(context, item, lang, market),
      child: Row(
        children: [
          // 1. Rank Badge (#1-#3 colored, #4+ grey)
          SizedBox(
            width: 24,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: index == 1
                    ? const Color(0xFFF59E0B) // Gold
                    : (index == 2
                        ? const Color(0xFF94A3B8) // Silver
                        : (index == 3 ? const Color(0xFFD97706) : const Color(0xFFCBD5E1))),
              ),
            ),
          ),

          // 2. Token Icon
          CryptoIcon(networkId: item.networkId, size: 36),
          const SizedBox(width: 10),

          // 3. Symbol & 24h Volume
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.symbol,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(fontSize: 9, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  item.formattedVolume,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // 4. Sparkline Mini-Chart
          SparklineChart(
            data: item.sparkline,
            isPositive: isPos,
            width: 58,
            height: 26,
          ),
          const SizedBox(width: 10),

          // 5. Price & Change Pill
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.formattedPrice,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isPos ? '+' : ''}${item.change24h.toStringAsFixed(2)}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 6. Favorite Star Button
          GestureDetector(
            onTap: () => market.toggleFavorite(item.id),
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                item.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                color: item.isFavorite ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageController lang, MarketController market) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_outline_rounded, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            Text(
              market.currentTab == MarketTab.watchlist ? lang.tr('empty_watchlist_tip') : lang.tr('no_search_results'),
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // --- Detailed Token Market Sheet ---
  void _showTokenDetailSheet(
    BuildContext context,
    MarketItem item,
    LanguageController lang,
    MarketController market,
  ) {
    final isPos = item.change24h >= 0;
    String selectedTf = '24H';
    final timeframes = ['1H', '24H', '7D', '1M', '1Y', 'ALL'];

    List<double> getChartData(String tf) {
      switch (tf) {
        case '1H':
          return [item.sparkline.last * 0.998, item.sparkline.last * 0.999, item.sparkline.last * 1.001, item.sparkline.last];
        case '24H':
          return item.sparkline;
        case '7D':
          return [item.sparkline.first * 0.94, item.sparkline.first * 0.96, item.sparkline[2], item.sparkline.last * 0.98, item.sparkline.last * 1.02, item.sparkline.last];
        case '1M':
          return [item.sparkline.first * 0.85, item.sparkline.first * 0.90, item.sparkline.first * 0.95, item.sparkline.last * 1.05, item.sparkline.last];
        case '1Y':
          return [item.sparkline.first * 0.60, item.sparkline.first * 0.75, item.sparkline.first * 0.90, item.sparkline.last];
        case 'ALL':
          return [item.sparkline.first * 0.30, item.sparkline.first * 0.50, item.sparkline.first * 0.80, item.sparkline.last];
        default:
          return item.sparkline;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final chartData = getChartData(selectedTf);

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header with Token info & Favorite Star
                    Row(
                      children: [
                        CryptoIcon(networkId: item.networkId, size: 42),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    item.symbol,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item.networkId.toUpperCase(),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                item.name,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            market.isFavorite(item.id) ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: market.isFavorite(item.id) ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
                            size: 26,
                          ),
                          onPressed: () {
                            market.toggleFavorite(item.id);
                            setSheetState(() {});
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Large Price Header & 24h Change Pill
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          item.formattedPrice,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isPos ? '+' : ''}${item.change24h.toStringAsFixed(2)}%',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Timeframe Selector Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: timeframes.map((tf) {
                        final isSelected = selectedTf == tf;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedTf = tf),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tf,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Interactive Chart Container
                    Container(
                      height: 140,
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: SparklineChart(
                        data: chartData,
                        isPositive: isPos,
                        width: double.infinity,
                        height: 120,
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Key Market Statistics Grid
                  const Text(
                    'Market Statistics',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        _buildDetailStatRow(lang.tr('market_cap_stat'), item.formattedMarketCap, 'Rank #${item.rank}'),
                        const Divider(height: 16),
                        _buildDetailStatRow(lang.tr('sort_name_vol'), item.formattedVolume, '24h Volume'),
                        const Divider(height: 16),
                        _buildDetailStatRow(lang.tr('high_24h'), '\$${item.high24h.toStringAsFixed(2)}', '24h High'),
                        const Divider(height: 16),
                        _buildDetailStatRow(lang.tr('low_24h'), '\$${item.low24h.toStringAsFixed(2)}', '24h Low'),
                      ],
                    ),
                  ),

                  if (item.contractAddress != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.code_rounded, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Contract: ${item.contractAddress!.substring(0, 6)}...${item.contractAddress!.substring(item.contractAddress!.length - 4)}',
                              style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: Color(0xFF475569)),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: item.contractAddress!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(lang.tr('copied'))),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => SendScreen(initialTokenSymbol: item.symbol)),
                            );
                          },
                          icon: const Icon(Icons.send_rounded, size: 16),
                          label: Text(lang.tr('action_send')),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SwapScreen(isStandalonePage: true)),
                            );
                          },
                          icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                          label: Text(lang.tr('trade_now')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      },
    ),
  );
}

  Widget _buildDetailStatRow(String label, String value, String sub) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ],
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
        ),
      ],
    );
  }
}
