// ============================================================
//  EcoRover — RGB Control Card Widget
//  5 color swatches + power switch
//  Locked (opacity reduced) during AUTONOMOUS / MOTION
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/rover_provider.dart';

class RgbCard extends ConsumerWidget {
  const RgbCard({super.key});

  static const _colors = [
    _RgbColor('red', Color(0xFFFF3944), 'Red'),
    _RgbColor('green', Color(0xFF00C983), 'Green'),
    _RgbColor('blue', Color(0xFF168EF3), 'Blue'),
    _RgbColor('yellow', Color(0xFFFFC21C), 'Yellow'),
    _RgbColor('white', Color(0xFFFFFFFF), 'White'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(roverStatusProvider);
    final locked = status.accessoriesLocked;
    final rgbOn = status.rgb;
    final activeColor = status.rgbColor.toLowerCase();

    return Opacity(
      opacity: locked ? 0.52 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          border: Border.all(color: EcoColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RGB Control',
              style: TextStyle(
                color: EcoColors.navy,
                fontWeight: FontWeight.w900,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Select LED color',
              style: TextStyle(color: Color(0xFF8494AD), fontSize: 9),
            ),
            const SizedBox(height: 12),

            // Color swatches (responsive, perfectly fitting any width without overflow)
            Row(
              children: _colors.map((c) {
                final isActive = rgbOn && activeColor == c.name;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: GestureDetector(
                        onTap: locked
                            ? null
                            : () async {
                                await ref
                                    .read(roverStatusProvider.notifier)
                                    .setRgbColor(c.name);
                                await ref
                                    .read(roverStatusProvider.notifier)
                                    .rgbOn();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: c.color,
                            borderRadius: BorderRadius.circular(8),
                            border: isActive
                                ? Border.all(
                                    color: const Color(0xFF092251), width: 2.5)
                                : c.name == 'white'
                                    ? Border.all(
                                        color: const Color(0xFFCBD8E5), width: 1.5)
                                    : Border.all(color: Colors.transparent),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF092251)
                                          .withValues(alpha: 0.22),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color: c.color.withValues(alpha: 0.25),
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    )
                                  ],
                          ),
                          child: Center(
                            child: isActive
                                ? Icon(
                                    Icons.check_rounded,
                                    size: 15,
                                    color: c.name == 'white' || c.name == 'yellow'
                                        ? const Color(0xFF092251)
                                        : Colors.white,
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Power switch row
            Container(
              padding: const EdgeInsets.only(top: 12),
              decoration: const BoxDecoration(
                border: Border(
                    top: BorderSide(color: Color(0xFFE7EEF4))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RGB Power',
                    style: TextStyle(
                      color: EcoColors.navy,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                  _EcoSwitch(
                    value: rgbOn,
                    disabled: locked,
                    onChanged: locked
                        ? null
                        : (val) async {
                            if (val) {
                              await ref
                                  .read(roverStatusProvider.notifier)
                                  .rgbOn();
                            } else {
                              await ref
                                  .read(roverStatusProvider.notifier)
                                  .rgbOff();
                            }
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              locked
                  ? 'Automatic during Auto / Motion'
                  : 'OFF = automatic obstacle warning',
              style: const TextStyle(
                color: Color(0xFF8190A8),
                fontSize: 8,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- iOS-like switch --------------------------------------------------------

class _EcoSwitch extends StatelessWidget {
  final bool value;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  const _EcoSwitch({
    required this.value,
    required this.disabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: value ? EcoColors.blue : const Color(0xFFCAD7E2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RgbColor {
  final String name;
  final Color color;
  final String label;
  const _RgbColor(this.name, this.color, this.label);
}
