// ============================================================
//  EcoRover — Controller Screen
//  Main single-screen app controller
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../app/theme.dart';
import '../providers/rover_provider.dart';
import '../providers/motion_provider.dart';

import '../widgets/ecorover_header.dart';
import '../widgets/camera_card.dart';
import '../widgets/control_header.dart';
import '../widgets/common/emergency_stop_button.dart';
import '../widgets/common/offline_panel.dart';
import '../widgets/manual/tilt_control.dart';
import '../widgets/manual/drive_pad.dart';
import '../widgets/manual/pan_control.dart';
import '../widgets/smart/autonomous_card.dart';
import '../widgets/smart/motion_card.dart';
import '../widgets/smart/rgb_card.dart';
import '../widgets/smart/sensor_dashboard.dart';
import '../widgets/smart/additional_options.dart';
import '../screens/settings_screen.dart';
import '../screens/fullscreen_camera_screen.dart';

class ControllerScreen extends ConsumerStatefulWidget {
  const ControllerScreen({super.key});

  @override
  ConsumerState<ControllerScreen> createState() => _ControllerScreenState();
}

class _ControllerScreenState extends ConsumerState<ControllerScreen>
    with WidgetsBindingObserver {
  bool _isSmartMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    // Portrait only for controller
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // Stop manual drive
      final status = ref.read(roverStatusProvider);
      if (status.mode.name == 'manual') {
        ref.read(roverStatusProvider.notifier).manualStop();
      }
      // Stop motion UDP immediately
      ref.read(motionProvider.notifier).stop();
      ref.read(roverStatusProvider.notifier).stopMotion();
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = ref.watch(connectionNotifierProvider);
    final isOnline = conn.isOnline;

    return Scaffold(
      backgroundColor: EcoColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 22),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Header
                      EcoRoverHeader(
                        onSettingsTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        ),
                      ),

                      // Offline panel
                      if (!isOnline) ...[
                        OfflinePanel(
                          onRetry: () {
                            // Force a status poll
                            ref.invalidate(roverStatusProvider);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Camera card (always visible)
                      CameraCard(
                        onFullscreen: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    const FullscreenCameraScreen()),
                          );
                        },
                      ),

                      // Control header
                      ControlHeader(
                        isSmartMode: _isSmartMode,
                        onModeChanged: (smart) {
                          setState(() => _isSmartMode = smart);
                        },
                      ),

                      // Page content
                      if (!_isSmartMode) ...[
                        _ManualPage(),
                      ] else ...[
                        _SmartPage(),
                      ],

                      // Emergency stop (always at bottom)
                      const EmergencyStopButton(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
//  Manual Page
// ============================================================

class _ManualPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Drive panel
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(19),
            boxShadow: EcoShadows.card,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Tilt + speed
              SizedBox(
                width: _tiltWidth(context),
                child: const TiltControl(),
              ),
              const SizedBox(width: 8),

              // Right: Spin + d-pad + fast
              const Expanded(child: DrivePad()),
            ],
          ),
        ),

        // Pan panel
        const PanControl(),
        const SizedBox(height: 10),
      ],
    );
  }

  double _tiltWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w <= 385) return 86;
    return (w * 0.25).clamp(92.0, 112.0);
  }
}

// ============================================================
//  Smart Page
// ============================================================

class _SmartPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width <= 335;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: EcoShadows.card,
      ),
      child: Column(
        children: [
          // Top row: Auto + Motion cards
          if (isNarrow)
            const Column(
              children: [
                AutonomousCard(),
                SizedBox(height: 8),
                MotionCard(),
              ],
            )
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: AutonomousCard()),
                SizedBox(width: 8),
                Expanded(child: MotionCard()),
              ],
            ),
          const SizedBox(height: 8),

          // Lower row: RGB + Sensors
          if (isNarrow)
            const Column(
              children: [
                RgbCard(),
                SizedBox(height: 8),
                SensorDashboard(),
              ],
            )
          else
            const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: RgbCard()),
                SizedBox(width: 8),
                Expanded(child: SensorDashboard()),
              ],
            ),
          const SizedBox(height: 8),

          // Additional options
          const AdditionalOptions(),
        ],
      ),
    );
  }
}
