import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/language_controller.dart';

class TxSpeedupSheet extends StatelessWidget {
  const TxSpeedupSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const TxSpeedupSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded, size: 40, color: Color(0xFFF59E0B)),
            const SizedBox(height: 12),
            Text(
              lang.isChinese ? '交易加速与取消' : 'Tx Speedup & Cancel',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              lang.isChinese
                  ? '当前网络没有检测到处于 Pending 状态的卡单交易。'
                  : 'No pending stuck transactions detected on current network.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(lang.tr('btn_confirm')),
            ),
          ],
        ),
      ),
    );
  }
}
