import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/token.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';
import '../crypto_icon.dart';
import '../tools/add_custom_token_sheet.dart';

class ManageTokensSheet extends StatelessWidget {
  final Network network;

  const ManageTokensSheet({super.key, required this.network});

  static Future<void> show(BuildContext context, Network network) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ManageTokensSheet(network: network),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final assetController = context.watch<AssetController>();
    final tokens = assetController.tokens;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  lang.tr('add_tokens'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: tokens.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final token = tokens[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CryptoIcon(networkId: token.symbol, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(token.symbol, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
                              Text(token.name, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Switch(
                          value: true,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (_) {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  AddCustomTokenSheet.show(context, network);
                },
                icon: const Icon(Icons.add_rounded, color: Color(0xFF2563EB)),
                label: Text(lang.tr('add_custom_token'), style: const TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
