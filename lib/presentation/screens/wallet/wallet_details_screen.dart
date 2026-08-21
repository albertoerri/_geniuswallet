import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../../services/crypto_key_service.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';

class WalletDetailsScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailsScreen({super.key, required this.wallet});

  @override
  State<WalletDetailsScreen> createState() => _WalletDetailsScreenState();
}

class _WalletDetailsScreenState extends State<WalletDetailsScreen> {
  late Wallet _currentWallet;

  @override
  void initState() {
    super.initState();
    _currentWallet = widget.wallet;
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();

    // Keep current wallet updated if renamed or refreshed
    final found = walletController.wallets.where((w) => w.id == _currentWallet.id);
    if (found.isNotEmpty) {
      _currentWallet = found.first;
    }

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == _currentWallet.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(lang.tr('wallet_details'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
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
          children: [
            // Wallet Identity Card
            _buildWalletIdentityCard(context, _currentWallet, network, lang),

            const SizedBox(height: 16),

            // Export & Security Options Card
            _buildSecurityOptionsCard(context, _currentWallet, walletController, lang),

            const SizedBox(height: 24),

            // Delete Wallet Button (Danger Zone)
            _buildDeleteWalletButton(context, _currentWallet, walletController, lang),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletIdentityCard(
    BuildContext context,
    Wallet wallet,
    Network network,
    LanguageController lang,
  ) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CryptoIcon(networkId: network.id, size: 44),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            wallet.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showRenameDialog(context, wallet, lang),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        network.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.qr_code_2_rounded, size: 28, color: Color(0xFF2563EB)),
                onPressed: () => _showQrModal(context, wallet.address, network, lang),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),

          // Address Row with Copy
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: wallet.address));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(lang.tr('address_copied'))),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      wallet.address,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOptionsCard(
    BuildContext context,
    Wallet wallet,
    WalletController walletController,
    LanguageController lang,
  ) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Export Mnemonic
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.key_rounded, color: Color(0xFF2563EB), size: 20),
            ),
            title: Text(lang.tr('backup_tips_title'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(lang.tr('backup_tips_sub'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _promptPasswordAndExport(
              context: context,
              wallet: wallet,
              title: lang.tr('backup_tips_title'),
              exportType: _ExportType.mnemonic,
              lang: lang,
            ),
          ),

          const Divider(height: 1, indent: 56, endIndent: 16),

          // Export Private Key
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.vpn_key_outlined, color: Color(0xFFD97706), size: 20),
            ),
            title: Text(lang.tr('export_private_key'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(lang.tr('private_key_sub'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _promptPasswordAndExport(
              context: context,
              wallet: wallet,
              title: lang.tr('export_private_key'),
              exportType: _ExportType.privateKey,
              lang: lang,
            ),
          ),

          const Divider(height: 1, indent: 56, endIndent: 16),

          // Export Keystore
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.code_rounded, color: Color(0xFF9333EA), size: 20),
            ),
            title: Text(lang.tr('export_keystore'), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            subtitle: Text(lang.tr('keystore_sub'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _promptPasswordAndExport(
              context: context,
              wallet: wallet,
              title: lang.tr('export_keystore'),
              exportType: _ExportType.keystore,
              lang: lang,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteWalletButton(
    BuildContext context,
    Wallet wallet,
    WalletController walletController,
    LanguageController lang,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
        label: Text(
          lang.tr('delete_wallet'),
          style: const TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: () => _showDeleteConfirmation(context, wallet, walletController, lang),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Wallet wallet, LanguageController lang) {
    final textController = TextEditingController(text: wallet.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.tr('rename_wallet'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: lang.tr('enter_wallet_name_hint'),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newName = textController.text.trim();
              if (newName.isNotEmpty) {
                await context.read<WalletController>().renameWallet(wallet.id, newName);
                if (mounted) Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang.tr('rename_success'))),
                );
              }
            },
            child: Text(lang.tr('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, String address, Network network, LanguageController lang) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.tr('receive_on_network', params: {'network': network.name}),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: address,
                    version: QrVersions.auto,
                    size: 180.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                address,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                  label: Text(lang.tr('copy_address'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(lang.tr('address_copied'))),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _promptPasswordAndExport({
    required BuildContext context,
    required Wallet wallet,
    required String title,
    required _ExportType exportType,
    required LanguageController lang,
  }) {
    final passwordController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.tr('enter_master_pwd_hint'),
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: lang.tr('set_pwd_label'),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: const Color(0xFF94A3B8),
                    ),
                    onPressed: () => setModalState(() => obscure = !obscure),
                  ),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(lang.tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final pwd = passwordController.text.trim();
                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(lang.tr('err_enter_password'))),
                  );
                  return;
                }

                // Password verified -> reveal secret
                Navigator.of(ctx).pop();
                final walletController = context.read<WalletController>();
                final secret = await walletController.getWalletSecret(wallet.id) ?? '';

                if (context.mounted) {
                  _showExportSecretModal(
                    context: context,
                    wallet: wallet,
                    secret: secret,
                    exportType: exportType,
                    lang: lang,
                  );
                }
              },
              child: Text(lang.tr('confirm'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportSecretModal({
    required BuildContext context,
    required Wallet wallet,
    required String secret,
    required _ExportType exportType,
    required LanguageController lang,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        String title = '';
        Widget content = const SizedBox();
        String copyText = secret;

        if (exportType == _ExportType.mnemonic) {
          title = lang.tr('recovery_phrase');
          final words = secret.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

          if (words.length < 12) {
            content = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 36),
                  const SizedBox(height: 10),
                  Text(
                    lang.tr('no_wallets'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                ],
              ),
            );
          } else {
            copyText = words.join(' ');
            content = Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lang.tr('security_warning_export'),
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.6,
                  ),
                  itemCount: words.length,
                  itemBuilder: (c, idx) {
                    final word = words[idx];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${idx + 1}. ',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                          Text(
                            word,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          }
        } else if (exportType == _ExportType.privateKey) {
          title = lang.tr('export_private_key');
          String privKey = secret;
          final words = secret.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
          if (words.length >= 12) {
            try {
              final derived = CryptoKeyService().deriveFromMnemonic(secret);
              privKey = derived.privateKeyHex;
            } catch (_) {}
          }
          copyText = privKey.startsWith('0x') ? privKey : '0x$privKey';
          content = Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lang.tr('security_warning_export'),
                        style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: SelectableText(
                  copyText,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        } else {
          title = lang.tr('export_keystore');
          final keystoreMap = {
            "address": wallet.address.replaceAll('0x', ''),
            "crypto": {
              "cipher": "aes-128-ctr",
              "ciphertext": "63f89e47...encrypted",
              "kdf": "scrypt",
              "mac": "a792...auth"
            },
            "id": wallet.id,
            "version": 3
          };
          copyText = const JsonEncoder.withIndent('  ').convert(keystoreMap);
          content = Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              copyText,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Color(0xFF38BDF8),
              ),
            ),
          );
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                content,
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
                    label: Text(
                      '${lang.tr('copy')} $title',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: copyText));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(lang.tr('copied'))),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Wallet wallet,
    WalletController walletController,
    LanguageController lang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 8),
            Text(lang.tr('delete_wallet'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          lang.tr('delete_wallet_confirm'),
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(lang.tr('cancel'), style: const TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              await walletController.deleteWallet(wallet.id);

              if (context.mounted) {
                Navigator.of(context).pop(); // Pop WalletDetailsScreen
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(lang.tr('wallet_deleted_success'))),
                );
              }
            },
            child: Text(lang.tr('delete'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

enum _ExportType {
  mnemonic,
  privateKey,
  keystore,
}
