// ============================================================
//  EcoRover — Motion Provider
//  Controls Motion mode: starts/stops accelerometer + UDP
// ============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/constants.dart';
import '../services/motion_sensor_service.dart';
import '../services/motion_udp_service.dart';
import '../providers/settings_provider.dart';

// ---- Motion state -----------------------------------------------------------

class MotionState {
  final bool active;
  final bool calibrated;
  final double rawX;
  final double rawY;
  final double rawZ;
  final double sentX;
  final double sentY;
  final double sentZ;
  final int packetCount;

  const MotionState({
    this.active = false,
    this.calibrated = false,
    this.rawX = 0,
    this.rawY = 0,
    this.rawZ = 0,
    this.sentX = 0,
    this.sentY = 0,
    this.sentZ = 0,
    this.packetCount = 0,
  });

  MotionState copyWith({
    bool? active,
    bool? calibrated,
    double? rawX,
    double? rawY,
    double? rawZ,
    double? sentX,
    double? sentY,
    double? sentZ,
    int? packetCount,
  }) {
    return MotionState(
      active: active ?? this.active,
      calibrated: calibrated ?? this.calibrated,
      rawX: rawX ?? this.rawX,
      rawY: rawY ?? this.rawY,
      rawZ: rawZ ?? this.rawZ,
      sentX: sentX ?? this.sentX,
      sentY: sentY ?? this.sentY,
      sentZ: sentZ ?? this.sentZ,
      packetCount: packetCount ?? this.packetCount,
    );
  }
}

// ---- Motion Notifier --------------------------------------------------------

class MotionNotifier extends Notifier<MotionState> {
  final _sensor = MotionSensorService();
  MotionUdpService? _udp;
  StreamSubscription? _packetSub;
  Timer? _sendTimer;

  MotionPacket? _latestPacket;

  @override
  MotionState build() {
    ref.onDispose(_stopAll);
    return const MotionState();
  }

  Future<bool> start() async {
    if (state.active) return true;

    final settings = ref.read(settingsProvider).valueOrNull;
    _udp = MotionUdpService(
      targetIp: settings?.controllerIp,
      targetPort: settings?.udpPort,
    );

    final opened = await _udp!.open();
    if (!opened) return false;

    _sensor.start();
    _packetSub = _sensor.packets.listen((pkt) {
      _latestPacket = pkt;
    });

    // Send at ~33 Hz
    _sendTimer = Timer.periodic(
      const Duration(milliseconds: EcoConstants.motionUdpIntervalMs),
      (_) => _sendFrame(),
    );

    state = state.copyWith(active: true, calibrated: false, packetCount: 0);
    return true;
  }

  void _sendFrame() {
    final pkt = _latestPacket;
    if (pkt == null || !state.active) return;

    _udp?.sendPacket(pkt.sentX, pkt.sentY, pkt.sentZ);

    state = state.copyWith(
      rawX: pkt.rawX,
      rawY: pkt.rawY,
      rawZ: pkt.rawZ,
      sentX: pkt.sentX,
      sentY: pkt.sentY,
      sentZ: pkt.sentZ,
      packetCount: state.packetCount + 1,
    );
  }

  void updateCalibration(bool calibrated) {
    state = state.copyWith(calibrated: calibrated);
  }

  void stop() {
    _stopAll();
    state = const MotionState();
  }

  void _stopAll() {
    _sendTimer?.cancel();
    _sendTimer = null;
    _packetSub?.cancel();
    _packetSub = null;
    _sensor.stop();
    _udp?.close();
    _udp = null;
    _latestPacket = null;
  }
}

final motionProvider =
    NotifierProvider<MotionNotifier, MotionState>(MotionNotifier.new);
