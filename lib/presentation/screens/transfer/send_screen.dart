import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/token.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

class SendScreen extends StatefulWidget {
  final Token? initialToken;

  const SendScreen({super.key, this.initialToken});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  Token? _selectedToken;
  int _gasSpeed = 1; // 0: Slow, 1: Standard, 2: Fast
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _selectedToken = widget.initialToken;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
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
        appBar: AppBar(title: const Text('Send')),
        body: const Center(child: Text('No active wallet')),
      );
    }

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    final tokens = assetController.tokens;
    _selectedToken ??= tokens.isNotEmpty ? tokens.first : null;

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double tokenPrice = _selectedToken?.priceUsd ?? 0.0;
    final double fiatEstimated = amount * tokenPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text('Send on ${network.name}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Token Selector Card
            _buildTokenSelectorCard(context, tokens),

            const SizedBox(height: 16),

            // Recipient Address Card
            _buildRecipientCard(context),

            const SizedBox(height: 16),

            // Amount Input Card
            _buildAmountCard(context, fiatEstimated),

            const SizedBox(height: 16),

            // Gas / Fee Selector Card
            _buildGasFeeCard(context, network.symbol),

            const SizedBox(height: 24),

            // Transfer Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                onPressed: _isSending
                    ? null
                    : () => _handleConfirmSend(context, activeWallet, network.name),
                child: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text(
                        'Next',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSelectorCard(BuildContext context, List<Token> tokens) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: () => _showTokenPickerSheet(context, tokens),
        child: Row(
          children: [
            CryptoIcon(networkId: _selectedToken?.symbol ?? 'ETH', size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedToken?.name ?? 'Select Token',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Balance: ${_selectedToken?.formattedBalance ?? '0.00'} ${_selectedToken?.symbol ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 24, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientCard(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recipient Address',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Enter or paste wallet address (0x...)',
              hintStyle: const TextStyle(fontSize: 13, fontFamily: 'sans-serif', color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data?.text != null) {
                        setState(() {
                          _addressController.text = data!.text!.trim();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Paste',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFF64748B)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scan QR code for address')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard(BuildContext context, double fiatEstimated) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Transfer Amount',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              Text(
                'Available: ${_selectedToken?.formattedBalance ?? '0.00'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: const TextStyle(fontSize: 22, color: Color(0xFFCBD5E1)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedToken?.symbol ?? '',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_selectedToken != null) {
                        setState(() {
                          _amountController.text = _selectedToken!.balance.toString();
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'MAX',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '≈ \$${fiatEstimated.toStringAsFixed(2)} USD',
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildGasFeeCard(BuildContext context, String nativeSymbol) {
    final speeds = [
      {'title': 'Slow', 'time': '≈ 1 min', 'gwei': '15 Gwei', 'fee': '0.0003 $nativeSymbol'},
      {'title': 'Standard', 'time': '≈ 15 sec', 'gwei': '30 Gwei', 'fee': '0.0006 $nativeSymbol'},
      {'title': 'Fast', 'time': '≈ 5 sec', 'gwei': '45 Gwei', 'fee': '0.0009 $nativeSymbol'},
    ];

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Miner / Gas Fee',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              Text(
                speeds[_gasSpeed]['fee']!,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(3, (index) {
              final isSelected = _gasSpeed == index;
              final item = speeds[index];
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _gasSpeed = index),
                  child: Container(
                    margin: EdgeInsets.only(left: index > 0 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item['title']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['time']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showTokenPickerSheet(BuildContext context, List<Token> tokens) {
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
              const Text(
                'Select Asset',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...tokens.map((token) {
                final isSelected = token.symbol == _selectedToken?.symbol;
                return ListTile(
                  leading: CryptoIcon(networkId: token.symbol, size: 36),
                  title: Text(token.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${token.formattedBalance} ${token.symbol}'),
                  trailing: isSelected ? const Icon(Icons.check_rounded, color: Color(0xFF2563EB)) : null,
                  onTap: () {
                    setState(() => _selectedToken = token);
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

  void _handleConfirmSend(BuildContext context, Wallet activeWallet, String networkName) {
    final toAddress = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final assetController = context.read<AssetController>();
    final networkController = context.read<NetworkController>();
    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    if (toAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter recipient address')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid transfer amount')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text('Confirm Transfer', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow('Network', networkName),
              _buildSummaryRow('From', Formatters.formatAddress(activeWallet.address)),
              _buildSummaryRow('To', Formatters.formatAddress(toAddress)),
              _buildSummaryRow('Amount', '$amount ${_selectedToken?.symbol ?? ''}'),
              _buildSummaryRow('Miner Fee', '0.0006 ${_selectedToken?.symbol ?? ''}'),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    setState(() => _isSending = true);
                    await Future.delayed(const Duration(milliseconds: 600));
                    if (mounted) {
                      if (_selectedToken != null) {
                        final newBal = (_selectedToken!.balance - amount).clamp(0.0, double.infinity);
                        await assetController.updateBalance(
                          network: network,
                          walletAddress: activeWallet.address,
                          walletId: activeWallet.id,
                          tokenSymbol: _selectedToken!.symbol,
                          newBalance: newBal,
                        );
                      }
                      setState(() => _isSending = false);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction broadcasted successfully!'),
                          backgroundColor: Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }
}
