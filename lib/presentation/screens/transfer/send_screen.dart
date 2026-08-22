import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/token.dart';
import '../../../domain/models/wallet.dart';
import '../../../domain/models/network.dart';
import '../../../services/crypto_key_service.dart';
import '../../../services/environment_service.dart';
import '../../../services/onchain_transaction_service.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/environment_controller.dart';
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
    EnvironmentController? envController;
    try {
      envController = context.watch<EnvironmentController>();
    } catch (_) {
      envController = null;
    }
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
            // Environment Status Banner
            _buildEnvironmentBanner(envController, network, lang),

            const SizedBox(height: 14),

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
                    : () => _handleConfirmSend(context, activeWallet, network, lang, envController),
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

  Widget _buildEnvironmentBanner(EnvironmentController? envController, Network network, LanguageController lang) {
    final isLive = envController?.isLive ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFF0FDF4) : const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.sensors_rounded : Icons.science_outlined,
            size: 20,
            color: isLive ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive
                      ? '${lang.tr('env_badge_live')}: ${network.name} (ChainID ${network.chainId})'
                      : '${lang.tr('env_badge_sim')}: ${lang.tr('env_mode_simulation')}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isLive ? const Color(0xFF15803D) : const Color(0xFF854D0E),
                  ),
                ),
                Text(
                  isLive ? lang.tr('env_mode_live_desc') : lang.tr('env_mode_simulation_desc'),
                  style: TextStyle(
                    fontSize: 11,
                    color: isLive ? const Color(0xFF166534) : const Color(0xFF713F12),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            CryptoIcon(networkId: _selectedToken?.symbol ?? 'POL', size: 36),
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
      {'title': lang.tr('slow_speed'), 'time': '≈ 1 min', 'gwei': '30 Gwei', 'fee': '0.0006 $nativeSymbol'},
      {'title': lang.tr('standard_speed'), 'time': '≈ 15 sec', 'gwei': '40 Gwei', 'fee': '0.0008 $nativeSymbol'},
      {'title': lang.tr('fast_speed'), 'time': '≈ 5 sec', 'gwei': '55 Gwei', 'fee': '0.0011 $nativeSymbol'},
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
    Network network,
    LanguageController lang,
    EnvironmentController? envController,
  ) {
    final toAddress = _addressController.text.trim();
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    final isLive = envController?.isLive ?? true;

    if (toAddress.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.tr('err_recipient_empty'))),
      );
      return;
    }

    if (!toAddress.startsWith('0x') || toAddress.length != 42) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid EVM recipient address (must start with 0x and have 42 characters)')),
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
              const SizedBox(height: 16),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        'Polygon Mainnet (Chain ID 137) - On-Chain Live Broadcast',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                      ),
                    ],
                  ),
                ),
              _buildSummaryRow(lang.tr('contact_network'), network.name),
              _buildSummaryRow(lang.tr('from_label'), Formatters.formatAddress(activeWallet.address)),
              _buildSummaryRow(lang.tr('to_label'), Formatters.formatAddress(toAddress)),
              _buildSummaryRow(lang.tr('amount'), '$amount ${_selectedToken?.symbol ?? ''}'),
              _buildSummaryRow(lang.tr('gas_fee_label'), '≈ 0.0008 ${network.symbol}'),
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
                    await _executeSendTransaction(context, activeWallet, network, toAddress, amount, isLive, lang);
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

  Future<void> _executeSendTransaction(
    BuildContext context,
    Wallet activeWallet,
    Network network,
    String toAddress,
    double amount,
    bool isLive,
    LanguageController lang,
  ) async {
    setState(() => _isSending = true);

    final walletController = context.read<WalletController>();
    final assetController = context.read<AssetController>();
    IOnChainTransactionService onChainService;
    try {
      onChainService = context.read<IOnChainTransactionService>();
    } catch (_) {
      onChainService = OnChainTransactionService();
    }
    ICryptoKeyService cryptoKeyService;
    try {
      cryptoKeyService = context.read<ICryptoKeyService>();
    } catch (_) {
      cryptoKeyService = CryptoKeyService();
    }

    String txHash = '';
    String explorerUrl = '';
    bool success = false;
    String? error;

    try {
      if (isLive) {
        // 1. Retrieve wallet secret
        final secret = await walletController.getWalletSecret(activeWallet.id);
        if (secret == null || secret.isEmpty) {
          throw Exception('Wallet private key not found or wallet is watch-only');
        }

        // 2. Derive private key
        String privateKeyHex;
        if (cryptoKeyService.validateMnemonic(secret)) {
          privateKeyHex = cryptoKeyService.deriveFromMnemonic(secret).privateKeyHex;
        } else if (cryptoKeyService.validatePrivateKey(secret)) {
          privateKeyHex = cryptoKeyService.deriveFromPrivateKey(secret).privateKeyHex;
        } else {
          privateKeyHex = secret;
        }

        // 3. Send on-chain transaction
        final token = _selectedToken;
        OnChainTxResult res;
        if (token != null && !token.isNative && token.contractAddress != null) {
          res = await onChainService.sendErc20Transfer(
            network: network,
            privateKeyHex: privateKeyHex,
            tokenContractAddress: token.contractAddress!,
            toAddress: toAddress,
            amount: amount,
            decimals: token.decimals,
            gasSpeedMultiplier: _gasSpeed,
          );
        } else {
          res = await onChainService.sendNativeTransfer(
            network: network,
            privateKeyHex: privateKeyHex,
            toAddress: toAddress,
            amount: amount,
            gasSpeedMultiplier: _gasSpeed,
          );
        }

        if (res.isSuccess && res.txHash != null) {
          txHash = res.txHash!;
          explorerUrl = res.explorerUrl ?? onChainService.getExplorerTxUrl(network, txHash);
          success = true;

          // Update balance and refresh on-chain balances
          if (token != null) {
            final newBal = (token.balance - amount).clamp(0.0, double.infinity);
            await assetController.updateBalance(
              network: network,
              walletAddress: activeWallet.address,
              walletId: activeWallet.id,
              tokenSymbol: token.symbol,
              newBalance: newBal,
            );
          }
          // Trigger on-chain balance refresh
          assetController.loadAssets(network: network, walletAddress: activeWallet.address, walletId: activeWallet.id, forceRefresh: true);
        } else {
          error = res.errorMessage ?? 'On-chain broadcast failed';
        }
      } else {
        // Simulation mode
        await Future.delayed(const Duration(milliseconds: 600));
        final pseudoHash = '0x${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}abcdef1234567890abcdef1234567890abcdef1234567890';
        txHash = pseudoHash;
        explorerUrl = onChainService.getExplorerTxUrl(network, txHash);
        success = true;

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
      }
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }

    if (!mounted) return;

    if (success && txHash.isNotEmpty) {
      _showTransactionReceiptModal(context, network, toAddress, amount, txHash, explorerUrl, isLive, lang);
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444)),
              const SizedBox(width: 8),
              Text(lang.tr('tx_broadcast_failed'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          content: Text(
            error ?? 'Unknown error occurred while broadcasting transaction.',
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(lang.tr('btn_confirm')),
            ),
          ],
        ),
      );
    }
  }

  void _showTransactionReceiptModal(
    BuildContext context,
    Network network,
    String toAddress,
    double amount,
    String txHash,
    String explorerUrl,
    bool isLive,
    LanguageController lang,
  ) {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                lang.tr('tx_success_title'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                '$amount ${_selectedToken?.symbol ?? ''} ➔ ${Formatters.formatAddress(toAddress)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              Container(
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
                        Text(
                          lang.tr('tx_hash_label'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF08A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isLive ? 'Polygon Mainnet' : 'Sandbox',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isLive ? const Color(0xFF15803D) : const Color(0xFF854D0E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            txHash,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy_rounded, size: 18, color: Color(0xFF2563EB)),
                          tooltip: lang.tr('copy_tx_hash'),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: txHash));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lang.tr('copied_tx_hash')),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF2563EB)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Color(0xFF2563EB)),
                      label: Text(
                        lang.tr('view_on_explorer'),
                        style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: explorerUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Explorer link copied: $explorerUrl'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        lang.tr('btn_confirm'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
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
