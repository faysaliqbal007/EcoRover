// ============================================================
//  EcoRover — Control Header Widget
//  Matches the V6 controlBar: title, capture, record, mode select
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../models/rover_mode.dart';
import '../../providers/rover_provider.dart';
import '../../providers/camera_provider.dart';

class ControlHeader extends ConsumerWidget {
  final bool isSmartMode;
  final ValueChanged<bool> onModeChanged;

  const ControlHeader({
    super.key,
    required this.isSmartMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(roverStatusProvider);
    final camState = ref.watch(cameraProvider);
    final isRecording = camState.isRecording;

    return Container(
      constraints: const BoxConstraints(minHeight: 68),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0x121E5082),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Title area
          Expanded(
            flex: 3,
            child: Row(
              children: [
                // Wheel icon
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF344E68), width: 2.5),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 17,
                    color: Color(0xFF344E68),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSmartMode ? 'Smart Control' : 'Drive Control',
                        style: const TextStyle(
                          color: EcoColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 13.5,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSmartMode ? 'Advanced Features' : 'Manual Driving',
                        style: const TextStyle(
                          color: Color(0xFF8090AB),
                          fontSize: 8.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Capture button (camera icon)
          _BarButton(
            child: const Icon(Icons.camera_alt_outlined,
                size: 18, color: Color(0xFF334B65)),
            onTap: () async {
              final result =
                  await ref.read(cameraProvider.notifier).capturePhoto();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result != null
                        ? 'Photo saved!'
                        : 'No camera frame available'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: result != null
                        ? EcoColors.green
                        : EcoColors.red,
                  ),
                );
              }
            },
          ),
          const SizedBox(width: 4),

          // Record button (red dot or flexible timer pill)
          _BarButton(
            padding: EdgeInsets.symmetric(
              horizontal: isRecording ? 8 : 6,
            ),
            child: isRecording
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EcoColors.red,
                          boxShadow: [
                            BoxShadow(
                              color: EcoColors.red.withValues(alpha: 0.45),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDur(camState.recordingDuration),
                        style: const TextStyle(
                          color: EcoColors.red,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EcoColors.red,
                      boxShadow: [
                        BoxShadow(
                          color: EcoColors.red.withValues(alpha: 0.15),
                          blurRadius: 3,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
            onTap: () async {
              if (isRecording) {
                final result =
                    await ref.read(cameraProvider.notifier).stopRecording();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result != null
                          ? 'Video saved!'
                          : 'Recording failed'),
                      duration: const Duration(seconds: 2),
                      backgroundColor:
                          result != null ? EcoColors.green : EcoColors.red,
                    ),
                  );
                }
              } else {
                await ref.read(cameraProvider.notifier).startRecording();
              }
            },
          ),
          const SizedBox(width: 4),

          // Mode selector
          Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6FF),
              borderRadius: BorderRadius.circular(9),
            ),
            child: DropdownButton<bool>(
              value: isSmartMode,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Color(0xFF078DE4), size: 18),
              style: const TextStyle(
                color: Color(0xFF078DE4),
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
              items: const [
                DropdownMenuItem(
                  value: false,
                  child: Text('Manual'),
                ),
                DropdownMenuItem(
                  value: true,
                  child: Text('Smart'),
                ),
              ],
              onChanged: (val) {
                if (val != null && val != isSmartMode) {
                  // Send idle before mode change
                  ref.read(roverStatusProvider.notifier).enterIdle();
                  onModeChanged(val);
                }
              },
            ),
          ),
          const SizedBox(width: 4),

          // Mode status
          Container(
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: EcoColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: EcoColors.onlineDot,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _modeLabel(status.mode, isSmartMode),
                  style: const TextStyle(
                    color: EcoColors.navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _modeLabel(RoverMode mode, bool smart) {
    if (smart) {
      switch (mode) {
        case RoverMode.autonomous:
          return 'Auto';
        case RoverMode.motion:
          return 'Motion';
        default:
          return 'Ready';
      }
    } else {
      return mode == RoverMode.manual ? 'Manual' : 'Idle';
    }
  }

  String _formatDur(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _BarButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final EdgeInsetsGeometry? padding;

  const _BarButton({
    required this.child,
    required this.onTap,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        constraints: const BoxConstraints(minWidth: 34),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFFBFDFF),
          border: Border.all(color: EcoColors.border),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Center(child: child),
      ),
    );
  }
}
