import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CryptoIcon extends StatelessWidget {
  final String networkId;
  final double size;

  const CryptoIcon({
    super.key,
    required this.networkId,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Widget iconContent;

    final id = networkId.toLowerCase();
    final iconSize = size * 0.55;

    switch (id) {
      case 'polygon':
      case 'pol':
      case 'matic':
        bg = AppColors.polygon;
        iconContent = Icon(Icons.hub_rounded, color: Colors.white, size: iconSize);
        break;
      case 'bnb':
      case 'binance':
      case 'bsc':
        bg = AppColors.bnb;
        iconContent = Icon(Icons.monetization_on_rounded, color: Colors.white, size: iconSize);
        break;
      case 'ethereum':
      case 'eth':
        bg = AppColors.ethereum;
        iconContent = Icon(Icons.diamond_rounded, color: Colors.white, size: iconSize);
        break;
      case 'base':
        bg = AppColors.base;
        iconContent = Icon(Icons.circle, color: Colors.white, size: iconSize * 0.85);
        break;
      case 'solana':
      case 'sol':
        bg = AppColors.solana;
        iconContent = Icon(Icons.bolt_rounded, color: Colors.white, size: iconSize);
        break;
      case 'bitcoin':
      case 'btc':
        bg = AppColors.bitcoin;
        iconContent = Icon(Icons.currency_bitcoin_rounded, color: Colors.white, size: iconSize);
        break;
      case 'tron':
      case 'trx':
        bg = AppColors.tron;
        iconContent = Icon(Icons.change_circle_rounded, color: Colors.white, size: iconSize);
        break;
      case 'arbitrum':
      case 'arb':
        bg = AppColors.arbitrum;
        iconContent = Icon(Icons.layers_rounded, color: Colors.white, size: iconSize);
        break;
      case 'usdt':
      case 'tether':
        bg = const Color(0xFF26A17B); // Tether Green
        iconContent = Icon(Icons.attach_money_rounded, color: Colors.white, size: iconSize);
        break;
      case 'usdc':
        bg = const Color(0xFF2775CA); // USDC Blue
        iconContent = Icon(Icons.currency_exchange_rounded, color: Colors.white, size: iconSize * 0.9);
        break;
      case 'dai':
      case 'usdd':
        bg = const Color(0xFFF5AC37); // DAI Orange
        iconContent = Icon(Icons.paid_rounded, color: Colors.white, size: iconSize);
        break;
      case 'weth':
        bg = const Color(0xFF627EEA);
        iconContent = Icon(Icons.diamond_outlined, color: Colors.white, size: iconSize);
        break;
      case 'cake':
        bg = const Color(0xFFD1884F); // PancakeSwap
        iconContent = Icon(Icons.cake_rounded, color: Colors.white, size: iconSize);
        break;
      case 'degen':
        bg = const Color(0xFFA36EFA); // Degen Purple
        iconContent = Icon(Icons.local_fire_department_rounded, color: Colors.white, size: iconSize);
        break;
      case 'bonk':
      case 'brett':
        bg = const Color(0xFFF28E2B);
        iconContent = Icon(Icons.pets_rounded, color: Colors.white, size: iconSize);
        break;
      case 'wbtc':
        bg = const Color(0xFFFF9900);
        iconContent = Icon(Icons.currency_bitcoin_rounded, color: Colors.white, size: iconSize);
        break;
      default:
        bg = AppColors.primary;
        iconContent = Icon(Icons.token_rounded, color: Colors.white, size: iconSize);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: iconContent,
      ),
    );
  }
}
