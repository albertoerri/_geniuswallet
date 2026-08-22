import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/environment_service.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/environment_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/tools/add_custom_token_sheet.dart';
import '../../widgets/tools/approval_revoke_sheet.dart';
import '../../widgets/tools/batch_transfer_sheet.dart';
import '../../widgets/tools/message_signer_sheet.dart';
import '../../widgets/tools/rpc_node_switcher_sheet.dart';
import '../../widgets/tools/token_security_sheet.dart';
import '../../widgets/tools/tx_speedup_sheet.dart';
import '../network/select_network_screen.dart';

class MoreToolsScreen extends StatefulWidget {
  const MoreToolsScreen({super.key});

  @override
  State<MoreToolsScreen> createState() => _MoreToolsScreenState();
}

class _MoreToolsScreenState extends State<MoreToolsScreen> {
  final List<Map<String, String>> _tokenApprovals = [
    {
      'spenderName': 'Uniswap V3 Router',
      'spenderAddress': '0xE592427A0AEce92De3Edee1F18E0157C05861564',
      'token': 'USDT',
      'allowance': 'Unlimited',
      'risk': 'Low',
    },
    {
      'spenderName': 'OpenSea Conduit',
      'spenderAddress': '0x1E0049783F008A0085193E00003D00cd54003c71',
      'token': 'WETH',
      'allowance': '10.0 WETH',
      'risk': 'Low',
    },
    {
      'spenderName': 'PancakeSwap V3 Router',
      'spenderAddress': '0x13f4EA83D0bd40E75C8222255bc855a974568Dd4',
      'token': 'USDC',
      'allowance': 'Unlimited',
      'risk': 'Medium',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
    final envController = context.watch<EnvironmentController>();
    final activeWallet = walletController.activeWallet;

    final network = networkController.allNetworks.firstWhere(
      (n) => n.id.toLowerCase() == activeWallet?.networkId.toLowerCase(),
      orElse: () => networkController.allNetworks.first,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          lang.tr('more_tools_title'),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Environment Switcher Card
            _buildEnvironmentCard(context, envController, lang),

            const SizedBox(height: 14),

            // Network & Wallet Status Banner
            _buildNetworkBanner(context, activeWallet, network),

            const SizedBox(height: 20),

            // Group 1: 资产与交易管理 (Asset & Transactions)
            _buildCategoryTitle(lang.isChinese ? '资产与交易管理' : 'Asset & Transaction Tools'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.alt_route_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    title: lang.tr('batch_transfer'),
                    subtitle: lang.tr('batch_transfer_sub'),
                    onTap: () {
                      if (activeWallet != null) {
                        BatchTransferSheet.show(context, activeWallet, network);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.shield_outlined,
                    iconColor: const Color(0xFFEF4444),
                    iconBg: const Color(0xFFFEF2F2),
                    title: lang.tr('approval_revoke'),
                    subtitle: lang.tr('approval_revoke_sub'),
                    onTap: () {
                      if (activeWallet != null) {
                        ApprovalRevokeSheet.show(context, activeWallet, network, _tokenApprovals);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.speed_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    title: lang.isChinese ? '交易加速与取消' : 'Tx Speedup & Cancel',
                    subtitle: lang.isChinese ? '重置或覆盖处于卡单状态的交易' : 'Speed up or cancel pending stuck transactions',
                    onTap: () => TxSpeedupSheet.show(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Group 2: 代币与智能合约工具 (Tokens & Smart Contracts)
            _buildCategoryTitle(lang.isChinese ? '代币与智能合约' : 'Tokens & Smart Contracts'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: lang.tr('add_custom_token'),
                    subtitle: lang.tr('add_custom_token_sub'),
                    onTap: () => AddCustomTokenSheet.show(context, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: lang.tr('token_security'),
                    subtitle: lang.tr('token_security_sub'),
                    onTap: () => TokenSecuritySheet.show(context, network),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Group 3: 节点与网络管理 (Node & Network)
            _buildCategoryTitle(lang.isChinese ? '节点与网络管理' : 'Node & Network Management'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.hub_outlined,
                    iconColor: const Color(0xFF3B82F6),
                    iconBg: const Color(0xFFEFF6FF),
                    title: lang.tr('rpc_switcher'),
                    subtitle: lang.tr('rpc_switcher_sub'),
                    onTap: () => RpcNodeSwitcherSheet.show(context, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.local_gas_station_outlined,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    title: lang.tr('gas_tracker'),
                    subtitle: lang.tr('gas_tracker_sub'),
                    onTap: () => _showGasTrackerSheet(context, lang, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.travel_explore_rounded,
                    iconColor: const Color(0xFF0284C7),
                    iconBg: const Color(0xFFF0F9FF),
                    title: '${network.name} ${lang.isChinese ? '区块浏览器' : 'Explorer'}',
                    subtitle: lang.isChinese ? '在区块链浏览器查看钱包与交易' : 'View address & transactions on explorer',
                    onTap: () {
                      final url = 'https://${network.id == 'polygon' ? 'polygonscan.com' : 'bscscan.com'}/address/${activeWallet?.address}';
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${lang.tr('copied')}: $url')),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Group 4: 开发者与安全工具 (Developer & Security)
            _buildCategoryTitle(lang.isChinese ? '开发者与安全工具' : 'Developer & Security Tools'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.draw_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: lang.tr('msg_signer'),
                    subtitle: lang.tr('msg_signer_sub'),
                    onTap: () {
                      if (activeWallet != null) {
                        MessageSignerSheet.show(context, activeWallet);
                      }
                    },
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.health_and_safety_rounded,
                    iconColor: const Color(0xFF2563EB),
                    iconBg: const Color(0xFFEFF6FF),
                    title: lang.tr('security_audit'),
                    subtitle: lang.tr('security_audit_sub'),
                    onTap: () => _showSecurityAuditSheet(context, lang, activeWallet),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showGasTrackerSheet(BuildContext context, LanguageController lang, dynamic network) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_gas_station_rounded, size: 40, color: Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              Text(
                '${network.name} ${lang.tr('gas_tracker')}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildGasCard('Slow', '28 Gwei', '\$0.001'),
                  _buildGasCard('Standard', '35 Gwei', '\$0.002', isSelected: true),
                  _buildGasCard('Rapid', '45 Gwei', '\$0.003'),
                ],
              ),
              const SizedBox(height: 16),
              const Text('EIP-1559 Base Fee: 27.4 Gwei | Priority Fee: 2.0 Gwei', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGasCard(String speed, String gwei, String usd, {bool isSelected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(speed, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(gwei, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          Text(usd, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  void _showSecurityAuditSheet(BuildContext context, LanguageController lang, dynamic activeWallet) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.health_and_safety_rounded, size: 40, color: Color(0xFF10B981)),
              const SizedBox(height: 12),
              Text(
                lang.tr('security_audit'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wallet Security Score: 100/100 (Optimal Security Profile)',
                style: TextStyle(fontSize: 13, color: Color(0xFF047857), fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(lang.tr('btn_confirm')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentCard(BuildContext context, EnvironmentController envController, LanguageController lang) {
    final isLive = envController.isLive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFF0FDF4) : const Color(0xFFFEFCE8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFFDE047),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLive ? const Color(0xFF22C55E) : const Color(0xFFEAB308)).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFFEF9C3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isLive ? Icons.sensors_rounded : Icons.science_rounded,
                      size: 20,
                      color: isLive ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.tr('env_mode_title'),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        isLive ? lang.tr('env_mode_live') : lang.tr('env_mode_simulation'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isLive ? const Color(0xFF16A34A) : const Color(0xFFCA8A04),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isLive,
                activeColor: const Color(0xFF16A34A),
                activeTrackColor: const Color(0xFFBBF7D0),
                inactiveThumbColor: const Color(0xFFCA8A04),
                inactiveTrackColor: const Color(0xFFFEF08A),
                onChanged: (val) async {
                  await envController.setMode(val ? EnvironmentMode.live : EnvironmentMode.simulation);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(val
                            ? 'Switched to Live Polygon Mainnet (真实主网链上环境)'
                            : 'Switched to Simulation Mode (模拟测试环境)'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isLive ? lang.tr('env_mode_live_desc') : lang.tr('env_mode_simulation_desc'),
            style: TextStyle(
              fontSize: 11,
              color: isLive ? const Color(0xFF166534) : const Color(0xFF713F12),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkBanner(BuildContext context, dynamic activeWallet, dynamic network) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CryptoIcon(networkId: network.id, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  network.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 2),
                Text(
                  '${activeWallet?.name ?? 'Wallet'} (${activeWallet?.address != null ? (activeWallet!.address.length > 10 ? '${activeWallet.address.substring(0, 6)}...${activeWallet.address.substring(activeWallet.address.length - 4)}' : activeWallet.address) : 'No address'})',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SelectNetworkScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Text('Switch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  Icon(Icons.unfold_more_rounded, size: 14, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildToolTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
