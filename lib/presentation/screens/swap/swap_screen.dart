import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/token.dart';
import '../../../domain/models/wallet.dart';
import '../../../services/crypto_key_service.dart';
import '../../../services/environment_service.dart';
import '../../../services/lifi_swap_service.dart';
import '../../../services/onchain_transaction_service.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/environment_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

enum SwapProviderOption { lifi, transit, quickswap }

class SwapRecord {
  final String fromSymbol;
  final String toSymbol;
  final double fromAmount;
  final double toAmount;
  final DateTime timestamp;
  final String? txHash;
  final String? explorerUrl;
  final String providerName;

  const SwapRecord({
    required this.fromSymbol,
    required this.toSymbol,
    required this.fromAmount,
    required this.toAmount,
    required this.timestamp,
    this.txHash,
    this.explorerUrl,
    this.providerName = 'Li.Fi / Transit',
  });
}

class SwapScreen extends StatefulWidget {
  final bool isStandalonePage;

  const SwapScreen({super.key, this.isStandalonePage = true});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _fromAmountController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final ILifiSwapService _lifiSwapService = LifiSwapService();

  Token? _fromToken;
  Token? _toToken;
  double _slippage = 0.5;
  SwapProviderOption _selectedProvider = SwapProviderOption.lifi;

  bool _isQuoting = false;
  bool _isSwapping = false;
  String? _quoteError;
  LifiSwapQuote? _currentQuote;
  Timer? _debounceTimer;

  final List<SwapRecord> _swapHistory = [];
  late AnimationController _flipAnimController;

  @override
  void initState() {
    super.initState();
    _flipAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fromAmountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _fromAmountController.dispose();
    _recipientController.dispose();
    _flipAnimController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        _fetchLiveQuote();
      }
    });
  }

  Future<void> _fetchLiveQuote() async {
    final amountText = _fromAmountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 0 || _fromToken == null || _toToken == null) {
      if (mounted) {
        setState(() {
          _currentQuote = null;
          _quoteError = null;
          _isQuoting = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isQuoting = true;
        _quoteError = null;
      });
    }

    final networkController = context.read<NetworkController>();
    final walletController = context.read<WalletController>();
    final activeWallet = walletController.activeWallet;

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == (activeWallet?.networkId ?? 'polygon').toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    try {
      final quote = await _lifiSwapService.getQuote(
        network: network,
        fromToken: _fromToken!,
        toToken: _toToken!,
        fromAmount: amount,
        walletAddress: activeWallet?.address ?? '0x0000000000000000000000000000000000000000',
        slippage: _slippage,
      );

      if (mounted) {
        setState(() {
          _currentQuote = quote;
          _isQuoting = false;
          _quoteError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _quoteError = e.toString().replaceAll('Exception: ', '');
          _isQuoting = false;
        });
      }
    }
  }

  void _switchTokens() {
    _flipAnimController.forward(from: 0.0);
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;
    });
    _fetchLiveQuote();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    EnvironmentController? envController;
    try {
      envController = context.watch<EnvironmentController>();
    } catch (_) {
      envController = null;
    }

    final activeWallet = walletController.activeWallet;

    if (activeWallet == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('action_swap'))),
        body: Center(child: Text(lang.tr('no_active_wallet'))),
      );
    }

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    final tokens = assetController.tokens;
    if (tokens.isNotEmpty) {
      _fromToken ??= tokens.first;
      _toToken ??= tokens.length > 1 ? tokens[1] : tokens.first;
    }

    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    final fromPrice = _fromToken?.priceUsd ?? 0.42;
    final toPrice = _toToken?.priceUsd ?? 1.0;
    final estimatedToAmount = _currentQuote?.toAmount ?? (fromPrice > 0 && toPrice > 0 ? (fromAmount * fromPrice / toPrice) : 0.0);
    final minReceived = _currentQuote?.toAmountMin ?? (estimatedToAmount * (1 - (_slippage / 100)));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _selectedProvider == SwapProviderOption.lifi
              ? 'Li.Fi 智能闪兑 (Swap & Bridge)'
              : (_selectedProvider == SwapProviderOption.transit ? 'Transit Swap' : 'QuickSwap DEX'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // 刷新报价按钮
          IconButton(
            icon: _isQuoting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : const Icon(Icons.refresh_rounded, color: Color(0xFF1E293B)),
            tooltip: 'Refresh Quote (刷新实时报价)',
            onPressed: _isQuoting ? null : () => _fetchLiveQuote(),
          ),
          // 滑点设置按钮
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Color(0xFF1E293B)),
            tooltip: 'Slippage Settings (滑点设置)',
            onPressed: () => _showSlippageSheet(context, lang),
          ),
        ],
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Environment & Network Status Banner
              _buildEnvironmentBanner(envController, network, lang),

              const SizedBox(height: 12),

              // 2. Provider Selector (Li.Fi / Transit / QuickSwap)
              _buildProviderSelector(lang),

              const SizedBox(height: 14),

              // 3. Main Swap Exchange Card
              _buildMainSwapCard(
                context: context,
                lang: lang,
                network: network,
                activeWallet: activeWallet,
                fromAmount: fromAmount,
                fromPrice: fromPrice,
                toPrice: toPrice,
                estimatedToAmount: estimatedToAmount,
                minReceived: minReceived,
              ),

              const SizedBox(height: 16),

              // 4. Quote & Routing Breakdown Details Card
              _buildRouteDetailsCard(
                context: context,
                lang: lang,
                fromAmount: fromAmount,
                estimatedToAmount: estimatedToAmount,
                minReceived: minReceived,
              ),

              const SizedBox(height: 24),

              // 5. Swap History Section
              _buildHistorySection(lang),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentBanner(EnvironmentController? envController, Network network, LanguageController lang) {
    final isLive = envController?.isLive ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFF0FDF4) : const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.check_circle_rounded : Icons.science_rounded,
            size: 16,
            color: isLive ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isLive
                  ? '已连接 Polygon PoS 真实主网 (Real On-Chain DEX Execution)'
                  : '模拟测试环境 (Simulation Mode)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isLive ? const Color(0xFF166534) : const Color(0xFF854D0E),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              network.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isLive ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelector(LanguageController lang) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _buildProviderTabItem(
            title: '⚡ Li.Fi 智能聚合',
            option: SwapProviderOption.lifi,
          ),
          _buildProviderTabItem(
            title: 'Transit Swap',
            option: SwapProviderOption.transit,
          ),
          _buildProviderTabItem(
            title: 'QuickSwap',
            option: SwapProviderOption.quickswap,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderTabItem({required String title, required SwapProviderOption option}) {
    final isSelected = _selectedProvider == option;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedProvider != option) {
            setState(() {
              _selectedProvider = option;
            });
            _fetchLiveQuote();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainSwapCard({
    required BuildContext context,
    required LanguageController lang,
    required Network network,
    required dynamic activeWallet,
    required double fromAmount,
    required double fromPrice,
    required double toPrice,
    required double estimatedToAmount,
    required double minReceived,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 支付 (From) 卡片
          _buildAmountContainer(
            label: lang.isChinese ? '支付 (From)' : 'From',
            token: _fromToken,
            controller: _fromAmountController,
            isEditable: true,
            fiatEquivalent: fromAmount * fromPrice,
            onTapToken: () => _openTokenPicker(isFrom: true),
            onTapMax: () {
              final bal = _fromToken?.balance ?? 0.0;
              final maxBal = _fromToken?.isNative == true ? (bal > 0.01 ? bal - 0.01 : 0.0) : bal;
              _fromAmountController.text = maxBal.toStringAsFixed(maxBal >= 1 ? 4 : 6);
            },
          ),

          // 居中上下对调按钮
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Divider(color: Color(0xFFF1F5F9), thickness: 1.5),
                RotationTransition(
                  turns: Tween(begin: 0.0, end: 0.5).animate(_flipAnimController),
                  child: InkWell(
                    onTap: _switchTokens,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: AppColors.primary, size: 22),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 获得 (To) 卡片
          _buildAmountContainer(
            label: lang.isChinese ? '预计获得 (To Estimated)' : 'To (estimated)',
            token: _toToken,
            controller: TextEditingController(
              text: _isQuoting ? '...' : (estimatedToAmount > 0 ? estimatedToAmount.toStringAsFixed(4) : '0.0'),
            ),
            isEditable: false,
            fiatEquivalent: estimatedToAmount * toPrice,
            onTapToken: () => _openTokenPicker(isFrom: false),
            isLoadingQuote: _isQuoting,
          ),

          if (_quoteError != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                '提示: $_quoteError',
                style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
              ),
            ),

          const SizedBox(height: 20),

          // 闪兑确认按钮
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (_isSwapping || fromAmount <= 0)
                  ? null
                  : () => _executeSwapTransaction(
                        context: context,
                        network: network,
                        activeWallet: activeWallet,
                        fromAmount: fromAmount,
                        estimatedToAmount: estimatedToAmount,
                        minReceived: minReceived,
                      ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: const Color(0xFFCBD5E1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSwapping
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                        SizedBox(width: 12),
                        Text('正在签名并执行链上闪兑...', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      ],
                    )
                  : Text(
                      fromAmount <= 0
                          ? (lang.isChinese ? '请输入兑换金额' : 'Enter an Amount')
                          : '${lang.isChinese ? '确认闪兑' : 'Swap'} (${_fromToken?.symbol} ➔ ${_toToken?.symbol})',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountContainer({
    required String label,
    required Token? token,
    required TextEditingController controller,
    required bool isEditable,
    required double fiatEquivalent,
    required VoidCallback onTapToken,
    VoidCallback? onTapMax,
    bool isLoadingQuote = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              if (onTapMax != null && token != null)
                Row(
                  children: [
                    Text(
                      '可用: ${token.formattedBalance} ${token.symbol}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onTapMax,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '全部 (MAX)',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: isEditable
                    ? TextField(
                        controller: controller,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        decoration: const InputDecoration(
                          hintText: '0.0',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 24, fontWeight: FontWeight.w800),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : (isLoadingQuote
                        ? const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          )
                        : Text(
                            controller.text,
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          )),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onTapToken,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CryptoIcon(networkId: token?.symbol ?? 'POL', size: 24),
                      const SizedBox(width: 8),
                      Text(
                        token?.symbol ?? 'SELECT',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '≈ \$${fiatEquivalent.toStringAsFixed(2)} USD',
            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetailsCard({
    required BuildContext context,
    required LanguageController lang,
    required double fromAmount,
    required double estimatedToAmount,
    required double minReceived,
  }) {
    final rate = fromAmount > 0 ? estimatedToAmount / fromAmount : 1.0;
    final routerName = _currentQuote?.routerName ?? 'Li.Fi / QuickSwap V2';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            lang.isChinese ? '最优兑换路由 (Best Route)' : 'Best Route',
            routerName,
            isBadge: true,
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            lang.isChinese ? '参考汇率 (Exchange Rate)' : 'Rate',
            '1 ${_fromToken?.symbol} ≈ ${rate.toStringAsFixed(4)} ${_toToken?.symbol}',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            '最小获得金额 (Min Received)',
            '${minReceived.toStringAsFixed(4)} ${_toToken?.symbol}',
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => _showSlippageSheet(context, lang),
            child: _buildDetailRow(
              '滑点容差 (Slippage)',
              '$_slippage% ✏️',
              valueColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailRow('预估矿工费 (Network Gas)', '≈ 0.003 POL (\$0.001)'),
          const SizedBox(height: 10),
          _buildDetailRow('价格影响 (Price Impact)', '< 0.05%', valueColor: const Color(0xFF16A34A)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String title, String value, {bool isBadge = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? const Color(0xFF1E293B),
            ),
          ),
      ],
    );
  }

  Widget _buildHistorySection(LanguageController lang) {
    if (_swapHistory.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lang.isChinese ? '闪兑历史记录 (Swap Records)' : 'Recent Swaps',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 10),
        ..._swapHistory.map((rec) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${rec.fromAmount} ${rec.fromSymbol} ➔ ${rec.toAmount.toStringAsFixed(4)} ${rec.toSymbol}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${rec.providerName} • ${rec.timestamp.hour}:${rec.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                  if (rec.txHash != null)
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: rec.explorerUrl ?? rec.txHash!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Explorer URL copied to clipboard!')),
                        );
                      },
                    ),
                ],
              ),
            )),
      ],
    );
  }

  void _showSlippageSheet(BuildContext context, LanguageController lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '滑点容差设置 (Slippage Tolerance)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '若实际成交价格波动超出滑点设置范围，交易将自动回滚以保障您的资金安全。',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [0.1, 0.5, 1.0, 2.0].map((val) {
                    final isSel = _slippage == val;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setSheetState(() => _slippage = val);
                          setState(() => _slippage = val);
                          _fetchLiveQuote();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSel ? AppColors.primary : const Color(0xFFE2E8F0),
                              width: isSel ? 1.5 : 1.0,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$val%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel ? AppColors.primary : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTokenPicker({required bool isFrom}) {
    final assetController = context.read<AssetController>();
    final tokens = assetController.tokens;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '选择代币 (Select Token)',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView.separated(
                  itemCount: tokens.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final t = tokens[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CryptoIcon(networkId: t.symbol, size: 36),
                      title: Text(t.symbol, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text(t.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      trailing: Text(
                        t.formattedBalance,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      onTap: () {
                        Navigator.of(ctx).pop();
                        setState(() {
                          if (isFrom) {
                            _fromToken = t;
                          } else {
                            _toToken = t;
                          }
                        });
                        _fetchLiveQuote();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeSwapTransaction({
    required BuildContext context,
    required Network network,
    required dynamic activeWallet,
    required double fromAmount,
    required double estimatedToAmount,
    required double minReceived,
  }) async {
    setState(() => _isSwapping = true);

    try {
      final walletController = context.read<WalletController>();
      final cryptoService = context.read<ICryptoKeyService>();
      final onChainService = context.read<IOnChainTransactionService>();
      final secret = await walletController.getWalletSecret(activeWallet.id);

      if (secret == null || secret.isEmpty) {
        throw Exception('无法获取钱包签名私钥，请确认钱包安全配置');
      }

      final String privateKey = secret.contains(' ')
          ? cryptoService.deriveFromMnemonic(secret).privateKeyHex
          : secret;

      OnChainTxResult result;

      if (_currentQuote != null) {
        result = await _lifiSwapService.executeQuote(
          network: network,
          privateKeyHex: privateKey,
          quote: _currentQuote!,
        );
      } else {
        result = await onChainService.sendSwapTransaction(
          network: network,
          privateKeyHex: privateKey,
          fromToken: _fromToken!,
          toToken: _toToken!,
          fromAmount: fromAmount,
          minToAmount: minReceived,
        );
      }

      if (!mounted) return;
      setState(() => _isSwapping = false);

      if (result.isSuccess) {
        final newRec = SwapRecord(
          fromSymbol: _fromToken?.symbol ?? 'POL',
          toSymbol: _toToken?.symbol ?? 'USDT',
          fromAmount: fromAmount,
          toAmount: estimatedToAmount,
          timestamp: DateTime.now(),
          txHash: result.txHash,
          explorerUrl: result.explorerUrl,
          providerName: _currentQuote?.routerName ?? 'Li.Fi / Transit',
        );
        setState(() {
          _swapHistory.insert(0, newRec);
        });

        _showSuccessReceiptModal(context, newRec);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('闪兑执行失败: ${result.errorMessage}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSwapping = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('执行异常: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showSuccessReceiptModal(BuildContext context, SwapRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                '链上闪兑广播成功！',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                '${record.fromAmount} ${record.fromSymbol} ➔ ${record.toAmount.toStringAsFixed(4)} ${record.toSymbol}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('聚合路由', record.providerName),
                    const SizedBox(height: 8),
                    _buildReceiptRow('交易网络', 'Polygon PoS Mainnet'),
                    const SizedBox(height: 8),
                    _buildReceiptRow(
                      '交易哈希 (TxHash)',
                      record.txHash != null && record.txHash!.length > 18
                          ? '${record.txHash!.substring(0, 10)}...${record.txHash!.substring(record.txHash!.length - 8)}'
                          : (record.txHash ?? 'N/A'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (record.txHash != null)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: record.txHash!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('TxHash 已复制到剪贴板！')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('复制哈希'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final url = record.explorerUrl ?? 'https://polygonscan.com/tx/${record.txHash}';
                          Clipboard.setData(ClipboardData(text: url));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('浏览器链接已复制: $url')),
                          );
                          Navigator.of(ctx).pop();
                        },
                        icon: const Icon(Icons.travel_explore_rounded, size: 16),
                        label: const Text('区块浏览器'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 48),
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
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
      ],
    );
  }
}
