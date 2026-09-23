// ============================================================
//  EcoRover — Media Recording Service
//  Records MJPEG stream frames to MP4 using ffmpeg_kit_flutter
// ============================================================

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import '../services/mjpeg_stream_service.dart';

class MediaRecordingService {
  final MjpegStreamService _streamService;

  bool _recording = false;
  StreamSubscription<Uint8List>? _frameSub;
  Directory? _tmpFramesDir;
  int _frameCount = 0;
  DateTime? _startTime;

  bool get isRecording => _recording;

  MediaRecordingService(this._streamService);

  Future<bool> startRecording() async {
    if (_recording) return false;

    try {
      final tmpDir = await getTemporaryDirectory();
      final ts = DateTime.now().millisecondsSinceEpoch;
      _tmpFramesDir = Directory('${tmpDir.path}/ecorover_rec_$ts');
      await _tmpFramesDir!.create(recursive: true);
      _frameCount = 0;
      _startTime = DateTime.now();
      _recording = true;

      _frameSub = _streamService.frames.listen(
        (frame) async {
          if (!_recording) return;
          final filename =
              '${_tmpFramesDir!.path}/frame_${_frameCount.toString().padLeft(6, '0')}.jpg';
          await File(filename).writeAsBytes(frame);
          _frameCount++;
        },
        onError: (_) {},
      );

      return true;
    } catch (_) {
      _recording = false;
      return false;
    }
  }

  /// Returns the saved video filename, or null on failure
  Future<String?> stopRecording() async {
    if (!_recording) return null;

    _recording = false;
    await _frameSub?.cancel();
    _frameSub = null;

    if (_frameCount < 5 || _tmpFramesDir == null) {
      _cleanup();
      return null;
    }

    try {
      final now = DateTime.now();
      final ts =
          '${now.year}-${_p(now.month)}-${_p(now.day)}_${_p(now.hour)}-${_p(now.minute)}-${_p(now.second)}';
      final videoName = 'EcoRover_$ts.mp4';

      final tmpDir = await getTemporaryDirectory();
      final outputPath = '${tmpDir.path}/$videoName';

      // Calculate actual frame rate from recording duration
      final duration = DateTime.now().difference(_startTime!).inMilliseconds;
      final fps = (_frameCount / (duration / 1000.0)).clamp(5.0, 30.0);

      // Use ffmpeg to encode JPEG frames to MP4
      final framesPattern = '${_tmpFramesDir!.path}/frame_%06d.jpg';
      final cmd =
          '-framerate ${fps.toStringAsFixed(1)} -i "$framesPattern" -c:v libx264 -pix_fmt yuv420p -movflags +faststart "$outputPath"';

      final session = await FFmpegKit.execute(cmd);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        // Save to gallery
        await Gal.putVideo(outputPath, album: 'EcoRover');
        await File(outputPath).delete();
        _cleanup();
        return videoName;
      } else {
        _cleanup();
        return null;
      }
    } catch (_) {
      _cleanup();
      return null;
    }
  }

  void _cleanup() {
    try {
      _tmpFramesDir?.deleteSync(recursive: true);
    } catch (_) {}
    _tmpFramesDir = null;
    _frameCount = 0;
  }

  String _p(int n) => n.toString().padLeft(2, '0');

  Duration get recordingDuration {
    if (_startTime == null) return Duration.zero;
    return DateTime.now().difference(_startTime!);
  }
}
