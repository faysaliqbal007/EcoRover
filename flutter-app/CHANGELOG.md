# Changelog

All notable changes to the EcoRover project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [1.0.0] — 2026-09-22

### 🎉 Initial Release

#### Added — Manual Drive System
- 3×3 mecanum drive pad with latched directional buttons
- 12 movement directions (forward, backward, curve, strafe, spin, diagonals)
- FAST strafe buttons for rapid lateral movement
- Adjustable speed slider with live percentage readout
- Emergency stop floating action button with pulsing red gradient

#### Added — Autonomous Navigation
- One-tap autonomous obstacle avoidance mode
- Independent auto-speed slider
- Mode switching between IDLE, MANUAL, AUTO, and MOTION

#### Added — Phone Tilt Motion Control
- Accelerometer-based driving via phone tilt
- 3-second tare calibration with countdown animation
- Adjustable sensitivity slider with over-steer protection
- High-speed UDP streaming at 33Hz

#### Added — Live Camera & Media
- Real-time MJPEG stream with byte-level SOI/EOI parser
- Auto-reconnect on stream failure
- Interactive zoom (1.0x – 3.0x) with Fit/Fill toggle
- Landscape fullscreen mode with telemetry HUD overlay
- Photo capture — instant JPEG snapshot saved to gallery
- Video recording — FFmpeg H.264 encoding (MJPEG → MP4)

#### Added — Sensor Telemetry
- 5-sensor live dashboard (Front/Rear Ultrasonic, Right IR, LDR, Obstacle)
- Color-coded proximity alerts for obstacle detection
- 650ms heartbeat status polling

#### Added — Accessory Control
- RGB LED panel with 5 color presets and power toggle
- Headlight toggle with auto-mode (LDR-controlled)
- Buzzer toggle with confirmation beep feedback
- Accessory auto-lock during autonomous mode

#### Added — Camera Servo Turret
- Horizontal pan slider (0° – 180°) with ±5° nudge buttons
- Vertical tilt slider (0° – 180°) with step controls

#### Added — Settings & Diagnostics
- Configurable IP addresses for controller and camera
- Configurable UDP port
- Live packet counter for network diagnostics
- Persistent settings via SharedPreferences

#### Added — App Shell & Branding
- Custom EcoRover splash screen with fade-in logo animation
- Deep navy (#0B1E36) and gold (#D4AF37) color theme
- Official EcoRover mascot launcher icons
- Branded header widget across all screens

#### Added — Testing & Documentation
- 44 unit tests covering models, services, and API routes
- 55-step hardware testing verification checklist
- Complete V6 REST API specification document
