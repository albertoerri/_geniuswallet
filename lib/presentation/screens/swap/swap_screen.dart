import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/token.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

class SwapRecord {
  final String fromSymbol;
  final String toSymbol;
  final double fromAmount;
  final double toAmount;
  final DateTime timestamp;

  const SwapRecord({
    required this.fromSymbol,
    required this.toSymbol,
    required this.fromAmount,
    required this.toAmount,
    required this.timestamp,
  });
}

class SwapScreen extends StatefulWidget {
  final bool isStandalonePage;

  const SwapScreen({super.key, this.isStandalonePage = true});

  @override
  State<SwapScreen> createState() => _SwapScreenState();
}

class _SwapScreenState extends State<SwapScreen> {
  int _activeTopTab = 0; // 0: Swap&Bridge, 1: Limit Order
  final _fromAmountController = TextEditingController();
  Token? _fromToken;
  Token? _toToken;
  double _slippage = 2.0;
  bool _isSwapping = false;
  final List<SwapRecord> _swapHistory = [];

  @override
  void dispose() {
    _fromAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final activeWallet = walletController.activeWallet;

    if (activeWallet == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('action_swap'))),
        body: Center(child: Text(lang.tr('no_active_wallet'))),
      );
    }

    final tokens = assetController.tokens;
    if (tokens.isNotEmpty) {
      _fromToken ??= tokens.first;
      _toToken ??= tokens.length > 1 ? tokens[1] : tokens.first;
    }

    final fromAmount = double.tryParse(_fromAmountController.text) ?? 0.0;
    final fromPrice = _fromToken?.priceUsd ?? 1.0;
    final toPrice = _toToken?.priceUsd ?? 1.0;
    final rate = toPrice > 0 ? fromPrice / toPrice : 1.0;
    final estimatedToAmount = fromAmount * rate;
    final minReceived = estimatedToAmount * (1 - (_slippage / 100));

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Segmented Tabs (Swap&Bridge / Limit Order)
          _buildTopTabs(lang),

          const SizedBox(height: 16),

          // Main Swap Card
          CustomCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transit Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transit Swap',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(lang.tr('rates_updated'))),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showSlippageSheet(context, lang),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // From Box
                _buildFromCard(context, tokens, lang),

                const SizedBox(height: 8),

                // Middle Swap Flip Button
                Center(
                  child: GestureDetector(
                    onTap: _flipTokens,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.swap_vert_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // To Box
                _buildToCard(context, tokens, estimatedToAmount, lang),

                const SizedBox(height: 18),

                // Swap Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: fromAmount <= 0 || _isSwapping
                        ? null
                        : () => _handleSwap(context, fromAmount, estimatedToAmount, lang),
                    child: _isSwapping
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            fromAmount <= 0 ? lang.tr('btn_enter_amount') : lang.tr('btn_swap_now'),
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Rate & Route Breakdown
                _buildDetailsBox(rate, minReceived, lang),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Last Record Section
          Text(
            lang.tr('last_record'),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),

          _swapHistory.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFFCBD5E1)),
                      const SizedBox(height: 8),
                      Text(
                        lang.tr('no_tx_records'),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _swapHistory.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final rec = _swapHistory[i];
                    return CustomCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFECFDF5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${rec.fromSymbol} ➔ ${rec.toSymbol}',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${rec.fromAmount} ${rec.fromSymbol}  ➔  ${rec.toAmount.toStringAsFixed(4)} ${rec.toSymbol}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Text(
                            lang.tr('success'),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          const SizedBox(height: 32),
        ],
      ),
    );

    if (!widget.isStandalonePage) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        body: SafeArea(child: content),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(lang.tr('swap_title'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: content,
    );
  }

  Widget _buildTopTabs(LanguageController lang) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _activeTopTab = 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    lang.tr('swap_title'),
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: _activeTopTab == 0 ? FontWeight.w700 : FontWeight.w500,
                      color: _activeTopTab == 0 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF1E293B)),
                ],
              ),
              const SizedBox(height: 2),
              if (_activeTopTab == 0)
                Container(
                  width: 32,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFromCard(BuildContext context, List<Token> tokens, LanguageController lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('from_label'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () {
                  if (_fromToken != null) {
                    setState(() => _fromAmountController.text = _fromToken!.balance.toString());
                  }
                },
                child: Row(
                  children: [
                    Text(
                      '${lang.tr('balance_prefix')}${_fromToken?.formattedBalance ?? '0.00'}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        lang.tr('all'),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Token selector chip
              GestureDetector(
                onTap: () => _showTokenPicker(context, tokens, isFrom: true, lang: lang),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CryptoIcon(networkId: _fromToken?.symbol ?? 'POL', size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _fromToken?.symbol ?? 'POL',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _fromAmountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '0.0',
                    hintStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToCard(BuildContext context, List<Token> tokens, double estimatedToAmount, LanguageController lang) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('to_label'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w600),
              ),
              Text(
                '${lang.tr('balance_prefix')}${_toToken?.formattedBalance ?? '0.00'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showTokenPicker(context, tokens, isFrom: false, lang: lang),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      CryptoIcon(networkId: _toToken?.symbol ?? 'USDT', size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _toToken?.symbol ?? 'USDT',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  estimatedToAmount > 0 ? estimatedToAmount.toStringAsFixed(4) : '0.0',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: estimatedToAmount > 0 ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBox(double rate, double minReceived, LanguageController lang) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.tr('rate'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text(
                '1 ${_fromToken?.symbol ?? ''} ≈ ${rate.toStringAsFixed(4)} ${_toToken?.symbol ?? ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.tr('min_received'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text(
                '${minReceived > 0 ? minReceived.toStringAsFixed(4) : '0.00'} ${_toToken?.symbol ?? ''}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lang.tr('route'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Row(
                children: [
                  const Icon(Icons.route_rounded, size: 14, color: Color(0xFF2563EB)),
                  const SizedBox(width: 4),
                  Text(
                    'Transit Aggregator (Best Rate)',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _flipTokens() {
    setState(() {
      final temp = _fromToken;
      _fromToken = _toToken;
      _toToken = temp;
    });
  }

  void _showTokenPicker(BuildContext context, List<Token> tokens, {required bool isFrom, required LanguageController lang}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.tr('select_token'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...tokens.map((token) {
                return ListTile(
                  leading: CryptoIcon(networkId: token.symbol, size: 36),
                  title: Text(token.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${token.formattedBalance} ${token.symbol}'),
                  onTap: () {
                    setState(() {
                      if (isFrom) {
                        _fromToken = token;
                      } else {
                        _toToken = token;
                      }
                    });
                    Navigator.of(ctx).pop();
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSlippageSheet(BuildContext context, LanguageController lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lang.tr('slippage_tolerance'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                Row(
                  children: [0.5, 1.0, 2.0, 3.0].map((val) {
                    final isSel = _slippage == val;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _slippage = val);
                          setSheetState(() {});
                          Navigator.of(ctx).pop();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                          ),
                          child: Center(
                            child: Text(
                              '$val%',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isSel ? const Color(0xFF2563EB) : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSwap(
    BuildContext context,
    double fromAmount,
    double toAmount,
    LanguageController lang,
  ) async {
    if (_fromToken != null && fromAmount > _fromToken!.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr('err_insufficient_balance')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() => _isSwapping = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      final walletController = context.read<WalletController>();
      final networkController = context.read<NetworkController>();
      final assetController = context.read<AssetController>();
      final activeWallet = walletController.activeWallet;

      if (activeWallet != null && _fromToken != null && _toToken != null) {
        final network = networkController.allNetworks.firstWhere(
          (n) => n.id.toLowerCase() == activeWallet.networkId.toLowerCase(),
          orElse: () => networkController.allNetworks.first,
        );
        final newFromBal = (_fromToken!.balance - fromAmount).clamp(0.0, double.infinity);
        await assetController.updateBalance(
          network: network,
          walletAddress: activeWallet.address,
          walletId: activeWallet.id,
          tokenSymbol: _fromToken!.symbol,
          newBalance: newFromBal,
        );
        await assetController.claimFaucet(
          network: network,
          walletAddress: activeWallet.address,
          walletId: activeWallet.id,
          tokenSymbol: _toToken!.symbol,
          amount: toAmount,
        );

        _swapHistory.insert(
          0,
          SwapRecord(
            fromSymbol: _fromToken!.symbol,
            toSymbol: _toToken!.symbol,
            fromAmount: fromAmount,
            toAmount: toAmount,
            timestamp: DateTime.now(),
          ),
        );
      }

      setState(() => _isSwapping = false);
      _fromAmountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr('swap_swapped_success', params: {
            'fromAmount': '$fromAmount',
            'fromToken': _fromToken?.symbol ?? '',
            'toAmount': toAmount.toStringAsFixed(4),
            'toToken': _toToken?.symbol ?? '',
          })),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}
