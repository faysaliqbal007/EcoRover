// ============================================================
//  EcoRover — Emergency Stop Button
//  Large red gradient button at the bottom of the screen
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/rover_provider.dart';
import '../../providers/motion_provider.dart';

class EmergencyStopButton extends ConsumerWidget {
  const EmergencyStopButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () async {
        // 1. Stop UDP motion immediately
        ref.read(motionProvider.notifier).stop();
        // 2. Call /api/emergency
        await ref.read(roverStatusProvider.notifier).emergencyStop();
      },
      child: Container(
        width: double.infinity,
        height: 68,
        margin: const EdgeInsets.only(top: 3, bottom: 8),
        decoration: BoxDecoration(
          gradient: EcoColors.emergencyGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: EcoColors.red.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 26),
            SizedBox(width: 10),
            Text(
              'EMERGENCY STOP',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
