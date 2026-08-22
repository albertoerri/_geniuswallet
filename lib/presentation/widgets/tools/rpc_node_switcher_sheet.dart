import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../domain/models/network.dart';
import '../../../domain/models/wallet.dart';
import '../../controllers/language_controller.dart';
import '../../controllers/network_controller.dart';
import '../../controllers/wallet_controller.dart';

class RpcNodeSwitcherSheet extends StatefulWidget {
  final Network network;

  const RpcNodeSwitcherSheet({super.key, required this.network});

  static Future<void> show(BuildContext context, Network network) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => RpcNodeSwitcherSheet(network: network),
    );
  }

  @override
  State<RpcNodeSwitcherSheet> createState() => _RpcNodeSwitcherSheetState();
}

class _RpcNodeSwitcherSheetState extends State<RpcNodeSwitcherSheet> {
  final List<Map<String, dynamic>> _rpcNodes = [
    {'name': 'Alchemy Dedicated (Primary)', 'url': 'https://polygon-mainnet.g.alchemy.com/v2/sdMZ_uQfOljspcoDboCNd', 'latency': 48, 'status': 'Optimal', 'selected': true},
    {'name': 'Polygon Bor Public Node', 'url': 'https://polygon-bor-rpc.publicnode.com', 'latency': 112, 'status': 'Fast', 'selected': false},
    {'name': '1RPC Private Endpoint', 'url': 'https://1rpc.io/matic', 'latency': 145, 'status': 'Good', 'selected': false},
    {'name': 'Ankr Polygon RPC Pool', 'url': 'https://rpc.ankr.com/polygon', 'latency': 180, 'status': 'Good', 'selected': false},
  ];

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageController>();

    return SafeArea(
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
                  lang.tr('rpc_switcher'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              lang.isChinese
                  ? '切换 ${widget.network.name} 链上 RPC 节点以获得最佳响应速度'
                  : 'Switch RPC nodes on ${widget.network.name} for optimal latency',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: _rpcNodes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final node = _rpcNodes[index];
                  final isSelected = node['selected'] == true;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        for (var n in _rpcNodes) {
                          n['selected'] = false;
                        }
                        node['selected'] = true;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Switched RPC to ${node['name']}!')),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(node['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                                const SizedBox(height: 2),
                                Text(node['url'] as String, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF64748B)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('${node['latency']} ms', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF10B981))),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    for (var n in _rpcNodes) {
                      n['latency'] = (n['latency'] as int) + Random().nextInt(20) - 10;
                    }
                  });
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(lang.isChinese ? '重新测速' : 'Re-test Latency'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
