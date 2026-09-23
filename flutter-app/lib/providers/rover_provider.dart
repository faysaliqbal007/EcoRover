// ============================================================
//  EcoRover — Rover Provider
//  Manages connection, status polling every 650ms, and API calls
// ============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/constants.dart';
import '../models/rover_status.dart';
import '../models/rover_mode.dart';
import '../services/rover_api_service.dart';
import '../providers/settings_provider.dart';

// ---- Connection state --------------------------------------------------------

enum ConnectionStatus { online, offline, connecting }

class ConnectionState {
  final ConnectionStatus status;
  final DateTime? lastSuccess;
  final String? lastStatusJson;
  final bool cameraOnline;

  const ConnectionState({
    this.status = ConnectionStatus.connecting,
    this.lastSuccess,
    this.lastStatusJson,
    this.cameraOnline = false,
  });

  bool get isOnline => status == ConnectionStatus.online;

  ConnectionState copyWith({
    ConnectionStatus? status,
    DateTime? lastSuccess,
    String? lastStatusJson,
    bool? cameraOnline,
  }) {
    return ConnectionState(
      status: status ?? this.status,
      lastSuccess: lastSuccess ?? this.lastSuccess,
      lastStatusJson: lastStatusJson ?? this.lastStatusJson,
      cameraOnline: cameraOnline ?? this.cameraOnline,
    );
  }
}

// ---- Rover Status Notifier (polls every 650ms) -------------------------------

class RoverStatusNotifier extends Notifier<RoverStatus> {
  Timer? _pollTimer;
  RoverApiService? _api;

  @override
  RoverStatus build() {
    ref.onDispose(() {
      _pollTimer?.cancel();
    });

    // Watch settings to rebuild API when IPs change
    final settings = ref.watch(settingsProvider).valueOrNull;
    _api = RoverApiService(controllerIp: settings?.controllerIp);

    _startPolling();
    return RoverStatus.defaults;
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(milliseconds: EcoConstants.statusPollMs),
      (_) => _poll(),
    );
    // Immediate first poll
    _poll();
  }

  Future<void> _poll() async {
    final status = await _api?.getStatus();
    if (status != null) {
      state = status;
      ref.read(connectionNotifierProvider.notifier).setOnline(true);
    } else {
      ref.read(connectionNotifierProvider.notifier).setOnline(false);
    }
  }

  RoverApiService get api {
    _api ??= RoverApiService(
        controllerIp: ref.read(settingsProvider).valueOrNull?.controllerIp);
    return _api!;
  }

  // ---- Manual drive commands -----------------------------------------------

  Future<void> driveCommand(DriveCommand cmd) async {
    switch (cmd) {
      case DriveCommand.forward:
        await api.manualForward();
      case DriveCommand.backward:
        await api.manualBackward();
      case DriveCommand.left:
        await api.manualLeft();
      case DriveCommand.right:
        await api.manualRight();
      case DriveCommand.strafeLeft:
        await api.manualStrafeLeft();
      case DriveCommand.strafeRight:
        await api.manualStrafeRight();
      case DriveCommand.spinLeft:
        await api.manualSpinLeft();
      case DriveCommand.spinRight:
        await api.manualSpinRight();
      case DriveCommand.diagFL:
        await api.manualDiagFL();
      case DriveCommand.diagFR:
        await api.manualDiagFR();
      case DriveCommand.diagBL:
        await api.manualDiagBL();
      case DriveCommand.diagBR:
        await api.manualDiagBR();
      case DriveCommand.stop:
        await api.manualStop();
    }
  }

  Future<void> manualStop() => api.manualStop();
  Future<void> enterIdle() => api.enterIdle();

  Future<void> setManualSpeed(int pct) => api.setManualSpeed(pct);
  Future<void> setAutoSpeed(int pct) => api.setAutoSpeed(pct);
  Future<void> setMotionSensitivity(int pct) =>
      api.setMotionSensitivity(pct);

  Future<void> setPan(int angle) => api.setPan(angle);
  Future<void> setTilt(int angle) => api.setTilt(angle);

  Future<void> startAuto() => api.startAuto();
  Future<void> stopAuto() => api.stopAuto();
  Future<void> startMotion() => api.startMotion();
  Future<void> stopMotion() => api.stopMotion();

  Future<void> setRgbColor(String name) => api.setRgbColor(name);
  Future<void> rgbOn() => api.rgbOn();
  Future<void> rgbOff() => api.rgbOff();

  Future<void> buzzerOn() => api.buzzerOn();
  Future<void> buzzerOff() => api.buzzerOff();

  Future<void> headlightOn() => api.headlightOn();
  Future<void> headlightOff() => api.headlightOff();

  Future<void> emergencyStop() async {
    await api.emergencyStop();
    await _poll();
  }
}

final roverStatusProvider =
    NotifierProvider<RoverStatusNotifier, RoverStatus>(RoverStatusNotifier.new);

// ---- Connection Notifier -----------------------------------------------------

class ConnectionNotifier extends Notifier<ConnectionState> {
  @override
  ConnectionState build() => const ConnectionState();

  void setOnline(bool online) {
    if (online) {
      state = state.copyWith(
        status: ConnectionStatus.online,
        lastSuccess: DateTime.now(),
      );
    } else {
      if (state.status != ConnectionStatus.offline) {
        state = state.copyWith(status: ConnectionStatus.offline);
      }
    }
  }

  void setCameraOnline(bool online) {
    state = state.copyWith(cameraOnline: online);
  }
}

final connectionNotifierProvider =
    NotifierProvider<ConnectionNotifier, ConnectionState>(
        ConnectionNotifier.new);
