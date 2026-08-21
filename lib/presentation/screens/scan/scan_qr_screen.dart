import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/custom_card.dart';
import '../transfer/receive_screen.dart';
import '../transfer/send_screen.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFlashlightOn = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleQrPayload(String rawPayload) {
    final trimmed = rawPayload.trim();
    if (trimmed.isEmpty) return;

    // 1. WalletConnect URI
    if (trimmed.startsWith('wc:')) {
      _showWalletConnectModal(trimmed);
      return;
    }

    // 2. Ethereum / Polygon Payment URI: ethereum:0x... or 0x...
    String address = trimmed;
    String? amount;
    String? token;

    if (trimmed.contains(':')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null && uri.path.isNotEmpty) {
        address = uri.path;
        amount = uri.queryParameters['value'] ?? uri.queryParameters['amount'];
        token = uri.queryParameters['token'];
      }
    }

    if (address.startsWith('0x') && address.length >= 10) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SendScreen(
            initialRecipient: address,
            initialAmount: amount,
            initialTokenSymbol: token,
          ),
        ),
      );
      return;
    }

    // 3. Web URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      _showUrlDialog(trimmed);
      return;
    }

    // 4. Default: Show raw QR payload
    _showRawPayloadDialog(trimmed);
  }

  void _showWalletConnectModal(String wcUri) {
    final lang = context.read<LanguageController>();
    final wallet = context.read<WalletController>().activeWallet;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.link_rounded, color: AppColors.primary, size: 34),
              ),
              const SizedBox(height: 14),
              Text(
                lang.tr('scan_result_wc'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text(
                'Uniswap Protocol wants to connect to your wallet',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Account', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(
                          wallet?.name ?? 'Wallet',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Network', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        Text(
                          wallet?.networkId.toUpperCase() ?? 'POLYGON',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(lang.tr('cancel')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('WalletConnect session connected successfully!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Connect', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUrlDialog(String url) {
    final lang = context.read<LanguageController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 40, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                lang.tr('scan_result_dapp'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(url, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: url));
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.tr('copied'))),
                        );
                      },
                      child: Text(lang.tr('copy')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Visiting $url...')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: Text(lang.tr('open_dapp')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRawPayloadDialog(String payload) {
    final lang = context.read<LanguageController>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2_rounded, size: 40, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'Scanned QR Content',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
                child: Text(payload, style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: payload));
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(lang.tr('copied'))));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text(lang.tr('copy')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSimulateScanSheet(BuildContext context, LanguageController lang) {
    final samples = [
      {
        'title': 'EVM Recipient Address',
        'sub': '0x71C80e460be01bc0ffFe8166D44122bc13d49bE8',
        'icon': Icons.send_rounded,
        'payload': '0x71C80e460be01bc0ffFe8166D44122bc13d49bE8',
      },
      {
        'title': 'Payment Request (2.5 POL)',
        'sub': 'ethereum:0x71C80e460be01bc0ffFe8166D44122bc13d49bE8?value=2.5&token=POL',
        'icon': Icons.payment_rounded,
        'payload': 'ethereum:0x71C80e460be01bc0ffFe8166D44122bc13d49bE8?value=2.5&token=POL',
      },
      {
        'title': 'WalletConnect v2 URI',
        'sub': 'wc:e82649a0-974b-4b47-a8fe-805c866d92f7@2?relay-protocol=irn',
        'icon': Icons.link_rounded,
        'payload': 'wc:e82649a0-974b-4b47-a8fe-805c866d92f7@2?relay-protocol=irn',
      },
      {
        'title': 'Web3 DApp Link',
        'sub': 'https://app.uniswap.org',
        'icon': Icons.language_rounded,
        'payload': 'https://app.uniswap.org',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.tr('scan_simulate'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 12),
                ...samples.map((s) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(s['icon'] as IconData, color: AppColors.primary, size: 20),
                    ),
                    title: Text(s['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      s['sub'] as String,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      _handleQrPayload(s['payload'] as String);
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Dark Viewport Background
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0F172A),
            ),
          ),

          // 2. Custom Scanning Viewfinder & Laser
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  // Corner brackets
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: _ViewfinderPainter(),
                  ),

                  // Animated Laser Line
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Positioned(
                        top: _animationController.value * 240 + 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF38BDF8),
                                Color(0xFF2563EB),
                                Color(0xFF38BDF8),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF38BDF8).withOpacity(0.8),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 3. Scan Guidance Text
          Positioned(
            left: 20,
            right: 20,
            top: MediaQuery.of(context).size.height * 0.5 + 150,
            child: Text(
              lang.tr('scan_guide'),
              style: const TextStyle(
                color: Color(0xFFE2E8F0),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // 4. Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      lang.tr('scan_title'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Row(
                      children: [
                        // Flashlight Toggle
                        IconButton(
                          icon: Icon(
                            _isFlashlightOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
                            color: _isFlashlightOn ? const Color(0xFFFBBF24) : Colors.white,
                            size: 22,
                          ),
                          onPressed: () {
                            setState(() {
                              _isFlashlightOn = !_isFlashlightOn;
                            });
                          },
                        ),
                        // Album Button
                        IconButton(
                          icon: const Icon(Icons.photo_library_outlined, color: Colors.white, size: 22),
                          onPressed: () => _showSimulateScanSheet(context, lang),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 5. Bottom Action Bar
          Positioned(
            bottom: 40,
            left: 32,
            right: 32,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // My QR Code Button
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReceiveScreen()),
                    );
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.tr('scan_my_code'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // Simulate Scan Button
                GestureDetector(
                  onTap: () => _showSimulateScanSheet(context, lang),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.tr('scan_simulate'),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const cornerLength = 28.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
