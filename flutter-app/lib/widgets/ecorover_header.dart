// ============================================================
//  EcoRover — EcoRover Header Widget
//  Matches the V6 dashboard header exactly
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../providers/rover_provider.dart';

class EcoRoverHeader extends ConsumerWidget {
  final VoidCallback onSettingsTap;

  const EcoRoverHeader({super.key, required this.onSettingsTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionNotifierProvider);
    final isOnline = conn.isOnline;

    return SizedBox(
      height: 78,
      child: Row(
        children: [
          // Brand section with official EcoRover logo and title
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/ecorover_brand.png',
                height: 52,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/ecorover_logo.png',
                  height: 48,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Online/Offline chip
          Container(
            height: 43,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x141E5082),
                  blurRadius: 16,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline
                        ? EcoColors.onlineDot
                        : const Color(0xFFCCCCCC),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  style: const TextStyle(
                    color: EcoColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Settings button
          GestureDetector(
            onTap: onSettingsTap,
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: EcoColors.border),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.settings_outlined,
                  color: Color(0xFF405872), size: 21),
            ),
          ),
        ],
      ),
    );
  }
}
