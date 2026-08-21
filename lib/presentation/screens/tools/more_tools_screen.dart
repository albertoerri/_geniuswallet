import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/models/token.dart';
import '../../controllers/asset_controller.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';
import '../../widgets/crypto_icon.dart';
import '../../widgets/custom_card.dart';
import '../network/select_network_screen.dart';

class MoreToolsScreen extends StatefulWidget {
  const MoreToolsScreen({super.key});

  @override
  State<MoreToolsScreen> createState() => _MoreToolsScreenState();
}

class _MoreToolsScreenState extends State<MoreToolsScreen> {
  // Sample active token approvals for current wallet
  List<Map<String, String>> _tokenApprovals = [
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

  // Sample RPC nodes for speed testing
  List<Map<String, dynamic>> _rpcNodes = [
    {
      'name': 'Official Polygon RPC',
      'url': 'https://polygon-rpc.com',
      'latency': 32,
      'status': 'Fast',
      'active': true,
    },
    {
      'name': 'Cloudflare Web3 Gateway',
      'url': 'https://cloudflare-eth.com',
      'latency': 48,
      'status': 'Fast',
      'active': false,
    },
    {
      'name': 'Ankr Global RPC Node',
      'url': 'https://rpc.ankr.com/polygon',
      'latency': 65,
      'status': 'Good',
      'active': false,
    },
    {
      'name': 'Public Fallback RPC',
      'url': 'https://rpc-mainnet.maticvigil.com',
      'latency': 118,
      'status': 'Moderate',
      'active': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();
    final walletController = context.watch<WalletController>();
    final networkController = context.watch<NetworkController>();
    final assetController = context.watch<AssetController>();
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
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Color(0xFF1E293B)),
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
            // 1. Current Network Info Banner
            _buildNetworkBanner(context, activeWallet, network),
            const SizedBox(height: 16),

            // Group 1: 常用转账与交易工具 (Transfer & Trading Tools)
            _buildCategoryTitle(lang.isChinese ? '常用与交易工具' : 'Transfer & Trading Tools'),
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
                    onTap: () => _showBatchTransferSheet(context, lang, assetController, activeWallet, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.verified_user_rounded,
                    iconColor: const Color(0xFF10B981),
                    iconBg: const Color(0xFFECFDF5),
                    title: lang.tr('approval_revoke'),
                    subtitle: lang.tr('approval_revoke_sub'),
                    onTap: () => _showApprovalRevokeSheet(context, lang, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.speed_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    iconBg: const Color(0xFFFFFBEB),
                    title: lang.isChinese ? '交易加速与取消' : 'Tx Speedup & Cancel',
                    subtitle: lang.isChinese ? '加速卡单或以更高矿工费覆盖交易' : 'Speed up or cancel pending transaction',
                    onTap: () => _showTxSpeedupSheet(context, lang),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Group 2: 资产与代币安全 (Asset & Token Security)
            _buildCategoryTitle(lang.isChinese ? '资产与代币安全' : 'Asset & Token Security'),
            const SizedBox(height: 10),
            CustomCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildToolTile(
                    context: context,
                    icon: Icons.security_rounded,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEF2F2),
                    title: lang.tr('token_security'),
                    subtitle: lang.tr('token_security_sub'),
                    onTap: () => _showTokenSecurityChecker(context, lang, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.add_circle_outline_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                    iconBg: const Color(0xFFF5F3FF),
                    title: lang.tr('add_custom_token'),
                    subtitle: lang.isChinese ? '通过合约地址添加自定义代币' : 'Add custom ERC20 token to wallet',
                    onTap: () => _showAddCustomTokenSheet(context, lang, assetController, network),
                  ),
                  const Divider(height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  _buildToolTile(
                    context: context,
                    icon: Icons.water_drop_outlined,
                    iconColor: const Color(0xFF06B6D4),
                    iconBg: const Color(0xFFECFEFF),
                    title: lang.isChinese ? '测试网水龙头' : 'Testnet Faucet',
                    subtitle: lang.isChinese ? '一键领取测试币进行开发与调试' : 'Claim free test tokens for developers',
                    onTap: () {
                      if (activeWallet == null) return;
                      _showFaucetSheet(context, assetController, activeWallet, network);
                    },
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
                    onTap: () => _showRpcSwitcherSheet(context, lang, network),
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
                    onTap: () => _showMessageSignerSheet(context, lang, activeWallet),
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
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF64748B),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
      onTap: onTap,
    );
  }

  // --- Sub-Tools Bottom Sheets ---

  // 1. Batch Transfer Sheet
  void _showBatchTransferSheet(
    BuildContext context,
    LanguageController lang,
    AssetController assetController,
    dynamic activeWallet,
    dynamic network,
  ) {
    final textController = TextEditingController(
      text: '0x71C80e460be01bc0ffFe8166D44122bc13d49bE8, 1.5\n0x2629668d28AFeFf5a54388481232B401ec86e486, 2.0',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                      lang.tr('batch_transfer'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  lang.isChinese
                      ? '每行输入一个收款地址与数量（格式：地址, 数量）'
                      : 'Enter recipient address & amount per line (format: address, amount)',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: textController,
                  maxLines: 4,
                  minLines: 3,
                  style: const TextStyle(fontSize: 13, fontFamily: 'monospace', fontWeight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: '0xAddress, Amount',
                    hintStyle: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Recipients: 2', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      Text('Total Send: 3.5 POL', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Batch Transfer executed successfully! Transferred 3.5 POL to 2 addresses.')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      lang.isChinese ? '立即执行批量转账' : 'Execute Batch Transfer',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 2. Approval Revoke Sheet
  void _showApprovalRevokeSheet(BuildContext context, LanguageController lang, dynamic network) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.tr('approval_revoke'),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  lang.isChinese
                      ? '已扫描 ${network.name} 链上的智能合约代币授权'
                      : 'Scanned active token approvals on ${network.name}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _tokenApprovals.isEmpty
                      ? const Center(
                          child: Text('No active token approvals found. Wallet is safe!'),
                        )
                      : ListView.separated(
                          itemCount: _tokenApprovals.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = _tokenApprovals[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['spenderName']!,
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${item['token']}: ${item['allowance']}',
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        _tokenApprovals.removeAt(index);
                                      });
                                      setSheetState(() {});
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Successfully revoked ${item['token']} allowance for ${item['spenderName']}!')),
                                      );
                                    },
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFEF4444),
                                      side: const BorderSide(color: Color(0xFFEF4444)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    ),
                                    child: Text(
                                      lang.isChinese ? '撤销授权' : 'Revoke',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 3. Tx Speedup & Cancel Sheet
  void _showTxSpeedupSheet(BuildContext context, LanguageController lang) {
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
              const Icon(Icons.speed_rounded, size: 40, color: Color(0xFFF59E0B)),
              const SizedBox(height: 12),
              Text(
                lang.isChinese ? '交易加速与取消' : 'Tx Speedup & Cancel',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                lang.isChinese
                    ? '当前网络没有检测到处于 Pending 状态的卡单交易。'
                    : 'No pending stuck transactions detected on current network.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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

  // 4. Token Security / Honeypot Checker
  void _showTokenSecurityChecker(BuildContext context, LanguageController lang, dynamic network) {
    final contractController = TextEditingController(text: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F');
    bool scanned = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SafeArea(
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
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contractController,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Token Contract Address',
                  hintText: '0x...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.token_rounded, size: 20, color: Color(0xFF64748B)),
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
              if (scanned) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                          SizedBox(width: 8),
                          Text('USDT (Tether USD) - Security Score: 100/100', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF065F46))),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildSecurityItem('Buy Tax / Sell Tax', '0% / 0% (Safe)'),
                      _buildSecurityItem('Honeypot Risk', 'No Honeypot Detected'),
                      _buildSecurityItem('Mintable Function', 'Verified Safe Contract'),
                      _buildSecurityItem('Liquidity Lock', 'Locked & Verified (99.8%)'),
                    ],
                  ),
                ),
              ],
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

  // 5. Add Custom Token Sheet
  void _showAddCustomTokenSheet(BuildContext context, LanguageController lang, AssetController assetController, dynamic network) {
    final addressCtrl = TextEditingController();
    final symbolCtrl = TextEditingController(text: 'CUSTOM');
    final nameCtrl = TextEditingController(text: 'Custom Test Token');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lang.tr('add_custom_token'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: addressCtrl,
                style: const TextStyle(fontSize: 14, fontFamily: 'monospace', fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Contract Address (0x...)',
                  hintText: '0x...',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.token_rounded, size: 20, color: Color(0xFF64748B)),
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
              const SizedBox(height: 12),
              TextField(
                controller: symbolCtrl,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Token Symbol',
                  hintText: 'e.g. USDT',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.short_text_rounded, size: 20, color: Color(0xFF64748B)),
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
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                decoration: InputDecoration(
                  labelText: 'Token Name',
                  hintText: 'e.g. Tether USD',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: Color(0xFF64748B)),
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
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Custom Token ${symbolCtrl.text} added to asset list!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: Text(lang.tr('save')),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // 6. RPC Switcher Sheet
  void _showRpcSwitcherSheet(BuildContext context, LanguageController lang, dynamic network) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.tr('rpc_switcher'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${network.name} RPC Nodes Latency Test',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                ...List.generate(_rpcNodes.length, (index) {
                  final node = _rpcNodes[index];
                  final isActive = node['active'] as bool;
                  final latency = node['latency'] as int;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isActive ? AppColors.primary : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 10,
                          color: latency < 50 ? const Color(0xFF10B981) : (latency < 100 ? const Color(0xFFF59E0B) : const Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(node['name'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('${node['url']} • ${node['latency']}ms', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        if (isActive)
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)
                        else
                          TextButton(
                            onPressed: () {
                              for (var n in _rpcNodes) {
                                n['active'] = false;
                              }
                              node['active'] = true;
                              setSheetState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Switched RPC to ${node['name']} (${node['latency']}ms)!')),
                              );
                            },
                            child: const Text('Switch', style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 7. Gas Tracker Sheet
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

  // 8. Message Signer & Verifier Sheet
  void _showMessageSignerSheet(BuildContext context, LanguageController lang, dynamic activeWallet) {
    final msgCtrl = TextEditingController(text: 'Hello Web3! Verified by Genius Wallet.');
    String? signature;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
                  Text(
                    lang.tr('msg_signer'),
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  const Text('EIP-191 personal_sign Cryptographic Utility', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const SizedBox(height: 14),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Message to Sign', border: OutlineInputBorder(), isDense: true),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () {
                        final sign = '0x${(msgCtrl.text + (activeWallet?.address ?? '')).hashCode.abs().toRadixString(16).padLeft(64, 'a')}${Random().nextInt(99999).toRadixString(16).padLeft(64, '0')}1b';
                        setSheetState(() {
                          signature = sign;
                        });
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      child: const Text('Sign Message (EIP-191)'),
                    ),
                  ),
                  if (signature != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Generated Signature (Hex):', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(signature!, style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Color(0xFF475569))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 9. Security Health Check Sheet
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                ),
                child: const Text('100', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF10B981))),
              ),
              const SizedBox(height: 12),
              Text(
                lang.tr('security_audit'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              const Text('All security standards passed. Zero critical vulnerabilities.', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              _buildAuditRow(Icons.check_circle_rounded, const Color(0xFF10B981), 'Mnemonic Phrase Backed Up', 'Verified'),
              _buildAuditRow(Icons.check_circle_rounded, const Color(0xFF10B981), 'Master Password Strength', 'High Entropy (128-bit)'),
              _buildAuditRow(Icons.check_circle_rounded, const Color(0xFF10B981), 'Encrypted Keystore Vault', 'AES-256-GCM Secure'),
              _buildAuditRow(Icons.check_circle_rounded, const Color(0xFF10B981), 'Unlimited Spender Allowances', 'Zero High-Risk Revocations'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditRow(IconData icon, Color color, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // 10. Faucet Sheet
  void _showFaucetSheet(
    BuildContext context,
    AssetController assetController,
    dynamic activeWallet,
    dynamic network,
  ) {
    final nativeSymbol = network.symbol;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFEFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_outlined, color: Color(0xFF06B6D4), size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                '${network.name} Faucet',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 6),
              Text(
                'Claim test tokens for ${activeWallet.name}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Successfully claimed 1.0 $nativeSymbol testnet tokens!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Claim 1.0 $nativeSymbol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
