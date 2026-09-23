// ============================================================
//  EcoRover — Offline Panel Widget
// ============================================================

import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';

class OfflinePanel extends StatelessWidget {
  final VoidCallback onRetry;

  const OfflinePanel({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: EcoShadows.card,
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: EcoColors.background,
              shape: BoxShape.circle,
              border: Border.all(color: EcoColors.border, width: 2),
            ),
            child: const Icon(Icons.wifi_off_rounded,
                size: 36, color: EcoColors.muted),
          ),
          const SizedBox(height: 20),
          const Text(
            'EcoRover Not Connected',
            style: TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Connect your phone to:',
            style: TextStyle(color: EcoColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: EcoColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EcoColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi, color: EcoColors.blue, size: 18),
                const SizedBox(width: 8),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Wi-Fi: ',
                        style: TextStyle(
                            color: EcoColors.muted, fontSize: 13),
                      ),
                      TextSpan(
                        text: EcoConstants.roverSsid,
                        style: TextStyle(
                          color: EcoColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Retry
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('RETRY CONNECTION'),
              style: ElevatedButton.styleFrom(
                backgroundColor: EcoColors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
