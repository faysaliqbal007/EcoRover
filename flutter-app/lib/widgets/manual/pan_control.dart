// ============================================================
//  EcoRover — Pan Control Widget
//  Horizontal slider 0–180° with ±5° buttons
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../providers/rover_provider.dart';

class PanControl extends ConsumerStatefulWidget {
  const PanControl({super.key});

  @override
  ConsumerState<PanControl> createState() => _PanControlState();
}

class _PanControlState extends ConsumerState<PanControl> {
  Timer? _panTimer;
  late double _pan;

  @override
  void initState() {
    super.initState();
    _pan = ref.read(roverStatusProvider).pan.toDouble();
  }

  @override
  void dispose() {
    _panTimer?.cancel();
    super.dispose();
  }

  void _setPan(double val) {
    final clamped = val.clamp(0.0, 180.0);
    setState(() => _pan = clamped);
    _panTimer?.cancel();
    _panTimer = Timer(
      const Duration(milliseconds: EcoConstants.sliderDebounceMs),
      () => ref.read(roverStatusProvider.notifier).setPan(clamped.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(roverStatusProvider, (_, next) {
      if ((next.pan.toDouble() - _pan).abs() > 5) {
        setState(() => _pan = next.pan.toDouble());
      }
    });

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: EcoShadows.card,
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  '↔ AZIMUTH PAN (0° - 180°)',
                  style: TextStyle(
                    color: EcoColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF4BD8FB)),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  '${_pan.round()}°',
                  style: const TextStyle(
                    color: Color(0xFF087DB9),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Slider row
          Row(
            children: [
              // -5°
              _PanBtn(
                label: '< −5°',
                onTap: () => _setPan(_pan - 5),
              ),
              const SizedBox(width: 7),

              // Slider
              Expanded(
                child: Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 7),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 14),
                        activeTrackColor: EcoColors.cyan,
                        inactiveTrackColor: EcoColors.border,
                        thumbColor: EcoColors.cyan,
                        overlayColor: EcoColors.cyan.withOpacity(0.2),
                      ),
                      child: Slider(
                        min: 0,
                        max: 180,
                        value: _pan,
                        onChanged: _setPan,
                      ),
                    ),
                    // Degree marks
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _Mark('0°'),
                          _Mark('45°'),
                          _Mark('90°'),
                          _Mark('135°'),
                          _Mark('180°'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 7),
              // +5°
              _PanBtn(
                label: '+5° >',
                onTap: () => _setPan(_pan + 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PanBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        height: 39,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: EcoColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF2E4861),
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  final String label;
  const _Mark(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF7889AA),
        fontSize: 8,
      ),
    );
  }
}
