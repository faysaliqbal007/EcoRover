// ============================================================
//  EcoRover App — RoverApiService
//  All HTTP GET calls to /api/* — V6 contract only
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../app/constants.dart';
import '../models/rover_status.dart';

class RoverApiService {
  final String baseUrl;

  static final _client = http.Client();

  RoverApiService({String? controllerIp})
      : baseUrl =
            'http://${controllerIp ?? EcoConstants.defaultControllerIp}';

  static const Duration _timeout =
      Duration(milliseconds: EcoConstants.connectionTimeoutMs);

  // ---- Connection check --------------------------------------------------

  Future<bool> isReachable() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(_timeout);
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---- Status + Config ---------------------------------------------------

  Future<RoverStatus?> getStatus() async {
    try {
      final resp = await _client
          .get(Uri.parse('$baseUrl/api/status'),
              headers: {'Cache-Control': 'no-store'})
          .timeout(_timeout);
      if (resp.statusCode == 200) {
        final json = jsonDecode(resp.body) as Map<String, dynamic>;
        return RoverStatus.fromJson(json);
      }
    } catch (_) {}
    return null;
  }

  // ---- General -----------------------------------------------------------

  Future<void> enterIdle() => _get('/api/idle');

  Future<void> emergencyStop() => _get('/api/emergency');

  // ---- Manual drive ------------------------------------------------------

  Future<void> manualForward() => _get('/api/manual/forward');
  Future<void> manualBackward() => _get('/api/manual/backward');
  Future<void> manualLeft() => _get('/api/manual/left');
  Future<void> manualRight() => _get('/api/manual/right');
  Future<void> manualStrafeLeft() => _get('/api/manual/strafe-left');
  Future<void> manualStrafeRight() => _get('/api/manual/strafe-right');
  Future<void> manualSpinLeft() => _get('/api/manual/spin-left');
  Future<void> manualSpinRight() => _get('/api/manual/spin-right');
  Future<void> manualDiagFL() => _get('/api/manual/diag-fl');
  Future<void> manualDiagFR() => _get('/api/manual/diag-fr');
  Future<void> manualDiagBL() => _get('/api/manual/diag-bl');
  Future<void> manualDiagBR() => _get('/api/manual/diag-br');
  Future<void> manualStop() => _get('/api/manual/stop');

  Future<void> setManualSpeed(int percent) =>
      _get('/api/manual/speed?percent=${percent.clamp(0, 100)}');

  // ---- Autonomous --------------------------------------------------------

  Future<void> startAuto() => _get('/api/auto/start');
  Future<void> stopAuto() => _get('/api/auto/stop');
  Future<void> setAutoSpeed(int percent) =>
      _get('/api/auto/speed?percent=${percent.clamp(0, 100)}');

  // ---- Motion ------------------------------------------------------------

  Future<void> startMotion() => _get('/api/motion/start');
  Future<void> stopMotion() => _get('/api/motion/stop');
  Future<void> setMotionSensitivity(int percent) =>
      _get('/api/motion/sensitivity?percent=${percent.clamp(10, 100)}');

  // ---- Servo -------------------------------------------------------------

  Future<void> setPan(int angle) =>
      _get('/api/pan?angle=${angle.clamp(0, 180)}');
  Future<void> setTilt(int angle) =>
      _get('/api/tilt?angle=${angle.clamp(0, 180)}');

  // ---- RGB ---------------------------------------------------------------

  Future<void> setRgbColor(String name) =>
      _get('/api/rgb/color?name=${Uri.encodeComponent(name)}');
  Future<void> rgbOn() => _get('/api/rgb/on');
  Future<void> rgbOff() => _get('/api/rgb/off');

  // ---- Buzzer ------------------------------------------------------------

  Future<void> buzzerOn() => _get('/api/buzzer/on');
  Future<void> buzzerOff() => _get('/api/buzzer/off');

  // ---- Headlight ---------------------------------------------------------

  Future<void> headlightOn() => _get('/api/headlight/on');
  Future<void> headlightOff() => _get('/api/headlight/off');

  // ---- Private helper ----------------------------------------------------

  Future<void> _get(String path) async {
    try {
      await _client
          .get(Uri.parse('$baseUrl$path'),
              headers: {'Cache-Control': 'no-store'})
          .timeout(_timeout);
    } catch (_) {
      // Silently drop — connection service handles offline state
    }
  }
}
