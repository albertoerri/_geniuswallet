import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../../services/crypto_key_service.dart';
import '../../../services/environment_service.dart';
import '../../../services/onchain_transaction_service.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/environment_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';

class BatchTransferSheet extends StatefulWidget {
  final Wallet activeWallet;
  final Network network;

  const BatchTransferSheet({
    super.key,
    required this.activeWallet,
    required this.network,
  });

  static Future<void> show(BuildContext context, Wallet wallet, Network network) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => BatchTransferSheet(activeWallet: wallet, network: network),
    );
  }

  @override
  State<BatchTransferSheet> createState() => _BatchTransferSheetState();
}

class _BatchTransferSheetState extends State<BatchTransferSheet> {
  late final TextEditingController _textController;
  bool _isExecuting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: '0x71C80e460be01bc0ffFe8166D44122bc13d49bE8, 0.01\n0x2629668d28AFeFf5a54388481232B401ec86e486, 0.01',
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('batch_transfer'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _isExecuting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lang.isChinese
                    ? '每行输入一个收款地址与数量（格式：地址, 数量）'
                    : 'Enter recipient address & amount per line (format: address, amount)',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _textController,
                maxLines: 4,
                minLines: 3,
                enabled: !_isExecuting,
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: '0xAddress, Amount',
                  hintStyle: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
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
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${widget.network.name} (ChainID ${widget.network.chainId})',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF2563EB)),
                    ),
                    const Text(
                      'Native Transfer (On-Chain)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isExecuting ? null : () => _executeBatchTransfer(context, lang),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isExecuting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          lang.isChinese ? '立即执行批量转账 (链上广播)' : 'Execute Batch Transfer (On-Chain)',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeBatchTransfer(BuildContext context, LanguageController lang) async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;

    setState(() => _isExecuting = true);

    final walletController = context.read<WalletController>();
    final assetController = context.read<AssetController>();
    EnvironmentController? envController;
    try {
      envController = context.read<EnvironmentController>();
    } catch (_) {
      envController = null;
    }
    final isLive = envController?.isLive ?? true;

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

    final txHashes = <String>[];
    int successCount = 0;

    try {
      if (isLive) {
        final secret = await walletController.getWalletSecret(widget.activeWallet.id);
        if (secret == null || secret.isEmpty) {
          throw Exception('Wallet private key not found');
        }

        String privateKeyHex;
        if (cryptoKeyService.validateMnemonic(secret)) {
          privateKeyHex = cryptoKeyService.deriveFromMnemonic(secret).privateKeyHex;
        } else if (cryptoKeyService.validatePrivateKey(secret)) {
          privateKeyHex = cryptoKeyService.deriveFromPrivateKey(secret).privateKeyHex;
        } else {
          privateKeyHex = secret;
        }

        for (final line in lines) {
          final parts = line.split(',');
          if (parts.isNotEmpty) {
            final addr = parts[0].trim();
            final amt = parts.length > 1 ? double.tryParse(parts[1].trim()) ?? 0.01 : 0.01;
            if (addr.startsWith('0x') && addr.length == 42 && amt > 0) {
              final res = await onChainService.sendNativeTransfer(
                network: widget.network,
                privateKeyHex: privateKeyHex,
                toAddress: addr,
                amount: amt,
              );
              if (res.isSuccess && res.txHash != null) {
                txHashes.add(res.txHash!);
                successCount++;
              }
            }
          }
        }
        await assetController.loadAssets(
          network: widget.network,
          walletAddress: widget.activeWallet.address,
          walletId: widget.activeWallet.id,
          forceRefresh: true,
        );
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        successCount = lines.length;
        txHashes.add('0xsimbatch${DateTime.now().millisecondsSinceEpoch}');
      }

      if (mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (dlgCtx) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  lang.isChinese ? '批量转账已广播上链' : 'Batch Transfers Broadcasted',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Successfully broadcasted $successCount transactions on ${widget.network.name}!'),
                const SizedBox(height: 10),
                if (txHashes.isNotEmpty) ...[
                  const Text('Latest TxHash:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  Text(
                    txHashes.first,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF2563EB)),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dlgCtx).pop(),
                child: Text(lang.tr('btn_confirm')),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExecuting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Batch Transfer Error: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }
}
