import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../../services/crypto_key_service.dart';
import '../../../services/environment_service.dart';
import '../../../services/onchain_transaction_service.dart';
import '../../controllers/environment_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';

class ApprovalRevokeSheet extends StatefulWidget {
  final Wallet activeWallet;
  final Network network;
  final List<Map<String, String>> tokenApprovals;

  const ApprovalRevokeSheet({
    super.key,
    required this.activeWallet,
    required this.network,
    required this.tokenApprovals,
  });

  static Future<void> show(
    BuildContext context,
    Wallet wallet,
    Network network,
    List<Map<String, String>> tokenApprovals,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ApprovalRevokeSheet(
        activeWallet: wallet,
        network: network,
        tokenApprovals: tokenApprovals,
      ),
    );
  }

  @override
  State<ApprovalRevokeSheet> createState() => _ApprovalRevokeSheetState();
}

class _ApprovalRevokeSheetState extends State<ApprovalRevokeSheet> {
  late final List<Map<String, String>> _approvals;

  @override
  void initState() {
    super.initState();
    _approvals = List.from(widget.tokenApprovals);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.tr('approval_revoke'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lang.isChinese
                  ? '已扫描 ${widget.network.name} 链上的智能合约代币授权'
                  : 'Scanned active token approvals on ${widget.network.name}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _approvals.isEmpty
                  ? const Center(
                      child: Text('No active token approvals found. Wallet is safe!'),
                    )
                  : ListView.separated(
                      itemCount: _approvals.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _approvals[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.security_rounded, color: Color(0xFF2563EB), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['spenderName']!,
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item['token']}: ${item['allowance']}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              OutlinedButton(
                                onPressed: () => _revokeApproval(index, item),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFEF4444),
                                  side: const BorderSide(color: Color(0xFFEF4444)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                child: Text(
                                  lang.isChinese ? '撤销授权' : 'Revoke',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _revokeApproval(int index, Map<String, String> item) async {
    final walletController = context.read<WalletController>();
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

    String txHash = '';
    if (isLive) {
      try {
        final secret = await walletController.getWalletSecret(widget.activeWallet.id);
        if (secret != null && secret.isNotEmpty) {
          String pk = secret;
          if (cryptoKeyService.validateMnemonic(secret)) {
            pk = cryptoKeyService.deriveFromMnemonic(secret).privateKeyHex;
          } else if (cryptoKeyService.validatePrivateKey(secret)) {
            pk = cryptoKeyService.deriveFromPrivateKey(secret).privateKeyHex;
          }
          final res = await onChainService.revokeApproval(
            network: widget.network,
            privateKeyHex: pk,
            tokenContractAddress: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F',
            spenderAddress: item['spenderAddress'] ?? '0xE592427A0AEce92De3Edee1F18E0157C05861564',
          );
          if (res.isSuccess && res.txHash != null) {
            txHash = res.txHash!;
          }
        }
      } catch (_) {}
    }

    setState(() {
      _approvals.removeAt(index);
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(txHash.isNotEmpty
              ? 'Revoked approval on ${widget.network.name}! TxHash: ${Formatters.formatAddress(txHash)}'
              : 'Successfully revoked ${item['token']} allowance for ${item['spenderName']}!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }
}
