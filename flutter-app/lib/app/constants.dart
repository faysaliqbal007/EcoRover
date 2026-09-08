// ============================================================
//  EcoRover App — Constants
// ============================================================

class EcoConstants {
  EcoConstants._();

  // Default network config (matches V6 firmware)
  static const String defaultControllerIp = '192.168.4.1';
  static const String defaultCameraIp = '192.168.4.200';
  static const int defaultUdpPort = 2055;

  static const String defaultControllerBase = 'http://$defaultControllerIp';
  static const String defaultCameraStream =
      'http://$defaultCameraIp/stream';

  // Status poll interval — matches V6 dashboard heartbeat
  static const int statusPollMs = 650;

  // Connection check timeout
  static const int connectionTimeoutMs = 3000;

  // Slider debounce (pan/tilt/speed)
  static const int sliderDebounceMs = 70;

  // Auto-retry interval when offline
  static const int retryIntervalMs = 2000;

  // Motion UDP send interval (~33 Hz)
  static const int motionUdpIntervalMs = 30;

  // Motion calibration sample count (matches firmware)
  static const int motionCalibrationSamples = 50;

  // Camera zoom
  static const double zoomMin = 1.0;
  static const double zoomMax = 3.0;
  static const double zoomStep = 0.1;

  // Default values (before first /api/status response)
  static const int defaultManualSpeed = 50;
  static const int defaultAutoSpeed = 50;
  static const int defaultMotionSensitivity = 50;
  static const int defaultPan = 90;
  static const int defaultTilt = 90;

  // Wi-Fi SSID (shown in offline panel — not used for auto-connect)
  static const String roverSsid = 'EcoRover';

  // App branding
  static const String appName = 'EcoRover';
  static const String appTagline = 'EXPLORE • BUILD • DISCOVER';

  // Media file prefixes
  static const String photoPrefix = 'EcoRover';
  static const String videoPrefix = 'EcoRover';

  // SharedPreferences keys
  static const String prefControllerIp = 'controller_ip';
  static const String prefCameraIp = 'camera_ip';
  static const String prefUdpPort = 'udp_port';
}
