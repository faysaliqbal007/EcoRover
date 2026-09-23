// ============================================================
//  EcoRover — Camera Card Widget
//  MJPEG stream display with LIVE indicator, zoom, Fit/Fill,
//  fullscreen, capture and record controls
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../app/constants.dart';
import '../../providers/camera_provider.dart';
import '../../providers/rover_provider.dart';
import '../../services/mjpeg_stream_service.dart';

class CameraCard extends ConsumerStatefulWidget {
  final VoidCallback? onFullscreen;

  const CameraCard({super.key, this.onFullscreen});

  @override
  ConsumerState<CameraCard> createState() => _CameraCardState();
}

class _CameraCardState extends ConsumerState<CameraCard> {
  @override
  Widget build(BuildContext context) {
    final camState = ref.watch(cameraProvider);
    final isOnline =
        camState.connectionState == CameraConnectionState.connected;

    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: EcoShadows.cameraCard,
      ),
      child: Column(
        children: [
          // Camera viewport
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: double.infinity,
              height: _viewportHeight(context),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Camera feed or offline placeholder
                  _CameraFeed(isFill: camState.isFill, zoom: camState.zoom),

                  // LIVE indicator
                  Positioned(
                    top: 11,
                    left: 11,
                    child: _LiveBadge(isOnline: isOnline),
                  ),

                  // Fullscreen button
                  Positioned(
                    top: 11,
                    right: 11,
                    child: _CamButton(
                      icon: Icons.fullscreen,
                      onTap: () {
                        // Send idle before fullscreen
                        ref.read(roverStatusProvider.notifier).enterIdle();
                        widget.onFullscreen?.call();
                      },
                    ),
                  ),

                  // Offline overlay
                  if (!isOnline)
                    _CameraOfflineOverlay(
                      state: camState.connectionState,
                      onRetry: () =>
                          ref.read(cameraProvider.notifier).retryCamera(),
                    ),

                  // Camera toolbar at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 9,
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 365),
                        child: _CamToolbar(
                          zoom: camState.zoom,
                          isFill: camState.isFill,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _viewportHeight(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return (w * 0.58).clamp(215.0, 285.0);
  }
}

// ---- Camera Feed (MJPEG frames via Image.memory) ----------------------------

class _CameraFeed extends ConsumerStatefulWidget {
  final bool isFill;
  final double zoom;

  const _CameraFeed({required this.isFill, required this.zoom});

  @override
  ConsumerState<_CameraFeed> createState() => _CameraFeedState();
}

class _CameraFeedState extends ConsumerState<_CameraFeed> {
  @override
  Widget build(BuildContext context) {
    // Get current frame from camera state
    final frame = ref.watch(
      cameraProvider.select((s) => s.currentFrame),
    );

    final boxFit = widget.isFill ? BoxFit.cover : BoxFit.contain;

    if (frame == null || frame.isEmpty) {
      return Container(
        color: const Color(0xFF020B16),
        child: const Center(
          child: CircularProgressIndicator(color: EcoColors.cyan),
        ),
      );
    }

    return Container(
      color: const Color(0xFF020B16),
      child: Transform.scale(
        scale: widget.zoom,
        child: Image.memory(
          frame,
          fit: boxFit,
          gaplessPlayback: true,
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}

// ---- Live Badge --------------------------------------------------------------

class _LiveBadge extends StatelessWidget {
  final bool isOnline;
  const _LiveBadge({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 37,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: BoxDecoration(
        color: const Color(0xE812293F),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline ? const Color(0xFFFF2540) : Colors.grey,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'LIVE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Camera icon button ------------------------------------------------------

class _CamButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CamButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xE812293F),
          border: Border.all(color: Colors.white30),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: Colors.white, size: 21),
      ),
    );
  }
}

// ---- Camera Toolbar ----------------------------------------------------------

class _CamToolbar extends ConsumerWidget {
  final double zoom;
  final bool isFill;

  const _CamToolbar({required this.zoom, required this.isFill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cam = ref.read(cameraProvider.notifier);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 11),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xD6061829),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Fit / Fill toggle
          _ToolBtn(
            label: isFill ? 'FILL' : 'FIT',
            onTap: () => cam.toggleFit(),
          ),
          const SizedBox(width: 5),

          // Zoom Out
          _ToolBtn(
            label: '−',
            onTap: () => cam.setZoom(zoom - EcoConstants.zoomStep),
          ),
          const SizedBox(width: 5),

          // Zoom slider
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: EcoColors.cyan,
                inactiveTrackColor: Colors.white24,
                thumbColor: EcoColors.cyan,
                overlayColor: EcoColors.cyan.withValues(alpha: 0.2),
              ),
              child: Slider(
                min: EcoConstants.zoomMin,
                max: EcoConstants.zoomMax,
                divisions: 20,
                value: zoom,
                onChanged: (v) => cam.setZoom(v),
              ),
            ),
          ),
          const SizedBox(width: 5),

          // Zoom In
          _ToolBtn(
            label: '+',
            onTap: () => cam.setZoom(zoom + EcoConstants.zoomStep),
          ),
          const SizedBox(width: 5),

          // Zoom text
          SizedBox(
            width: 40,
            child: Text(
              '${zoom.toStringAsFixed(1)}x',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w900,
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
        height: 29,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ---- Camera Offline Overlay --------------------------------------------------

class _CameraOfflineOverlay extends StatelessWidget {
  final CameraConnectionState state;
  final VoidCallback onRetry;

  const _CameraOfflineOverlay(
      {required this.state, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam_off_outlined,
                color: Colors.white54, size: 48),
            const SizedBox(height: 10),
            Text(
              state == CameraConnectionState.connecting
                  ? 'Connecting...'
                  : 'CAMERA OFFLINE',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: EcoColors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'RETRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
