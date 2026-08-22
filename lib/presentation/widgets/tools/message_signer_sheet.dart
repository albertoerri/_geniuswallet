import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/wallet.dart';
import '../../../services/crypto_key_service.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';

class MessageSignerSheet extends StatefulWidget {
  final Wallet activeWallet;

  const MessageSignerSheet({super.key, required this.activeWallet});

  static Future<void> show(BuildContext context, Wallet wallet) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => MessageSignerSheet(activeWallet: wallet),
    );
  }

  @override
  State<MessageSignerSheet> createState() => _MessageSignerSheetState();
}

class _MessageSignerSheetState extends State<MessageSignerSheet> {
  final _msgCtrl = TextEditingController(text: 'Hello from Genius Wallet! EIP-191 Verified.');
  String _signature = '';

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _signMessage() async {
    final text = _msgCtrl.text;
    if (text.isEmpty) return;

    final walletCtrl = context.read<WalletController>();
    ICryptoKeyService cryptoService;
    try {
      cryptoService = context.read<ICryptoKeyService>();
    } catch (_) {
      cryptoService = CryptoKeyService();
    }

    try {
      final secret = await walletCtrl.getWalletSecret(widget.activeWallet.id);
      if (secret != null) {
        String pk = secret;
        if (cryptoService.validateMnemonic(secret)) {
          pk = cryptoService.deriveFromMnemonic(secret).privateKeyHex;
        } else if (cryptoService.validatePrivateKey(secret)) {
          pk = cryptoService.deriveFromPrivateKey(secret).privateKeyHex;
        }
        final sig = cryptoService.signPersonalMessage(message: text, privateKeyHex: pk);
        setState(() => _signature = sig);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signing Error: $e')),
      );
    }
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
                    lang.tr('message_signer'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _msgCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Message to Sign (EIP-191)',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _signMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(lang.isChinese ? '使用私钥进行离线签名' : 'Sign Message Offline'),
                ),
              ),
              if (_signature.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Signature (Hex):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _signature));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Signature copied to clipboard!')),
                              );
                            },
                          ),
                        ],
                      ),
                      Text(
                        _signature,
                        style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF1E293B)),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
