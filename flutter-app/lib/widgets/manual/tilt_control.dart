// ============================================================
//  EcoRover — Tilt Control Widget (left column of Manual page)
//  Vertical slider 0–180° + speed slider
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../providers/rover_provider.dart';

class TiltControl extends ConsumerStatefulWidget {
  const TiltControl({super.key});

  @override
  ConsumerState<TiltControl> createState() => _TiltControlState();
}

class _TiltControlState extends ConsumerState<TiltControl> {
  Timer? _tiltTimer;
  Timer? _speedTimer;

  // Local optimistic values
  late double _tilt;
  late double _speed;

  @override
  void initState() {
    super.initState();
    final status = ref.read(roverStatusProvider);
    _tilt = status.tilt.toDouble();
    _speed = status.manualSpeed.toDouble();
  }

  @override
  void dispose() {
    _tiltTimer?.cancel();
    _speedTimer?.cancel();
    super.dispose();
  }

  void _onTiltChanged(double val) {
    setState(() => _tilt = val);
    _tiltTimer?.cancel();
    _tiltTimer = Timer(
      const Duration(milliseconds: EcoConstants.sliderDebounceMs),
      () => ref.read(roverStatusProvider.notifier).setTilt(val.round()),
    );
  }

  void _onSpeedChanged(double val) {
    setState(() => _speed = val);
    _speedTimer?.cancel();
    _speedTimer = Timer(
      const Duration(milliseconds: EcoConstants.sliderDebounceMs),
      () => ref.read(roverStatusProvider.notifier).setManualSpeed(val.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sync with status when not interacting
    ref.listen(roverStatusProvider, (_, next) {
      // Only sync if the difference is large (avoid fighting user input)
      if ((next.tilt.toDouble() - _tilt).abs() > 5) {
        setState(() => _tilt = next.tilt.toDouble());
      }
      if ((next.manualSpeed.toDouble() - _speed).abs() > 5) {
        setState(() => _speed = next.manualSpeed.toDouble());
      }
    });

    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 6, 9),
      decoration: BoxDecoration(
        border: Border.all(color: EcoColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Tilt label
          const Text(
            'TILT',
            style: TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),

          // Angle display
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF4BD8FB)),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${_tilt.round()}°',
              style: const TextStyle(
                color: Color(0xFF087DB9),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Tilt scale with vertical slider
          SizedBox(
            height: 258,
            child: Row(
              children: [
                // Degree marks
                const SizedBox(
                  width: 38,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _DegLabel('180°'),
                      _DegLabel('135°'),
                      _DegLabel('90°'),
                      _DegLabel('45°'),
                      _DegLabel('0°'),
                    ],
                  ),
                ),

                // Vertical slider
                Expanded(
                  child: RotatedBox(
                    quarterTurns: 3, // rotate -90° to make vertical
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 16),
                        activeTrackColor: EcoColors.cyan,
                        inactiveTrackColor: EcoColors.border,
                        thumbColor: EcoColors.cyan,
                        overlayColor: EcoColors.cyan.withOpacity(0.2),
                      ),
                      child: Slider(
                        min: 0,
                        max: 180,
                        value: _tilt,
                        onChanged: _onTiltChanged,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Speed box
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: Color(0xFFE7EEF4))),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SPEED',
                      style: TextStyle(
                        color: EcoColors.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                    Text(
                      '${_speed.round()}%',
                      style: const TextStyle(
                        color: EcoColors.navy,
                        fontWeight: FontWeight.w900,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6),
                    overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12),
                    activeTrackColor: EcoColors.blue,
                    inactiveTrackColor: EcoColors.border,
                    thumbColor: EcoColors.blue,
                    overlayColor: EcoColors.blue.withOpacity(0.2),
                  ),
                  child: Slider(
                    min: 0,
                    max: 100,
                    value: _speed,
                    onChanged: _onSpeedChanged,
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

class _DegLabel extends StatelessWidget {
  final String text;
  const _DegLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF7386AB),
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
