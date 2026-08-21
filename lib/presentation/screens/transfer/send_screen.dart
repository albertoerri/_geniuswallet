import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/token.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

class SendScreen extends StatefulWidget {
  final Token? initialToken;
  final String? initialRecipient;
  final String? initialAmount;
  final String? initialTokenSymbol;

  const SendScreen({
    super.key,
    this.initialToken,
    this.initialRecipient,
    this.initialAmount,
    this.initialTokenSymbol,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _amountController;
  Token? _selectedToken;
  int _gasSpeed = 1; // 0: Slow, 1: Standard, 2: Fast
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.initialRecipient ?? '');
    _amountController = TextEditingController(text: widget.initialAmount ?? '');
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
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final activeWallet = walletController.activeWallet;

    if (activeWallet == null) {
      return Scaffold(
        appBar: AppBar(title: Text(lang.tr('send_title'))),
        body: Center(child: Text(lang.tr('no_active_wallet'))),
      );
    }

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    final tokens = assetController.tokens;
    if (_selectedToken == null && tokens.isNotEmpty) {
      if (widget.initialTokenSymbol != null) {
        _selectedToken = tokens.firstWhere(
          (t) => t.symbol.toLowerCase() == widget.initialTokenSymbol!.toLowerCase(),
          orElse: () => tokens.first,
        );
      } else {
        _selectedToken = tokens.first;
      }
    }

    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double tokenPrice = _selectedToken?.priceUsd ?? 0.0;
    final double fiatEstimated = amount * tokenPrice;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          lang.tr('send_on_network', params: {'network': network.name}),
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
        ),
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
            _buildTokenSelectorCard(context, tokens, lang),

            const SizedBox(height: 16),

            // Recipient Address Card
            _buildRecipientCard(context, lang),

            const SizedBox(height: 16),

            // Amount Input Card
            _buildAmountCard(context, fiatEstimated, lang),

            const SizedBox(height: 16),

            // Gas / Fee Selector Card
            _buildGasFeeCard(context, network.symbol, lang),

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
                    : () => _handleConfirmSend(context, activeWallet, network.name, lang),
                child: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        lang.tr('next'),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenSelectorCard(BuildContext context, List<Token> tokens, LanguageController lang) {
    return CustomCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: InkWell(
        onTap: () => _showTokenPickerSheet(context, tokens, lang),
        child: Row(
          children: [
            CryptoIcon(networkId: _selectedToken?.symbol ?? 'ETH', size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedToken?.name ?? lang.tr('select_token'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${lang.tr('balance_prefix')}${_selectedToken?.formattedBalance ?? '0.00'} ${_selectedToken?.symbol ?? ''}',
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

  Widget _buildRecipientCard(BuildContext context, LanguageController lang) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.tr('recipient_address'),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: '0x...',
              hintStyle: const TextStyle(fontSize: 14, fontFamily: 'sans-serif', color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        lang.tr('paste_address'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 22, color: Color(0xFF475569)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.tr('scan_for_address'))),
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

  Widget _buildAmountCard(BuildContext context, double fiatEstimated, LanguageController lang) {
    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('transfer_amount'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
              Text(
                '${lang.tr('available')}: ${_selectedToken?.formattedBalance ?? '0.00'}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFFCBD5E1)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Text(
                        lang.tr('all'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
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

  Widget _buildGasFeeCard(BuildContext context, String nativeSymbol, LanguageController lang) {
    final speeds = [
      {'title': lang.tr('slow_speed'), 'time': '≈ 1 min', 'gwei': '15 Gwei', 'fee': '0.0003 $nativeSymbol'},
      {'title': lang.tr('standard_speed'), 'time': '≈ 15 sec', 'gwei': '30 Gwei', 'fee': '0.0006 $nativeSymbol'},
      {'title': lang.tr('fast_speed'), 'time': '≈ 5 sec', 'gwei': '45 Gwei', 'fee': '0.0009 $nativeSymbol'},
    ];

    return CustomCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lang.tr('gas_fee_label'),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
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

  void _showTokenPickerSheet(BuildContext context, List<Token> tokens, LanguageController lang) {
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

  void _handleConfirmSend(
    BuildContext context,
    Wallet activeWallet,
    String networkName,
    LanguageController lang,
  ) {
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
        SnackBar(content: Text(lang.tr('err_recipient_empty'))),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.tr('err_amount_invalid'))),
      );
      return;
    }

    if (_selectedToken != null && amount > _selectedToken!.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr('err_insufficient_balance')),
          backgroundColor: const Color(0xFFEF4444),
        ),
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
              Center(
                child: Text(
                  lang.tr('confirm_transfer'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 20),
              _buildSummaryRow(lang.tr('contact_network'), networkName),
              _buildSummaryRow(lang.tr('from_label'), Formatters.formatAddress(activeWallet.address)),
              _buildSummaryRow(lang.tr('to_label'), Formatters.formatAddress(toAddress)),
              _buildSummaryRow(lang.tr('amount'), '$amount ${_selectedToken?.symbol ?? ''}'),
              _buildSummaryRow(lang.tr('gas_fee_label'), '0.0006 ${network.symbol}'),
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
                        SnackBar(
                          content: Text(lang.tr('tx_broadcast_success')),
                          backgroundColor: const Color(0xFF10B981),
                        ),
                      );
                    }
                  },
                  child: Text(
                    lang.tr('confirm'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
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
