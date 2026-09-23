// ============================================================
//  EcoRover — Additional Options Widget
//  Buzzer + Headlight option cards (3-column grid)
//  Locked during AUTONOMOUS / MOTION
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../providers/rover_provider.dart';

class AdditionalOptions extends ConsumerWidget {
  const AdditionalOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(roverStatusProvider);
    final locked = status.accessoriesLocked;
    final buzzerOn = status.buzzer;
    final headlightManual = status.headlightManual;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: EcoShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Options',
            style: TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 9),

          // 3-column grid: Buzzer, Headlight, (Recording handled by controlBar)
          Row(
            children: [
              // Buzzer
              Expanded(
                child: Opacity(
                  opacity: locked ? 0.52 : 1.0,
                  child: _OptionCard(
                    title: 'Buzzer',
                    stateLabel: locked
                        ? 'AUTO'
                        : (buzzerOn ? 'ON' : 'AUTO'),
                    value: buzzerOn,
                    disabled: locked,
                    onChanged: locked
                        ? null
                        : (val) async {
                            if (val) {
                              await ref
                                  .read(roverStatusProvider.notifier)
                                  .buzzerOn();
                            } else {
                              await ref
                                  .read(roverStatusProvider.notifier)
                                  .buzzerOff();
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 7),

              // Headlight
              Expanded(
                child: Opacity(
                  opacity: locked ? 0.52 : 1.0,
                  child: _OptionCard(
                    title: 'Headlight',
                    stateLabel: locked
                        ? 'AUTO'
                        : (headlightManual ? 'ON' : 'AUTO'),
                    value: headlightManual,
                    disabled: locked,
                    onChanged: locked
                        ? null
                        : (val) async {
                            if (val) {
                              await ref
                                  .read(roverStatusProvider.notifier)
                                  .headlightOn();
                            } else {
                              await ref
                                  .read(roverStatusProvider.notifier)
                                  .headlightOff();
                            }
                          },
                  ),
                ),
              ),
              const SizedBox(width: 7),

              // Clients count
              Expanded(
                child: Container(
                  constraints:
                      const BoxConstraints(minHeight: 64),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: EcoColors.border),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Clients',
                        style: TextStyle(
                          color: EcoColors.navy,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          const Icon(Icons.devices_outlined,
                              size: 12, color: EcoColors.muted),
                          const SizedBox(width: 4),
                          Text(
                            '${status.clients}',
                            style: const TextStyle(
                              color: EcoColors.blue,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Option card with toggle ------------------------------------------------

class _OptionCard extends StatelessWidget {
  final String title;
  final String stateLabel;
  final bool value;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  const _OptionCard({
    required this.title,
    required this.stateLabel,
    required this.value,
    required this.disabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: EcoColors.border),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: EcoColors.navy,
              fontWeight: FontWeight.w900,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stateLabel,
                style: const TextStyle(
                  color: EcoColors.muted,
                  fontWeight: FontWeight.w900,
                  fontSize: 8,
                ),
              ),
              _SmallSwitch(
                value: value,
                disabled: disabled,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallSwitch extends StatelessWidget {
  final bool value;
  final bool disabled;
  final ValueChanged<bool>? onChanged;

  const _SmallSwitch({
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
        width: 40,
        height: 22,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: value ? EcoColors.blue : const Color(0xFFCAD7E2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 16,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
