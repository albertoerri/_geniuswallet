import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/token.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

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

  @override
  void dispose() {
    _fromAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final activeWallet = walletController.activeWallet;

    if (activeWallet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Swap')),
        body: const Center(child: Text('No active wallet')),
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
          _buildTopTabs(),

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
                      'Transit',
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
                              const SnackBar(content: Text('Rates updated')),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined, size: 20, color: Color(0xFF64748B)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showSlippageSheet(context),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // From Box
                _buildFromCard(context, tokens),

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
                _buildToCard(context, tokens, estimatedToAmount),

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
                        : () => _handleSwap(context, fromAmount, estimatedToAmount),
                    child: _isSwapping
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            fromAmount <= 0 ? 'Enter an Amount' : 'Swap Now',
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Rate & Route Breakdown
                _buildDetailsBox(rate, minReceived),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Last Record Section
          const Text(
            'Last Record',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: const Column(
              children: [
                Icon(Icons.receipt_long_outlined, size: 44, color: Color(0xFFCBD5E1)),
                SizedBox(height: 8),
                Text(
                  'No transaction records',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
                ),
              ],
            ),
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
        title: const Text('Swap & Bridge', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
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

  Widget _buildTopTabs() {
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
                    'Swap&Bridge',
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
        const SizedBox(width: 24),
        GestureDetector(
          onTap: () => setState(() => _activeTopTab = 1),
          child: Text(
            'Limit Order',
            style: TextStyle(
              fontSize: 16,
              fontWeight: _activeTopTab == 1 ? FontWeight.w700 : FontWeight.w500,
              color: _activeTopTab == 1 ? const Color(0xFF1E293B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFromCard(BuildContext context, List<Token> tokens) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('From', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              GestureDetector(
                onTap: () {
                  if (_fromToken != null) {
                    setState(() => _fromAmountController.text = _fromToken!.balance.toString());
                  }
                },
                child: const Text('All', style: TextStyle(fontSize: 12, color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Token selector chip
              GestureDetector(
                onTap: () => _showTokenPicker(context, tokens, isFrom: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CryptoIcon(networkId: _fromToken?.symbol ?? 'ETH', size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _fromToken?.symbol ?? 'Select',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'Transfer out',
                    hintStyle: TextStyle(fontSize: 16, color: Color(0xFFCBD5E1), fontWeight: FontWeight.normal),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Balance: ${_fromToken?.formattedBalance ?? '0.00'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToCard(BuildContext context, List<Token> tokens, double estimatedAmount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('To (estimated)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: [
              // Token selector chip
              GestureDetector(
                onTap: () => _showTokenPicker(context, tokens, isFrom: false),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      CryptoIcon(networkId: _toToken?.symbol ?? 'USDT', size: 24),
                      const SizedBox(width: 8),
                      Text(
                        _toToken?.symbol ?? 'Select',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF1E293B)),
                      ),
                      const Icon(Icons.arrow_drop_down_rounded, size: 20, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  estimatedAmount > 0 ? estimatedAmount.toStringAsFixed(4) : 'Receive',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: estimatedAmount > 0 ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Balance: ${_toToken?.formattedBalance ?? '0.00'}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsBox(double rate, double minReceived) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildDetailRow('Swap Rate', '1 ${_fromToken?.symbol ?? ''} ≈ ${rate.toStringAsFixed(4)} ${_toToken?.symbol ?? ''}'),
          _buildDetailRow('Min Receive', '${minReceived.toStringAsFixed(4)} ${_toToken?.symbol ?? ''}'),
          _buildDetailRow('Slippage', '$_slippage%'),
          _buildDetailRow('Price Impact', '< 0.01%'),
          _buildDetailRow('Service Fee', '0.00%'),
          _buildDetailRow('Route', 'Direct LP / Transit'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
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

  void _showTokenPicker(BuildContext context, List<Token> tokens, {required bool isFrom}) {
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
                isFrom ? 'Select Source Token' : 'Select Target Token',
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

  void _showSlippageSheet(BuildContext context) {
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
                const Text('Slippage Tolerance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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

  void _handleSwap(BuildContext context, double fromAmount, double toAmount) async {
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
      }

      setState(() => _isSwapping = false);
      _fromAmountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Swapped $fromAmount ${_fromToken?.symbol} to ${toAmount.toStringAsFixed(4)} ${_toToken?.symbol}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}
