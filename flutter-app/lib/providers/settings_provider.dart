// ============================================================
//  EcoRover — Settings Provider
//  Persists configurable IPs and UDP port via SharedPreferences
// ============================================================

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app/constants.dart';

class EcoSettings {
  final String controllerIp;
  final String cameraIp;
  final int udpPort;

  const EcoSettings({
    this.controllerIp = EcoConstants.defaultControllerIp,
    this.cameraIp = EcoConstants.defaultCameraIp,
    this.udpPort = EcoConstants.defaultUdpPort,
  });

  String get controllerBase => 'http://$controllerIp';
  String get cameraStreamUrl => 'http://$cameraIp/stream';

  EcoSettings copyWith({
    String? controllerIp,
    String? cameraIp,
    int? udpPort,
  }) {
    return EcoSettings(
      controllerIp: controllerIp ?? this.controllerIp,
      cameraIp: cameraIp ?? this.cameraIp,
      udpPort: udpPort ?? this.udpPort,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<EcoSettings> {
  @override
  Future<EcoSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return EcoSettings(
      controllerIp: prefs.getString(EcoConstants.prefControllerIp) ??
          EcoConstants.defaultControllerIp,
      cameraIp: prefs.getString(EcoConstants.prefCameraIp) ??
          EcoConstants.defaultCameraIp,
      udpPort:
          prefs.getInt(EcoConstants.prefUdpPort) ?? EcoConstants.defaultUdpPort,
    );
  }

  Future<void> setControllerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(EcoConstants.prefControllerIp, ip);
    final current = state.valueOrNull ?? const EcoSettings();
    state = AsyncData(current.copyWith(controllerIp: ip));
  }

  Future<void> setCameraIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(EcoConstants.prefCameraIp, ip);
    final current = state.valueOrNull ?? const EcoSettings();
    state = AsyncData(current.copyWith(cameraIp: ip));
  }

  Future<void> setUdpPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(EcoConstants.prefUdpPort, port);
    final current = state.valueOrNull ?? const EcoSettings();
    state = AsyncData(current.copyWith(udpPort: port));
  }

  Future<void> resetToDefaults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(EcoConstants.prefControllerIp);
    await prefs.remove(EcoConstants.prefCameraIp);
    await prefs.remove(EcoConstants.prefUdpPort);
    state = const AsyncData(EcoSettings());
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, EcoSettings>(SettingsNotifier.new);
