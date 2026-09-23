// ============================================================
//  EcoRover — Motion Card Widget
//  ENABLE MOTION / CALIBRATING... / STOP MOTION
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../models/rover_mode.dart';
import '../../providers/rover_provider.dart';
import '../../providers/motion_provider.dart';

class MotionCard extends ConsumerStatefulWidget {
  const MotionCard({super.key});

  @override
  ConsumerState<MotionCard> createState() => _MotionCardState();
}

class _MotionCardState extends ConsumerState<MotionCard> {
  Timer? _sensitivityTimer;
  late double _sensitivity;

  @override
  void initState() {
    super.initState();
    _sensitivity =
        ref.read(roverStatusProvider).motionSensitivity.toDouble();
  }

  @override
  void dispose() {
    _sensitivityTimer?.cancel();
    super.dispose();
  }

  void _onSensitivityChanged(double val) {
    setState(() => _sensitivity = val);
    _sensitivityTimer?.cancel();
    _sensitivityTimer = Timer(
      const Duration(milliseconds: EcoConstants.sliderDebounceMs),
      () => ref
          .read(roverStatusProvider.notifier)
          .setMotionSensitivity(val.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(roverStatusProvider);
    final isMotion = status.mode == RoverMode.motion;
    final calibrated = status.phoneCalibrated;

    ref.listen(roverStatusProvider, (_, next) {
      // Sync calibration state to motion provider
      if (next.mode == RoverMode.motion) {
        ref.read(motionProvider.notifier).updateCalibration(next.phoneCalibrated);
      }
      if ((next.motionSensitivity.toDouble() - _sensitivity).abs() > 5) {
        setState(() => _sensitivity = next.motionSensitivity.toDouble());
      }
    });

    String btnLabel;
    if (!isMotion) {
      btnLabel = 'ENABLE MOTION';
    } else if (!calibrated) {
      btnLabel = 'CALIBRATING...';
    } else {
      btnLabel = 'STOP MOTION';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: EcoColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Motion Control',
            style: TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Control EcoRover using phone tilt',
            style: TextStyle(
              color: Color(0xFF7D8DA8),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Enable/Stop button
          GestureDetector(
            onTap: () async {
              if (isMotion) {
                // Stop UDP first, then API
                ref.read(motionProvider.notifier).stop();
                await ref.read(roverStatusProvider.notifier).stopMotion();
              } else {
                // Start API first, then UDP+sensor
                await ref.read(roverStatusProvider.notifier).startMotion();
                await ref.read(motionProvider.notifier).start();
              }
            },
            child: Container(
              width: double.infinity,
              height: 43,
              decoration: BoxDecoration(
                gradient: EcoColors.purpleGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isMotion || !calibrated)
                      const SizedBox.shrink()
                    else
                      const Icon(Icons.sensors, color: Colors.white, size: 16),
                    if (isMotion && !calibrated)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      btnLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Sensitivity slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Sensitivity',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900)),
              Text('${_sensitivity.round()}%',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 6),
              activeTrackColor: EcoColors.blue,
              inactiveTrackColor: EcoColors.border,
              thumbColor: EcoColors.blue,
            ),
            child: Slider(
              min: 10,
              max: 100,
              value: _sensitivity,
              onChanged: _onSensitivityChanged,
            ),
          ),

          // Calibration note
          if (isMotion && !calibrated)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: EcoColors.purple.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Hold phone in neutral position. Calibrating...',
                style: TextStyle(
                  color: EcoColors.purple,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
