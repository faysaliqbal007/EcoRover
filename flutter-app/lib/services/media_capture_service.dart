// ============================================================
//  EcoRover — Media Capture Service
//  Extracts latest JPEG frame from MJPEG stream and saves
//  to Android photo gallery
// ============================================================

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import '../services/mjpeg_stream_service.dart';

class MediaCaptureService {
  final MjpegStreamService _streamService;

  MediaCaptureService(this._streamService);


  Future<String?> capturePhoto() async {
    final frame = _streamService.latestFrame;
    if (frame == null || frame.isEmpty) {
      return null;
    }

    try {
      // Build timestamped filename
      final now = DateTime.now();
      final ts =
          '${now.year}-${_p(now.month)}-${_p(now.day)}_${_p(now.hour)}-${_p(now.minute)}-${_p(now.second)}';
      final filename = 'EcoRover_$ts.jpg';

      // Write to temp dir first
      final tmpDir = await getTemporaryDirectory();
      final tmpFile = File('${tmpDir.path}/$filename');
      await tmpFile.writeAsBytes(frame);

      // Save to gallery
      await Gal.putImage(tmpFile.path, album: 'EcoRover');

      // Clean up temp
      await tmpFile.delete();

      return filename;
    } catch (e) {
      return null;
    }
  }

  String _p(int n) => n.toString().padLeft(2, '0');
}
