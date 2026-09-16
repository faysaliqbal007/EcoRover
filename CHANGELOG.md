# Changelog

All notable changes to the **EcoRover** project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2026-09-16 (Stable Production Release / V6 Core Architecture)

### Added
- **ESP32-S3 Drivetrain Control**: 12-movement omnidirectional mecanum kinematics (Forward, Backward, Curve Left/Right, FAST Strafe Left/Right, Spin In-Place, Diagonals).
- **LEDC Hardware PWM**: Explicit non-conflicting timer channels (CH0-CH3 at 1500Hz for motors; CH4-CH5 at 50Hz for pan/tilt servos).
- **ESP32-CAM Independent Node**: Dedicated wireless video streaming node at static IP `192.168.4.200` broadcasting 640x480 MJPEG at `/stream`.
- **Flutter Mobile Application**:
  - Dark Cyberpunk Theme (Deep navy `#0B1E36`, Gold `#D4AF37`, Cyber Cyan `#00E5FF`).
  - Interactive 3x3 directional D-pad with latched touch and tactile feedback.
  - Pan & Tilt dual-axis servo sliders with +/- 5° nudge buttons.
  - 5-sensor live telemetry dashboard (Front/Rear ultrasonic, Right IR, LDR light level, Obstacle status).
  - Phone motion control streaming accelerometer vectors via UDP port 2055 at 33Hz with 50-sample tare calibration.
  - Fullscreen landscape camera HUD with telemetry overlay and 1.0x-3.0x zoom.
  - Native Android photo snapshot capture and H.264 MP4 video recording via FFmpeg Kit.
  - Fail-safe Emergency Stop floating button with pulsing animation.
- **Embedded Web Dashboard**: Self-hosted compressed GZIP byte dashboard (`dashboard_gz.h`) on port 80.
- **Automated Test Suite**: 44 comprehensive unit tests verifying data models, JSON deserialization, UDP packets, and API route generation.
- **Hardware Protection**: 5V to 3.3V voltage dividers on ultrasonic ECHO pins and isolated power rails with LM2596 buck converter.

### Fixed
- **Motor/Servo Jitter**: Removed third-party `ESP32Servo` library to eliminate timer overlap conflicts with motor PWM.
- **Rear Right Motor Reversal**: Locked authoritative mapping to `GPIO40` for `RR_IN2`.
- **Android HTTP Blocking**: Added `network_security_config.xml` to permit cleartext communication on private local IP subnet `192.168.4.*`.
- **SoftAP Stability**: Replaced dynamic sleep with deterministic cold-start sequence on Wi-Fi channel 1.
- **D-Pad Touch Latch**: Resolved multi-touch gesture collision where rapid taps caused orphaned drive states.
