// ============================================================
//  EcoRover — Fullscreen Camera Screen
//  Shows only MJPEG feed + zoom + exit button
//  Sends /api/idle before entering
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme.dart';
import '../app/constants.dart';
import '../providers/camera_provider.dart';

class FullscreenCameraScreen extends ConsumerStatefulWidget {
  const FullscreenCameraScreen({super.key});

  @override
  ConsumerState<FullscreenCameraScreen> createState() =>
      _FullscreenCameraScreenState();
}

class _FullscreenCameraScreenState
    extends ConsumerState<FullscreenCameraScreen> {
  @override
  void initState() {
    super.initState();
    // Lock to landscape for fullscreen camera
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Restore portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);
    final frame = camState.currentFrame;
    final zoom = camState.zoom;
    final isFill = camState.isFill;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera feed
          if (frame != null && frame.isNotEmpty)
            Transform.scale(
              scale: zoom,
              child: Image.memory(
                frame,
                fit: isFill ? BoxFit.cover : BoxFit.contain,
                gaplessPlayback: true,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: EcoColors.cyan),
            ),

          // Exit button
          Positioned(
            top: 16,
            right: 16,
            child: SafeArea(
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.white30),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
          ),

          // Toolbar bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 16,
            child: SafeArea(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _ToolBtn(
                        label: isFill ? 'FILL' : 'FIT',
                        onTap: () =>
                            ref.read(cameraProvider.notifier).toggleFit(),
                      ),
                      const SizedBox(width: 8),
                      _ToolBtn(
                        label: '−',
                        onTap: () => ref
                            .read(cameraProvider.notifier)
                            .setZoom(zoom - EcoConstants.zoomStep),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2,
                            activeTrackColor: EcoColors.cyan,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: EcoColors.cyan,
                          ),
                          child: Slider(
                            min: EcoConstants.zoomMin,
                            max: EcoConstants.zoomMax,
                            divisions: 20,
                            value: zoom,
                            onChanged: (v) =>
                                ref.read(cameraProvider.notifier).setZoom(v),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ToolBtn(
                        label: '+',
                        onTap: () => ref
                            .read(cameraProvider.notifier)
                            .setZoom(zoom + EcoConstants.zoomStep),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${zoom.toStringAsFixed(1)}x',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
