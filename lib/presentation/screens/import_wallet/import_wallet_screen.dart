import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/wallet_controller.dart';
import '../main_navigation_screen.dart';

enum ImportTab {
  phrase,
  privateKey,
  keystore,
}

class ImportWalletScreen extends StatefulWidget {
  final Network network;
  final WalletImportType initialImportType;

  const ImportWalletScreen({
    super.key,
    required this.network,
    this.initialImportType = WalletImportType.recoveryPhrase,
  });

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  late ImportTab _selectedTab;
  final TextEditingController _secretController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isInitializingName = true;
  bool _showAdvancedMode = false;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialImportType == WalletImportType.privateKey
        ? ImportTab.privateKey
        : ImportTab.phrase;
    _initDefaultName();
  }

  Future<void> _initDefaultName() async {
    final walletController = context.read<WalletController>();
    final defaultName = await walletController.getDefaultWalletName(
      widget.network.defaultNamePrefix,
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
    _secretController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handlePaste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      setState(() {
        _secretController.text = data.text!.trim();
      });
    }
  }

  Future<void> _handleImport() async {
    final secret = _secretController.text.trim();
    if (secret.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedTab == ImportTab.phrase
                ? 'Please enter your recovery phrase'
                : 'Please enter your private key',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please read and agree to the Service Agreement'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    final walletController = context.read<WalletController>();
    final importType = _selectedTab == ImportTab.phrase
        ? WalletImportType.recoveryPhrase
        : WalletImportType.privateKey;

    final success = await walletController.importWallet(
      name: _nameController.text.trim().isEmpty ? 'POL-1' : _nameController.text.trim(),
      secret: secret,
      importType: importType,
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
            content: Text(walletController.errorMessage ?? 'Failed to import wallet'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletController = context.watch<WalletController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Import Wallet',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, size: 24, color: Color(0xFF1E293B)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Scan QR code to import')),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Tabs: Phrase | Private Key | Keystore
                    Container(
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          _buildTabItem(ImportTab.phrase, 'Phrase'),
                          _buildTabItem(ImportTab.privateKey, 'Private Key'),
                          _buildTabItem(ImportTab.keystore, 'Keystore'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Secret Input Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _secretController,
                            maxLines: 5,
                            minLines: 4,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                            decoration: InputDecoration(
                              hintText: _getHintText(),
                              hintStyle: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _handlePaste,
                              child: const Text(
                                'Paste',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E6FFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Advanced Mode
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _showAdvancedMode = !_showAdvancedMode;
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Advanced mode',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            Icon(
                              _showAdvancedMode
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.chevron_right_rounded,
                              size: 16,
                              color: const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_showAdvancedMode) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Derivation Path: ${widget.network.derivationPath}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Wallet Name Label
                    const Text(
                      'Wallet Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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
                        hintText: _isInitializingName ? 'Loading...' : '${widget.network.defaultNamePrefix}-1',
                        hintStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF94A3B8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
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

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Confirm Button & Terms
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Terms Agreement Row
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _agreedToTerms = !_agreedToTerms;
                      });
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _agreedToTerms ? const Color(0xFF1E6FFF) : const Color(0xFFCBD5E1),
                              width: 1.5,
                            ),
                            color: _agreedToTerms ? const Color(0xFF1E6FFF) : Colors.transparent,
                          ),
                          child: _agreedToTerms
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Read & agree with ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        const Text(
                          'Service Agreement',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1E6FFF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Import Wallet Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: walletController.isLoading ? null : _handleImport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E6FFF),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFF93C5FD),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: walletController.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Import Wallet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
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

  Widget _buildTabItem(ImportTab tab, String title) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = tab;
            _secretController.clear();
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  String _getHintText() {
    switch (_selectedTab) {
      case ImportTab.phrase:
        return 'Memorizing words, separated by space';
      case ImportTab.privateKey:
        return 'Enter the plaintext private key or scan the QR code, please note the case';
      case ImportTab.keystore:
        return 'Enter keystore content or scan the QR code';
    }
  }
}
