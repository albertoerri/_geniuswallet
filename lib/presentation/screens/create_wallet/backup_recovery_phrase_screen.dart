import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../controllers/wallet_controller.dart';
import 'verify_recovery_phrase_screen.dart';

class BackupRecoveryPhraseScreen extends StatefulWidget {
  final String walletName;
  final Network? network;
  final String mnemonic;
  final bool isHD;

  const BackupRecoveryPhraseScreen({
    super.key,
    required this.walletName,
    this.network,
    required this.mnemonic,
    this.isHD = false,
  });

  @override
  State<BackupRecoveryPhraseScreen> createState() => _BackupRecoveryPhraseScreenState();
}

class _BackupRecoveryPhraseScreenState extends State<BackupRecoveryPhraseScreen> {
  int _selectedTab = 0; // 0: Handwritten Backup, 1: KeyPal Card Backup
  late final List<String> _words;

  @override
  void initState() {
    super.initState();
    _words = widget.mnemonic.trim().split(RegExp(r'\s+'));
  }

  void _onMaybeLater() async {
    final walletController = context.read<WalletController>();
    final networkId = widget.network?.id ?? 'ethereum';
    final success = await walletController.createWallet(
      name: widget.walletName,
      mnemonic: widget.mnemonic,
      networkId: networkId,
    );

    if (success && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _onVerifyNow() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VerifyRecoveryPhraseScreen(
          walletName: widget.walletName,
          network: widget.network,
          mnemonic: widget.mnemonic,
          isHD: widget.isHD,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'Backup Recovery Phrase',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle Tip
              const Text(
                'Make sure to write down your Recovery Phrase accurately and keep it in a safe place.Never take screenshots or store or share it online,to avoid the risk of leakage.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Tab Switcher
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 0
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Handwritten Backup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 0 ? FontWeight.w600 : FontWeight.normal,
                              color: _selectedTab == 0 ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _selectedTab == 1
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'KeyPal Card Backup',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedTab == 1 ? FontWeight.w600 : FontWeight.normal,
                              color: _selectedTab == 1 ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Header Row: Recovery Phrase (12 words) & Show QR Code
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Recovery Phrase (12 words)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _showQrDialog(context);
                    },
                    child: const Text(
                      'Show QR Code',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3x4 Grid of 12 Words
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(12),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _words.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _words[index],
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Copy Recovery Phrase Button
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: widget.mnemonic));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recovery phrase copied to clipboard!')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Copy Recovery Phrase',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Warning Card: Remember
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Remember:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '・ Don\'t disclose recovery phrase to anyone\n'
                      '・ Once the recovery phrase is lost, assets cannot be recovered\n'
                      '・ Please do not backup and save by screenshots or network transmission\n'
                      '・ Don\'t uninstall the app when in issues, please contact us for help',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Primary Button: Completed backup, verify it now
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _onVerifyNow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Completed backup, verify it now',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Secondary Button: Maybe Later
              Center(
                child: TextButton(
                  onPressed: _onMaybeLater,
                  child: const Text(
                    'Maybe Later',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recovery Phrase QR'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2_rounded, size: 140, color: AppColors.primary),
            const SizedBox(height: 12),
            const Text(
              'Scan this QR code from an offline device to import your recovery phrase.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
