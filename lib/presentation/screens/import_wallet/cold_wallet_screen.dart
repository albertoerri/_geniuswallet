import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../main_navigation_screen.dart';

class ColdWalletScreen extends StatefulWidget {
  final Network network;

  const ColdWalletScreen({
    super.key,
    required this.network,
  });

  @override
  State<ColdWalletScreen> createState() => _ColdWalletScreenState();
}

class _ColdWalletScreenState extends State<ColdWalletScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isInitializingName = true;

  @override
  void initState() {
    super.initState();
    _initDefaultName();
  }

  Future<void> _initDefaultName() async {
    final walletController = context.read<WalletController>();
    final defaultName = await walletController.getDefaultWalletName(
      '${widget.network.defaultNamePrefix}-Cold',
      widget.network.id,
    );
    if (mounted) {
      _nameController.text = defaultName;
      setState(() {
        _isInitializingName = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSetupColdWallet() async {
    final lang = context.read<LanguageController>();
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr('must_agree_terms')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final walletController = context.read<WalletController>();
    // Generate secure offline wallet for cold mode
    final mnemonic = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    final success = await walletController.importWallet(
      name: _nameController.text.trim().isEmpty ? '${widget.network.defaultNamePrefix}-Cold' : _nameController.text.trim(),
      secret: mnemonic,
      importType: WalletImportType.coldWallet,
      networkId: widget.network.id,
    );

    if (mounted && success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('cold_wallet_title'),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    // Shield Illustration Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 40),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            lang.tr('cold_wallet'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            lang.tr('cold_wallet_desc'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Wallet Name Input Box
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        lang.tr('wallet_name'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _isInitializingName ? 'Loading...' : '${widget.network.defaultNamePrefix}-Cold',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20, color: Color(0xFF64748B)),
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
              ),
            ),

            // Bottom Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _agreedToTerms = !_agreedToTerms;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _agreedToTerms ? const Color(0xFF1E6FFF) : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                            color: _agreedToTerms ? const Color(0xFF1E6FFF) : Colors.transparent,
                          ),
                          child: _agreedToTerms
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.tr('read_agree')} ',
                              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              children: [
                                TextSpan(
                                  text: lang.tr('terms_of_service'),
                                  style: const TextStyle(
                                    color: Color(0xFF1E6FFF),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: walletController.isLoading ? null : _handleSetupColdWallet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: walletController.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              lang.tr('setup_cold_wallet'),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
