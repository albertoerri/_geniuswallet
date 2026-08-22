import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../services/onchain_transaction_service.dart';
import '../../controllers/language_controller.dart';

class TokenSecuritySheet extends StatefulWidget {
  final Network network;

  const TokenSecuritySheet({super.key, required this.network});

  static Future<void> show(BuildContext context, Network network) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => TokenSecuritySheet(network: network),
    );
  }

  @override
  State<TokenSecuritySheet> createState() => _TokenSecuritySheetState();
}

class _TokenSecuritySheetState extends State<TokenSecuritySheet> {
  final _contractController = TextEditingController(text: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F');
  bool _isScanning = false;
  ContractSecurityReport? _report;

  @override
  void initState() {
    super.initState();
    _scanContract();
  }

  @override
  void dispose() {
    _contractController.dispose();
    super.dispose();
  }

  Future<void> _scanContract() async {
    final addr = _contractController.text.trim();
    if (addr.isEmpty) return;

    setState(() => _isScanning = true);
    IOnChainTransactionService onChainService;
    try {
      onChainService = context.read<IOnChainTransactionService>();
    } catch (_) {
      onChainService = OnChainTransactionService();
    }

    try {
      final res = await onChainService.checkContractSecurityOnChain(
        network: widget.network,
        contractAddress: addr,
      );
      if (mounted) {
        setState(() {
          _report = res;
          _isScanning = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.tr('token_security'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contractController,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Token Contract Address',
                  hintText: '0x...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.token_rounded, size: 20, color: Color(0xFF64748B)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.search_rounded, color: Color(0xFF2563EB)),
                    onPressed: _scanContract,
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
              const SizedBox(height: 14),
              if (_isScanning)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                  ),
                )
              else if (_report != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _report!.isHoneypotRisk ? const Color(0xFFFEF2F2) : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _report!.isHoneypotRisk ? const Color(0xFFFECACA) : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _report!.isHoneypotRisk ? Icons.warning_rounded : Icons.check_circle_rounded,
                            color: _report!.isHoneypotRisk ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_report!.symbol ?? 'TOKEN'} (${_report!.name ?? 'Contract'}) - Risk: ${_report!.riskLevel}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _report!.isHoneypotRisk ? const Color(0xFF991B1B) : const Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSecurityItem('Contract Bytecode Size', '${_report!.bytecodeSize} bytes (Verified)'),
                      _buildSecurityItem('Risk Level', _report!.riskLevel),
                      _buildSecurityItem('Honeypot Risk', _report!.isHoneypotRisk ? 'Detected High Risk!' : 'No Honeypot Detected'),
                      _buildSecurityItem('Contract Status', _report!.isContract ? 'Active On-Chain' : 'Not a Contract'),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF047857))),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46))),
        ],
      ),
    );
  }
}
