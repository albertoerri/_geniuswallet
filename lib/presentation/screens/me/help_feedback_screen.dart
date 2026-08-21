import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/language_controller.dart';
import '../../widgets/custom_card.dart';

class HelpFeedbackScreen extends StatelessWidget {
  const HelpFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    final faqs = [
      {'q': lang.tr('faq_1_q'), 'a': lang.tr('faq_1_a')},
      {'q': lang.tr('faq_2_q'), 'a': lang.tr('faq_2_a')},
      {
        'q': lang.currentLanguage == AppLanguage.zh ? '如何导出我的钱包私钥？' : 'How do I export my private key?',
        'a': lang.currentLanguage == AppLanguage.zh
            ? '进入主页左上角抽屉或「我的」-「钱包管理」，点击对应的钱包进入详情页，输入主密码后即可查看并导出明文私钥。'
            : 'Open the drawer from the dashboard or go to "Me" -> "Manage Wallets", select your wallet, verify your master password, and securely export your private key.',
      },
      {
        'q': lang.currentLanguage == AppLanguage.zh ? '交易矿工费 (Gas) 怎么计算？' : 'How is transaction Gas Fee calculated?',
        'a': lang.currentLanguage == AppLanguage.zh
            ? 'Genius Wallet 支持 EIP-1559 动态矿工费计算，提供慢速 (Slow)、推荐 (Standard)、极速 (Fast) 三档选择，确保交易快速上链。'
            : 'Genius Wallet supports dynamic EIP-1559 gas fee estimation with Slow, Standard, and Fast presets for rapid blockchain confirmation.',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(lang.tr('help_and_feedback'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
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
            // Quick Support Card
            CustomCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang.tr('contact_support'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'support@geniuswallet.io (24/7)',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(lang.currentLanguage == AppLanguage.zh ? '已打开在线客服支持会话' : 'Connected to live support'),
                          backgroundColor: const Color(0xFF2563EB),
                        ),
                      );
                    },
                    child: Text(
                      lang.currentLanguage == AppLanguage.zh ? '咨询' : 'Chat',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // FAQ Header
            Text(
              lang.tr('faq_title'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),

            const SizedBox(height: 12),

            // FAQs
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: faqs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final faq = faqs[i];
                return CustomCard(
                  padding: EdgeInsets.zero,
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Text(
                        faq['q']!,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                          child: Text(
                            faq['a']!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Official Community
            Text(
              lang.tr('official_community'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
            ),

            const SizedBox(height: 12),

            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.send_rounded, color: Color(0xFF0088CC)),
                    title: const Text('Telegram Community', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('t.me/geniuswallet_official', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Telegram community...')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.tag_rounded, color: Color(0xFF1DA1F2)),
                    title: const Text('Twitter / X', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: const Text('@GeniusWallet_App', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: const Icon(Icons.open_in_new_rounded, size: 18, color: Color(0xFF94A3B8)),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Twitter / X profile...')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
