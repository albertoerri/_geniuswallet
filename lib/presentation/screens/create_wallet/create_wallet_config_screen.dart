import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../controllers/language_controller.dart';
import 'backup_tips_screen.dart';

class CreateWalletConfigScreen extends StatefulWidget {
  final Network? network;
  final bool isHD;

  const CreateWalletConfigScreen({
    super.key,
    this.network,
    this.isHD = false,
  });

  @override
  State<CreateWalletConfigScreen> createState() => _CreateWalletConfigScreenState();
}

class _CreateWalletConfigScreenState extends State<CreateWalletConfigScreen> {
  late final TextEditingController _nameController;
  bool _agreedToTerms = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final defaultName = widget.isHD
        ? 'HD-1'
        : (widget.network?.symbol != null ? '${widget.network!.symbol}-1' : 'Wallet-1');
    _nameController = TextEditingController(text: defaultName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onNext() {
    final lang = context.read<LanguageController>();
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = lang.tr('enter_wallet_name_hint');
      });
      return;
    }

    if (!_agreedToTerms) {
      setState(() {
        _errorMessage = lang.tr('must_agree_terms');
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BackupTipsScreen(
          walletName: name,
          network: widget.network,
          isHD: widget.isHD,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final title = widget.isHD
        ? lang.tr('create_hd_wallet')
        : lang.tr('create_network_wallet', params: {'network': widget.network?.name ?? 'Wallet'});

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 20),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subtitle
                      Text(
                        lang.tr('set_wallet_name_sub'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 28),

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

                      // Wallet Name Input
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        onChanged: (_) => setState(() {
                          if (_errorMessage != null) _errorMessage = null;
                        }),
                        decoration: InputDecoration(
                          hintText: lang.tr('enter_wallet_name_hint'),
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

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Agreement Row (Terms of Service)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _agreedToTerms = !_agreedToTerms;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _agreedToTerms ? AppColors.primary : Colors.transparent,
                                border: Border.all(
                                  color: _agreedToTerms
                                      ? AppColors.primary
                                      : const Color(0xFFCBD5E1),
                                  width: 1.5,
                                ),
                              ),
                              child: _agreedToTerms
                                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${lang.tr('read_agree')} ',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(lang.tr('terms_of_service'))),
                                );
                              },
                              child: Text(
                                lang.tr('terms_of_service'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Step Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            widget.isHD ? lang.tr('create_wallet') : lang.tr('btn_next_step'),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
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
          },
        ),
      ),
    );
  }
}
