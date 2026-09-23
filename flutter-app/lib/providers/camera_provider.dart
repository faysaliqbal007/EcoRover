// ============================================================
//  EcoRover — Camera Provider
//  Manages MJPEG stream, zoom, fit, recording, capture
// ============================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/constants.dart';
import '../services/mjpeg_stream_service.dart';
import '../services/media_capture_service.dart';
import '../services/media_recording_service.dart';
import '../providers/settings_provider.dart';
import '../providers/rover_provider.dart';

// ---- Camera state -----------------------------------------------------------

class CameraState {
  final CameraConnectionState connectionState;
  final double zoom;
  final bool isFill; // true = cover, false = contain
  final bool isRecording;
  final Duration recordingDuration;
  final String? lastCaptureMessage;
  final Uint8List? currentFrame;

  const CameraState({
    this.connectionState = CameraConnectionState.connecting,
    this.zoom = 1.0,
    this.isFill = true,
    this.isRecording = false,
    this.recordingDuration = Duration.zero,
    this.lastCaptureMessage,
    this.currentFrame,
  });

  CameraState copyWith({
    CameraConnectionState? connectionState,
    double? zoom,
    bool? isFill,
    bool? isRecording,
    Duration? recordingDuration,
    String? lastCaptureMessage,
    Uint8List? currentFrame,
  }) {
    return CameraState(
      connectionState: connectionState ?? this.connectionState,
      zoom: zoom ?? this.zoom,
      isFill: isFill ?? this.isFill,
      isRecording: isRecording ?? this.isRecording,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      lastCaptureMessage: lastCaptureMessage ?? this.lastCaptureMessage,
      currentFrame: currentFrame ?? this.currentFrame,
    );
  }
}

// ---- Camera Notifier --------------------------------------------------------

class CameraNotifier extends Notifier<CameraState> {
  MjpegStreamService? _stream;
  MediaCaptureService? _capture;
  MediaRecordingService? _recording;

  StreamSubscription<Uint8List>? _frameSub;
  StreamSubscription<CameraConnectionState>? _stateSub;
  Timer? _recordingTimer;
  String? _currentStreamUrl;

  @override
  CameraState build() {
    ref.onDispose(_dispose);

    final settings = ref.watch(settingsProvider).valueOrNull;
    final streamUrl =
        settings?.cameraStreamUrl ?? EcoConstants.defaultCameraStream;

    if (_stream == null || _currentStreamUrl != streamUrl) {
      _currentStreamUrl = streamUrl;
      _initStream(streamUrl);
    }
    return const CameraState();
  }

  void _initStream(String url) {
    _frameSub?.cancel();
    _frameSub = null;
    _stateSub?.cancel();
    _stateSub = null;
    _stream?.stop();
    _stream?.dispose();
    _stream = null;

    final stream = MjpegStreamService(url);
    _stream = stream;
    _capture = MediaCaptureService(stream);
    _recording = MediaRecordingService(stream);

    _stateSub = stream.connectionState.listen(
      (cs) {
        state = state.copyWith(connectionState: cs);
        ref
            .read(connectionNotifierProvider.notifier)
            .setCameraOnline(cs == CameraConnectionState.connected);
      },
      onError: (_) {},
    );

    _frameSub = stream.frames.listen(
      (frame) {
        state = state.copyWith(currentFrame: frame);
      },
      onError: (_) {},
    );

    stream.start();
  }

  void retryCamera() {
    _stream?.retry();
  }

  void setZoom(double zoom) {
    final clamped = (zoom.clamp(EcoConstants.zoomMin, EcoConstants.zoomMax) *
            10)
        .round() /
        10;
    state = state.copyWith(zoom: clamped);
  }

  void toggleFit() {
    state = state.copyWith(isFill: !state.isFill);
  }

  Future<String?> capturePhoto() async {
    final result = await _capture?.capturePhoto();
    state = state.copyWith(
      lastCaptureMessage:
          result != null ? 'Photo saved: $result' : 'No frame available',
    );
    return result;
  }

  Future<bool> startRecording() async {
    final ok = await _recording?.startRecording() ?? false;
    if (ok) {
      state = state.copyWith(isRecording: true, recordingDuration: Duration.zero);
      _startRecordingTimer();
    }
    return ok;
  }

  Future<String?> stopRecording() async {
    _recordingTimer?.cancel();
    final result = await _recording?.stopRecording();
    state = state.copyWith(
      isRecording: false,
      recordingDuration: Duration.zero,
      lastCaptureMessage:
          result != null ? 'Video saved: $result' : 'Recording failed',
    );
    return result;
  }

  void _startRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer =
        Timer.periodic(const Duration(seconds: 1), (_) {
      final dur = _recording?.recordingDuration ?? Duration.zero;
      state = state.copyWith(recordingDuration: dur);
    });
  }

  Uint8List? get latestFrame => _stream?.latestFrame;

  void _dispose() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    _frameSub?.cancel();
    _frameSub = null;
    _stateSub?.cancel();
    _stateSub = null;
    _stream?.stop();
    _stream?.dispose();
    _stream = null;
  }
}

final cameraProvider =
    NotifierProvider<CameraNotifier, CameraState>(CameraNotifier.new);
