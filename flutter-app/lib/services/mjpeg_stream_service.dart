// ============================================================
//  EcoRover — MJPEG Stream Service
//  Connects to ESP32-CAM MJPEG stream, parses JPEG frames,
//  publishes via Stream<Uint8List>, reconnects on failure.
// ============================================================

import 'dart:async';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

enum CameraConnectionState { connecting, connected, offline }

class MjpegStreamService {
  final String streamUrl;

  final _frameController = StreamController<Uint8List>.broadcast();
  final _stateController =
      StreamController<CameraConnectionState>.broadcast();

  Stream<Uint8List> get frames => _frameController.stream;
  Stream<CameraConnectionState> get connectionState =>
      _stateController.stream;

  Uint8List? _latestFrame;
  Uint8List? get latestFrame => _latestFrame;

  bool _running = false;
  http.Client? _activeClient;
  StreamSubscription<List<int>>? _streamSub;
  Timer? _retryTimer;

  MjpegStreamService(this.streamUrl);

  void _emitState(CameraConnectionState s) {
    if (!_stateController.isClosed) {
      _stateController.add(s);
    }
  }

  void _emitFrame(Uint8List frame) {
    if (!_frameController.isClosed) {
      _frameController.add(frame);
    }
  }

  void start() {
    if (_running) return;
    _running = true;
    _connect();
  }

  void stop() {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      _streamSub?.cancel();
    } catch (_) {}
    _streamSub = null;
    try {
      _activeClient?.close();
    } catch (_) {}
    _activeClient = null;
    _emitState(CameraConnectionState.offline);
  }

  Future<void> _connect() async {
    if (!_running || _stateController.isClosed) return;

    _emitState(CameraConnectionState.connecting);

    try {
      _activeClient?.close();
      final client = http.Client();
      _activeClient = client;

      final request = http.Request('GET', Uri.parse(streamUrl));
      request.headers['Connection'] = 'keep-alive';

      final response = await client.send(request).timeout(
            const Duration(seconds: 4),
          );

      if (!_running || _stateController.isClosed) {
        client.close();
        return;
      }

      if (response.statusCode != 200) {
        _scheduleRetry();
        return;
      }

      _emitState(CameraConnectionState.connected);

      final buffer = <int>[];
      _streamSub?.cancel();
      _streamSub = response.stream.listen(
        (chunk) {
          if (_running && !_frameController.isClosed) {
            _processChunk(chunk, buffer);
          }
        },
        onError: (_) {
          if (_running && !_stateController.isClosed) {
            _scheduleRetry();
          }
        },
        onDone: () {
          if (_running && !_stateController.isClosed) {
            _scheduleRetry();
          }
        },
        cancelOnError: true,
      );

      if (!_running) {
        await _streamSub?.cancel();
        _streamSub = null;
      }
    } catch (_) {
      if (_running && !_stateController.isClosed) {
        _scheduleRetry();
      }
    }
  }

  void _processChunk(List<int> chunk, List<int> buffer) {
    buffer.addAll(chunk);

    // MJPEG frames are delimited by JPEG SOI/EOI markers
    // SOI = 0xFF 0xD8, EOI = 0xFF 0xD9
    int start = -1;
    for (int i = 0; i < buffer.length - 1; i++) {
      if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
        start = i;
      }
      if (start >= 0 &&
          buffer[i] == 0xFF &&
          buffer[i + 1] == 0xD9) {
        // Found complete JPEG frame
        final frame = Uint8List.fromList(buffer.sublist(start, i + 2));
        _latestFrame = frame;

        _emitFrame(frame);

        // Remove processed data
        buffer.removeRange(0, i + 2);
        start = -1;
        i = -1; // restart scan
      }
    }

    // Prevent unbounded buffer growth (max 256 KB)
    if (buffer.length > 256 * 1024) {
      buffer.clear();
    }
  }

  void _scheduleRetry() {
    if (!_running || _stateController.isClosed) return;
    _emitState(CameraConnectionState.offline);
    _retryTimer?.cancel();
    _retryTimer = Timer(const Duration(seconds: 3), () {
      if (_running && !_stateController.isClosed) {
        _connect();
      }
    });
  }

  void retry() {
    _retryTimer?.cancel();
    if (_running && !_stateController.isClosed) {
      _connect();
    } else {
      start();
    }
  }

  void dispose() {
    _running = false;
    _retryTimer?.cancel();
    _retryTimer = null;
    try {
      _streamSub?.cancel();
    } catch (_) {}
    _streamSub = null;
    try {
      _activeClient?.close();
    } catch (_) {}
    _activeClient = null;

    if (!_frameController.isClosed) {
      _frameController.close();
    }
    if (!_stateController.isClosed) {
      _stateController.close();
    }
  }
}
