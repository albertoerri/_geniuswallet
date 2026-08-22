import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/token.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';

class AddCustomTokenSheet extends StatefulWidget {
  final Network network;

  const AddCustomTokenSheet({super.key, required this.network});

  static Future<void> show(BuildContext context, Network network) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => AddCustomTokenSheet(network: network),
    );
  }

  @override
  State<AddCustomTokenSheet> createState() => _AddCustomTokenSheetState();
}

class _AddCustomTokenSheetState extends State<AddCustomTokenSheet> {
  final _addressCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController(text: 'CUSTOM');
  final _nameCtrl = TextEditingController(text: 'Custom Test Token');
  final _decimalsCtrl = TextEditingController(text: '18');

  @override
  void dispose() {
    _addressCtrl.dispose();
    _symbolCtrl.dispose();
    _nameCtrl.dispose();
    _decimalsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final assetController = context.read<AssetController>();

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
              Text(
                lang.tr('add_custom_token'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _addressCtrl,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Contract Address (0x...)',
                  hintText: '0x...',
                  filled: true,
                  fillColor: Colors.white,
                  prefixIcon: const Icon(Icons.token_rounded, size: 20, color: Color(0xFF64748B)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _symbolCtrl,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Token Symbol',
                  hintText: 'e.g. USDT',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Token Name',
                  hintText: 'e.g. Tether USD',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final addr = _addressCtrl.text.trim();
                    final sym = _symbolCtrl.text.trim();
                    final name = _nameCtrl.text.trim();
                    final dec = int.tryParse(_decimalsCtrl.text.trim()) ?? 18;

                    if (addr.isNotEmpty && sym.isNotEmpty) {
                      final customToken = Token(
                        id: '${widget.network.id}_${sym.toLowerCase()}',
                        networkId: widget.network.id,
                        symbol: sym.toUpperCase(),
                        name: name.isNotEmpty ? name : sym,
                        decimals: dec,
                        contractAddress: addr,
                        priceUsd: 1.0,
                        balance: 0.0,
                      );
                      assetController.addCustomToken(customToken);
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Token $sym added to your wallet!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    lang.tr('btn_confirm'),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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
}
