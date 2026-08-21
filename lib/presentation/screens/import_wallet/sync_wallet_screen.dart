import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../main_navigation_screen.dart';

class SyncWalletScreen extends StatefulWidget {
  final Network network;

  const SyncWalletScreen({
    super.key,
    required this.network,
  });

  @override
  State<SyncWalletScreen> createState() => _SyncWalletScreenState();
}

class _SyncWalletScreenState extends State<SyncWalletScreen> {
  Wallet? _selectedSourceWallet;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final evmWallets = walletController.wallets.where((w) => w.networkId != widget.network.id).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          lang.tr('sync_wallet_title'),
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
                    Text(
                      lang.tr('sync_wallet_desc', params: {'network': widget.network.name}),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (evmWallets.isEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.sync_disabled_rounded, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              Text(
                                lang.tr('no_evm_wallets'),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: evmWallets.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                          itemBuilder: (context, index) {
                            final w = evmWallets[index];
                            final isSelected = _selectedSourceWallet?.id == w.id;

                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF2563EB), size: 20),
                              ),
                              title: Text(w.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              subtitle: Text(
                                '${w.address.substring(0, 8)}...${w.address.substring(w.address.length - 6)} (${w.networkId.toUpperCase()})',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              ),
                              trailing: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF1E6FFF) : const Color(0xFFCBD5E1),
                                    width: 2,
                                  ),
                                  color: isSelected ? const Color(0xFF1E6FFF) : Colors.transparent,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                                    : null,
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedSourceWallet = w;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            if (evmWallets.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: Colors.white,
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _selectedSourceWallet == null || walletController.isLoading
                        ? null
                        : () async {
                            final secret = await walletController.getWalletSecret(_selectedSourceWallet!.id);
                            if (secret == null || secret.isEmpty) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Cannot sync watch-only wallet')),
                                );
                              }
                              return;
                            }

                            final success = await walletController.importWallet(
                              name: '${widget.network.defaultNamePrefix}-${_selectedSourceWallet!.name}',
                              secret: secret,
                              importType: WalletImportType.syncWallet,
                              networkId: widget.network.id,
                            );

                            if (mounted && success) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                                (route) => false,
                              );
                            }
                          },
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
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Text(
                            lang.tr('btn_sync'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
