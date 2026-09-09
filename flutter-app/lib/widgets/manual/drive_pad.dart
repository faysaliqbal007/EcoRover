// ============================================================
//  EcoRover — Drive Pad Widget
//  Spin row, 3x3 d-pad, fast row
//  LATCHED behavior: tap once → stays active, tap STOP → stops
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/rover_mode.dart';
import '../../providers/rover_provider.dart';

class DrivePad extends ConsumerWidget {
  const DrivePad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(roverStatusProvider);
    final activeDrive = status.mode == RoverMode.manual
        ? status.activeDrive
        : null;

    return Column(
      children: [
        // Spin row
        Row(
          children: [
            Expanded(
              child: _SpinBtn(
                label: '↺ SPIN L',
                cmd: DriveCommand.spinLeft,
                active: activeDrive == DriveCommand.spinLeft,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _SpinBtn(
                label: 'SPIN R ↻',
                cmd: DriveCommand.spinRight,
                active: activeDrive == DriveCommand.spinRight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),

        // D-pad 3×3
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _DriveBtn(
                    label: '↖',
                    style: _BtnStyle.light,
                    cmd: DriveCommand.diagFL,
                    active: activeDrive == DriveCommand.diagFL,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _DriveBtn(
                    label: '↑',
                    style: _BtnStyle.dark,
                    cmd: DriveCommand.forward,
                    active: activeDrive == DriveCommand.forward,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _DriveBtn(
                    label: '↗',
                    style: _BtnStyle.light,
                    cmd: DriveCommand.diagFR,
                    active: activeDrive == DriveCommand.diagFR,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _DriveBtn(
                    label: '←',
                    style: _BtnStyle.dark,
                    cmd: DriveCommand.left,
                    active: activeDrive == DriveCommand.left,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(child: _StopBtn()),
                const SizedBox(width: 7),
                Expanded(
                  child: _DriveBtn(
                    label: '→',
                    style: _BtnStyle.dark,
                    cmd: DriveCommand.right,
                    active: activeDrive == DriveCommand.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _DriveBtn(
                    label: '↙',
                    style: _BtnStyle.light,
                    cmd: DriveCommand.diagBL,
                    active: activeDrive == DriveCommand.diagBL,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _DriveBtn(
                    label: '↓',
                    style: _BtnStyle.dark,
                    cmd: DriveCommand.backward,
                    active: activeDrive == DriveCommand.backward,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: _DriveBtn(
                    label: '↘',
                    style: _BtnStyle.light,
                    cmd: DriveCommand.diagBR,
                    active: activeDrive == DriveCommand.diagBR,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),

        // Fast row
        Row(
          children: [
            Expanded(
              child: _FastBtn(
                label: '« FAST L',
                cmd: DriveCommand.strafeLeft,
                active: activeDrive == DriveCommand.strafeLeft,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _FastBtn(
                label: 'FAST R »',
                cmd: DriveCommand.strafeRight,
                active: activeDrive == DriveCommand.strafeRight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---- Button style enum ------------------------------------------------------
enum _BtnStyle { dark, light }

// ---- Drive button (tap = latch) ---------------------------------------------
class _DriveBtn extends ConsumerWidget {
  final String label;
  final _BtnStyle style;
  final DriveCommand cmd;
  final bool active;

  const _DriveBtn({
    required this.label,
    required this.style,
    required this.cmd,
    required this.active,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget btn = GestureDetector(
      onTap: () =>
          ref.read(roverStatusProvider.notifier).driveCommand(cmd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        constraints: BoxConstraints(
          minHeight: _btnHeight(context),
        ),
        decoration: BoxDecoration(
          gradient: style == _BtnStyle.dark ? EcoColors.driveButtonDark : null,
          color: style == _BtnStyle.light ? Colors.white : null,
          border: style == _BtnStyle.light
              ? Border.all(color: EcoColors.border)
              : active
                  ? Border.all(
                      color: EcoColors.blue.withOpacity(0.5), width: 3)
                  : null,
          borderRadius: BorderRadius.circular(15),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: EcoColors.blue.withOpacity(0.32),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: style == _BtnStyle.dark ? Colors.white : EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: _fontSize(context),
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: active ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: btn,
    );
  }

  double _btnHeight(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w * 0.20).clamp(65.0, 84.0);
  }

  double _fontSize(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w * 0.09).clamp(26.0, 37.0);
  }
}

// ---- Stop button ------------------------------------------------------------
class _StopBtn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = (MediaQuery.of(context).size.width * 0.20).clamp(65.0, 84.0);

    return GestureDetector(
      onTap: () => ref.read(roverStatusProvider.notifier).manualStop(),
      child: Container(
        height: h,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFFF202B), width: 2),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '■',
              style: TextStyle(
                color: const Color(0xFFEE1824),
                fontSize:
                    (MediaQuery.of(context).size.width * 0.07).clamp(22.0, 29.0),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'STOP',
              style: TextStyle(
                color: Color(0xFFEE1824),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Spin button ------------------------------------------------------------
class _SpinBtn extends ConsumerWidget {
  final String label;
  final DriveCommand cmd;
  final bool active;

  const _SpinBtn({
    required this.label,
    required this.cmd,
    required this.active,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = (MediaQuery.of(context).size.width * 0.15).clamp(53.0, 65.0);

    return AnimatedScale(
      scale: active ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: GestureDetector(
        onTap: () =>
            ref.read(roverStatusProvider.notifier).driveCommand(cmd),
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: active
                  ? EcoColors.blue.withOpacity(0.5)
                  : EcoColors.border,
              width: active ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: EcoColors.blue.withOpacity(0.2),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: EcoColors.navy,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---- Fast button ------------------------------------------------------------
class _FastBtn extends ConsumerWidget {
  final String label;
  final DriveCommand cmd;
  final bool active;

  const _FastBtn({
    required this.label,
    required this.cmd,
    required this.active,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = (MediaQuery.of(context).size.width * 0.14).clamp(49.0, 59.0);

    return AnimatedScale(
      scale: active ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 80),
      child: GestureDetector(
        onTap: () =>
            ref.read(roverStatusProvider.notifier).driveCommand(cmd),
        child: Container(
          height: h,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: active
                  ? EcoColors.blue.withOpacity(0.5)
                  : EcoColors.border,
              width: active ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: EcoColors.blue.withOpacity(0.2),
                      blurRadius: 8,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: EcoColors.navy,
                fontWeight: FontWeight.w900,
                fontSize:
                    (MediaQuery.of(context).size.width * 0.038)
                        .clamp(11.0, 16.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
