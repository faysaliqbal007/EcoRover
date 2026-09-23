// ============================================================
//  EcoRover — Sensor Dashboard Widget
//  Live: Front/Rear ultrasonic, Right IR, LDR, Obstacle
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/rover_provider.dart';

class SensorDashboard extends ConsumerWidget {
  const SensorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(roverStatusProvider);

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        border: Border.all(color: EcoColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sensor Dashboard',
            style: TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Live sensor data',
            style: TextStyle(color: Color(0xFF8494AD), fontSize: 9),
          ),
          const SizedBox(height: 8),

          // Sensor rows
          _SensorRow(
            name: 'Front Ultrasonic',
            value: status.frontDisplay,
            isDanger: false,
          ),
          _SensorRow(
            name: 'Rear Ultrasonic',
            value: status.rearDisplay,
            isDanger: false,
          ),
          _SensorRow(
            name: 'Right IR',
            value: status.rightObstacle ? 'BLOCKED' : 'CLEAR',
            isDanger: status.rightObstacle,
          ),
          _SensorRow(
            name: 'LDR',
            value: status.ldr.toString(),
            isDanger: false,
          ),
          _SensorRow(
            name: 'Obstacle',
            value: status.obstacleDisplay,
            isDanger: status.obstacleIsDanger,
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  final String name;
  final String value;
  final bool isDanger;
  final bool isLast;

  const _SensorRow({
    required this.name,
    required this.value,
    required this.isDanger,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFE8EFF4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              name,
              style: const TextStyle(
                color: Color(0xFF6C7E9D),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              color: isDanger
                  ? EcoColors.sensorDanger
                  : EcoColors.sensorGood,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
