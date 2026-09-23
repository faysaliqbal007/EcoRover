// ============================================================
//  EcoRover — Autonomous Card Widget
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../models/rover_mode.dart';
import '../../providers/rover_provider.dart';
import '../../providers/motion_provider.dart';

class AutonomousCard extends ConsumerStatefulWidget {
  const AutonomousCard({super.key});

  @override
  ConsumerState<AutonomousCard> createState() => _AutonomousCardState();
}

class _AutonomousCardState extends ConsumerState<AutonomousCard> {
  Timer? _speedTimer;
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = ref.read(roverStatusProvider).autoSpeed.toDouble();
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    super.dispose();
  }

  void _onSpeedChanged(double val) {
    setState(() => _speed = val);
    _speedTimer?.cancel();
    _speedTimer = Timer(
      const Duration(milliseconds: EcoConstants.sliderDebounceMs),
      () => ref.read(roverStatusProvider.notifier).setAutoSpeed(val.round()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(roverStatusProvider);
    final isAuto = status.mode == RoverMode.autonomous;

    ref.listen(roverStatusProvider, (_, next) {
      if ((next.autoSpeed.toDouble() - _speed).abs() > 5) {
        setState(() => _speed = next.autoSpeed.toDouble());
      }
    });

    return _FeatureCard(
      title: 'Autonomous Mode',
      subtitle: 'Obstacle avoidance and free-space navigation',
      child: Column(
        children: [
          // Start/Stop button
          GestureDetector(
            onTap: () async {
              if (isAuto) {
                await ref.read(roverStatusProvider.notifier).stopAuto();
              } else {
                // Stop motion if active
                ref.read(motionProvider.notifier).stop();
                await ref.read(roverStatusProvider.notifier).startAuto();
              }
            },
            child: Container(
              width: double.infinity,
              height: 43,
              decoration: BoxDecoration(
                gradient: EcoColors.greenGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  isAuto ? 'STOP AUTO' : 'START AUTO',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Speed slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Speed',
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w900)),
              Text('${_speed.round()}%',
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
              min: 0,
              max: 100,
              value: _speed,
              onChanged: _onSpeedChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Feature Card container -------------------------------------------------

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: EcoColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF7D8DA8),
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
