import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../main_navigation_screen.dart';

class WatchWalletScreen extends StatefulWidget {
  final Network network;

  const WatchWalletScreen({
    super.key,
    required this.network,
  });

  @override
  State<WatchWalletScreen> createState() => _WatchWalletScreenState();
}

class _WatchWalletScreenState extends State<WatchWalletScreen> {
  final TextEditingController _addressController = TextEditingController();
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
      '${widget.network.defaultNamePrefix}-Watch',
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
    _addressController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _addressController.text = data.text!.trim();
      });
    }
  }

  Future<void> _handleImport() async {
    final lang = context.read<LanguageController>();
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr('watch_address_hint')),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

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
    final success = await walletController.importWallet(
      name: _nameController.text.trim().isEmpty ? '${widget.network.defaultNamePrefix}-Watch' : _nameController.text.trim(),
      secret: address,
      importType: WalletImportType.watchWallet,
      networkId: widget.network.id,
    );

    if (mounted) {
      if (success) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(walletController.errorMessage ?? lang.tr('error')),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
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
          lang.tr('watch_wallet_title'),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              lang.tr('watch_wallet_tip'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1E40AF),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Address Input Label
                    Text(
                      lang.tr('watch_address_label'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Address Input Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _addressController,
                            maxLines: 3,
                            minLines: 2,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w500,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: lang.tr('watch_address_hint'),
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'sans-serif',
                                color: Color(0xFF94A3B8),
                                height: 1.5,
                              ),
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _handlePaste,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.content_paste_rounded, size: 14, color: Color(0xFF2563EB)),
                                    const SizedBox(width: 4),
                                    Text(
                                      lang.tr('paste'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Wallet Name Label
                    Text(
                      lang.tr('wallet_name'),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Wallet Name Input Box
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: _isInitializingName ? 'Loading...' : '${widget.network.defaultNamePrefix}-Watch',
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
                        suffixIcon: _nameController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.cancel_rounded, size: 20, color: Color(0xFF94A3B8)),
                                onPressed: () {
                                  setState(() {
                                    _nameController.clear();
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Section: Terms of Service & Import Button
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
                      onPressed: walletController.isLoading ? null : _handleImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: walletController.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              lang.tr('btn_import'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
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
