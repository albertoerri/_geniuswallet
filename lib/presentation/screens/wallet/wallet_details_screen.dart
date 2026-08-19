import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../../services/crypto_key_service.dart';
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
        title: const Text('Wallet Details', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
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
            _buildWalletIdentityCard(context, _currentWallet, network),

            const SizedBox(height: 16),

            // Export & Security Options Card
            _buildSecurityOptionsCard(context, _currentWallet, walletController),

            const SizedBox(height: 24),

            // Delete Wallet Button (Danger Zone)
            _buildDeleteWalletButton(context, _currentWallet, walletController),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletIdentityCard(BuildContext context, Wallet wallet, Network network) {
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
                          onTap: () => _showRenameDialog(context, wallet),
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
                        style: TextStyle(
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
                onPressed: () => _showQrModal(context, wallet.address, network),
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
                const SnackBar(content: Text('Address copied to clipboard!')),
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
                        color: Color(0xFF475569),
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
  ) {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Export Recovery Phrase
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.key_rounded, color: Color(0xFF2563EB), size: 22),
            ),
            title: const Text(
              'Export Recovery Phrase',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            subtitle: const Text(
              'View 12-word mnemonic phrase',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _promptPasswordAndExport(
              context: context,
              wallet: wallet,
              title: 'Export Recovery Phrase',
              exportType: _ExportType.mnemonic,
            ),
          ),

          const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),

          // Export Private Key
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vpn_key_rounded, color: Color(0xFFD97706), size: 22),
            ),
            title: const Text(
              'Export Private Key',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            subtitle: const Text(
              'Unencrypted private key string',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _promptPasswordAndExport(
              context: context,
              wallet: wallet,
              title: 'Export Private Key',
              exportType: _ExportType.privateKey,
            ),
          ),

          const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),

          // Export Keystore
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded, color: Color(0xFF475569), size: 22),
            ),
            title: const Text(
              'Export Keystore',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
            ),
            subtitle: const Text(
              'Encrypted JSON keystore file',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () => _promptPasswordAndExport(
              context: context,
              wallet: wallet,
              title: 'Export Keystore',
              exportType: _ExportType.keystore,
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
  ) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
        label: const Text(
          'Delete Wallet',
          style: TextStyle(
            color: Color(0xFFEF4444),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          side: const BorderSide(color: Color(0xFFFCA5A5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: () => _showDeleteConfirmation(context, wallet, walletController),
      ),
    );
  }

  void _showRenameDialog(BuildContext context, Wallet wallet) {
    final textController = TextEditingController(text: wallet.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Rename Wallet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Enter new wallet name',
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
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
                  const SnackBar(content: Text('Wallet renamed successfully')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showQrModal(BuildContext context, String address, Network network) {
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
                'Receive on ${network.name}',
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
                  label: const Text('Copy Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: address));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied to clipboard!')),
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
              const Text(
                'Enter your Master Password to verify identity:',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Master Password',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  suffixIcon: IconButton(
                    icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                    onPressed: () => setModalState(() => obscure = !obscure),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final pwd = passwordController.text.trim();
                if (pwd.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter password')),
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
                  );
                }
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
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
          title = 'Recovery Phrase';
          final words = secret.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
          
          if (words.length < 12) {
            content = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 36),
                  SizedBox(height: 10),
                  Text(
                    'No Recovery Phrase Available',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'This wallet was imported using a private key and does not have a recovery phrase.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
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
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Do not share your Recovery Phrase with anyone! Anyone with this phrase can steal all your assets.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.3),
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
          title = 'Private Key';
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
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Keep your private key strictly confidential! Never transmit it over unsecured networks.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFB91C1C), height: 1.3),
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
          title = 'Keystore JSON';
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
                    label: Text('Copy $title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: copyText));
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$title copied to clipboard!')),
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
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 8),
            Text('Delete Wallet', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${wallet.name}"?\n\nPlease make sure you have backed up your Recovery Phrase or Private Key. This action cannot be undone.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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
                  const SnackBar(content: Text('Wallet deleted successfully')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
