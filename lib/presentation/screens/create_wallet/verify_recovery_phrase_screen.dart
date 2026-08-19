import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/network.dart';
import '../../controllers/wallet_controller.dart';

class VerifyRecoveryPhraseScreen extends StatefulWidget {
  final String walletName;
  final Network? network;
  final String mnemonic;
  final bool isHD;

  const VerifyRecoveryPhraseScreen({
    super.key,
    required this.walletName,
    this.network,
    required this.mnemonic,
    this.isHD = false,
  });

  @override
  State<VerifyRecoveryPhraseScreen> createState() => _VerifyRecoveryPhraseScreenState();
}

class _VerifyRecoveryPhraseScreenState extends State<VerifyRecoveryPhraseScreen> {
  late final List<String> _originalWords;
  late final List<String> _shuffledWords;
  final List<String?> _selectedWords = List.filled(12, null);
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _originalWords = widget.mnemonic.trim().split(RegExp(r'\s+'));
    _shuffledWords = List.from(_originalWords)..shuffle();
  }

  void _onWordChipTapped(String word) {
    setState(() {
      _errorMessage = null;
      // Find first empty index in _selectedWords
      final emptyIndex = _selectedWords.indexOf(null);
      if (emptyIndex != -1) {
        _selectedWords[emptyIndex] = word;
      }
    });
  }

  void _onSelectedSlotTapped(int index) {
    if (_selectedWords[index] != null) {
      setState(() {
        _selectedWords[index] = null;
        _errorMessage = null;
      });
    }
  }

  void _onConfirm() async {
    // Check if all 12 are selected
    if (_selectedWords.contains(null)) {
      setState(() {
        _errorMessage = 'Please select all 12 words in order';
      });
      return;
    }

    // Check if matches original order
    for (int i = 0; i < 12; i++) {
      if (_selectedWords[i] != _originalWords[i]) {
        setState(() {
          _errorMessage = 'Invalid word order. Please re-check your backup.';
        });
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final walletController = context.read<WalletController>();
    final networkId = widget.network?.id ?? 'ethereum';

    final success = await walletController.createWallet(
      name: widget.walletName,
      mnemonic: widget.mnemonic,
      networkId: networkId,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        // Pop all back to MainNavigationScreen
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        setState(() {
          _errorMessage = walletController.errorMessage ?? 'Failed to create wallet';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Count remaining words in shuffle
    final List<String> availableWords = List.from(_shuffledWords);
    for (final sel in _selectedWords) {
      if (sel != null) {
        availableWords.remove(sel);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verification recovery phrase',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // Instructions
              const Text(
                'Tap the input box and enter the correct recovery phrases in order, or select the recovery phrases below to fill in and verify whether your backup is correct.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Upper 3x4 Grid of Slots
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
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final word = _selectedWords[index];
                    return GestureDetector(
                      onTap: () => _onSelectedSlotTapped(index),
                      child: Container(
                        decoration: BoxDecoration(
                          color: word != null ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: word != null ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                color: word != null ? AppColors.primary : const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                word ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (word != null)
                              const Icon(Icons.close_rounded, size: 14, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Lower Shuffled Word Chips
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _shuffledWords.map((word) {
                  // Check how many times word is picked vs total count in phrase
                  final totalInShuffled = _shuffledWords.where((w) => w == word).length;
                  final pickedCount = _selectedWords.where((w) => w == word).length;
                  final isAvailable = pickedCount < totalInShuffled;

                  return GestureDetector(
                    onTap: isAvailable ? () => _onWordChipTapped(word) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isAvailable ? Colors.white : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isAvailable ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: isAvailable
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isAvailable ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 36),

              // Bottom Confirm Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
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
  }
}
