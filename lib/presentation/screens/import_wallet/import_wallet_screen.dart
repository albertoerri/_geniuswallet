import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
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
  final TextEditingController _keystorePasswordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _customPathController = TextEditingController();

  bool _obscureKeystorePassword = true;
  bool _agreedToTerms = false;
  bool _isInitializingName = true;
  bool _showAdvancedMode = false;
  String _selectedDerivationPath = "m/44'/60'/0'/0/0";
  bool _isCustomDerivationPath = false;

  final List<String> _presetPaths = [
    "m/44'/60'/0'/0/0",
    "m/44'/60'/0'/0",
    "m/44'/60'/0'/0/1",
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialImportType == WalletImportType.privateKey) {
      _selectedTab = ImportTab.privateKey;
    } else if (widget.initialImportType == WalletImportType.keystore) {
      _selectedTab = ImportTab.keystore;
    } else {
      _selectedTab = ImportTab.phrase;
    }
    _selectedDerivationPath = widget.network.derivationPath;
    _customPathController.text = _selectedDerivationPath;
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
    _keystorePasswordController.dispose();
    _nameController.dispose();
    _customPathController.dispose();
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
    final lang = context.read<LanguageController>();
    final secret = _secretController.text.trim();
    if (secret.isEmpty) {
      String msg;
      if (_selectedTab == ImportTab.phrase) {
        msg = lang.tr('enter_phrase_hint');
      } else if (_selectedTab == ImportTab.privateKey) {
        msg = lang.tr('enter_pk_hint');
      } else {
        msg = lang.tr('enter_keystore_hint');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }

    if (_selectedTab == ImportTab.keystore && _keystorePasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.tr('enter_keystore_pwd_hint')),
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
    WalletImportType importType;
    if (_selectedTab == ImportTab.phrase) {
      importType = WalletImportType.recoveryPhrase;
    } else if (_selectedTab == ImportTab.privateKey) {
      importType = WalletImportType.privateKey;
    } else {
      importType = WalletImportType.keystore;
    }

    final finalDerivationPath = _isCustomDerivationPath
        ? _customPathController.text.trim()
        : _selectedDerivationPath;

    final success = await walletController.importWallet(
      name: _nameController.text.trim().isEmpty ? '${widget.network.defaultNamePrefix}-1' : _nameController.text.trim(),
      secret: secret,
      importType: importType,
      networkId: widget.network.id,
      derivationPath: finalDerivationPath,
      password: _keystorePasswordController.text,
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

  String _getHintText(LanguageController lang) {
    switch (_selectedTab) {
      case ImportTab.phrase:
        return lang.tr('enter_phrase_hint');
      case ImportTab.privateKey:
        return lang.tr('enter_pk_hint');
      case ImportTab.keystore:
        return lang.tr('enter_keystore_hint');
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
          lang.tr('import_wallet'),
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
                          _buildTabItem(ImportTab.phrase, lang.tr('recovery_phrase')),
                          _buildTabItem(ImportTab.privateKey, lang.tr('private_key')),
                          _buildTabItem(ImportTab.keystore, lang.tr('keystore')),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Secret Input Card
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
                            controller: _secretController,
                            maxLines: 5,
                            minLines: 4,
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'monospace',
                              color: Color(0xFF0F172A),
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: _getHintText(lang),
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
                          const SizedBox(height: 12),
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

                    // Keystore Password Field (Shown only on Keystore Tab)
                    if (_selectedTab == ImportTab.keystore) ...[
                      const SizedBox(height: 16),
                      Text(
                        lang.tr('keystore_password'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keystorePasswordController,
                        obscureText: _obscureKeystorePassword,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        decoration: InputDecoration(
                          hintText: lang.tr('enter_keystore_pwd_hint'),
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Color(0xFF64748B)),
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
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureKeystorePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 20,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureKeystorePassword = !_obscureKeystorePassword;
                              });
                            },
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Advanced Mode Toggle
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
                            Text(
                              lang.tr('advanced_mode'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
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

                    // Advanced Derivation Path Selector & Editor
                    if (_showAdvancedMode) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFCBD5E1), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.tr('derivation_path'),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Preset Chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ..._presetPaths.map((path) {
                                  final isSelected = !_isCustomDerivationPath && _selectedDerivationPath == path;
                                  return ChoiceChip(
                                    label: Text(
                                      path,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'monospace',
                                        color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFFEFF6FF),
                                    backgroundColor: const Color(0xFFF8FAFC),
                                    side: BorderSide(
                                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                    ),
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _isCustomDerivationPath = false;
                                          _selectedDerivationPath = path;
                                        });
                                      }
                                    },
                                  );
                                }),
                                ChoiceChip(
                                  label: Text(
                                    lang.tr('custom_path'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _isCustomDerivationPath ? const Color(0xFF2563EB) : const Color(0xFF475569),
                                      fontWeight: _isCustomDerivationPath ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                  selected: _isCustomDerivationPath,
                                  selectedColor: const Color(0xFFEFF6FF),
                                  backgroundColor: const Color(0xFFF8FAFC),
                                  side: BorderSide(
                                    color: _isCustomDerivationPath ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _isCustomDerivationPath = true;
                                    });
                                  },
                                ),
                              ],
                            ),

                            // Custom Input field if Custom selected
                            if (_isCustomDerivationPath) ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: _customPathController,
                                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                                decoration: InputDecoration(
                                  hintText: lang.tr('enter_custom_path'),
                                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2.0),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

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
                        hintText: _isInitializingName ? 'Loading...' : '${widget.network.defaultNamePrefix}-1',
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

  Widget _buildTabItem(ImportTab tab, String label) {
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
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
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
}
