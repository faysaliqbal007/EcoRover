# EcoRover Engineering Troubleshooting Guide

This guide documents the 15 critical hardware, firmware, and mobile challenges encountered throughout the development of EcoRover and their definitive resolutions.

---

### 1. Board Overheating & 12V Inductive Damage
- **Symptom**: ESP32-S3 becoming dangerously warm; risk of brownout or regulator destruction.
- **Root Cause**: Accidental coupling between the 12V motor supply rail and the 3.3V/5V logic inputs.
- **Solution**: Completely physically separated the 12V motor supply from the logic rail. Installed an LM2596 high-efficiency buck converter dialed to exactly 5.0V with a digital multimeter. Enforced a single, solid Common Ground connecting battery negative, buck converter ground, ESP32 ground, and L298N grounds.

---

### 2. Left Motor Driver Failure (0V Output)
- **Symptom**: Left motor driver showed power LED illuminated and 12V at inputs, but output measured 0V across both motor terminals.
- **Root Cause**: The illuminated board LED only verifies logic VCC, not H-bridge power or PWM switching. Input direction logic and Enable jumpers were misconfigured.
- **Solution**: Bench-tested each motor channel independently. Verified PWM on pins `GPIO39` and `GPIO38` using an oscilloscope before re-coupling the drivetrain.

---

### 3. Motor & Servo PWM Conflicts
- **Symptom**: Motors froze or jittered uncontrollably as soon as pan/tilt servos were moved.
- **Root Cause**: The Arduino `ESP32Servo` library dynamically hijacked hardware timer channels that overlapped with the motor driver LEDC channels.
- **Solution**: Removed `ESP32Servo` entirely. Implemented explicit ESP32 LEDC hardware channels:
  - Motors: `CH0` (FL), `CH1` (RL), `CH2` (FR), `CH3` (RR) at 1500 Hz (8-bit).
  - Servos: `CH4` (Pan), `CH5` (Tilt) at 50 Hz (14-bit).

---

### 4. Motor Direction Pin Drift Across Revisions
- **Symptom**: Rear Right wheel spinning in reverse during forward commands.
- **Root Cause**: Older experimental pin mappings (`RR_IN2 = GPIO21`) were mistakenly merged over the final verified mapping.
- **Solution**: Locked the single authoritative pin map: `RR_IN1 = GPIO41`, `RR_IN2 = GPIO40`, and `RR_EN = GPIO47`.

---

### 5. Wi-Fi SoftAP Disappearing on Firmware Update
- **Symptom**: `EcoRover` Wi-Fi network failed to appear on phones after cold reboot.
- **Root Cause**: ESP32 Wi-Fi hardware state retained lingering sleep flags and channel conflicts.
- **Solution**: Implemented a deterministic cold-start sequence in setup:
  ```cpp
  WiFi.mode(WIFI_OFF); delay(100);
  WiFi.mode(WIFI_AP);
  WiFi.setSleep(false);
  WiFi.softAPConfig(AP_IP, AP_GATEWAY, AP_SUBNET);
  WiFi.softAP(WIFI_SSID, WIFI_PASSWORD, 1, 0, 4); // Channel 1, max 4 clients
  ```

---

### 6. C++ Compile Errors from Large Web Dashboard Code
- **Symptom**: Arduino IDE threw errors like `"function does not name a type"`.
- **Root Cause**: Embedding thousands of lines of raw HTML/JS inside C++ multi-line string literals caused quotation and escape character conflicts.
- **Solution**: Extracted HTML/JS into separate files and converted the production web dashboard into a compressed gzip hex array (`dashboard_gz.h`).

---

### 7. Responsive Dashboard Overflow & Stale Labels
- **Symptom**: Vertical tilt slider overflowing mobile screens; stale "Manual" label remaining in Smart mode.
- **Root Cause**: Missing CSS viewport bounds and state logic driven by assumption rather than live telemetry.
- **Solution**: Refactored CSS with flexbox bounds and icon-only toolbars. UI labels are strictly bound to `/api/status` state.

---

### 8. Accessory State Conflicts with Autonomous Modes
- **Symptom**: Manual RGB or buzzer toggles interfering with automatic obstacle alerts.
- **Root Cause**: Shared output pins lacked clear state ownership.
- **Solution**: Mode isolation: Autonomous and Motion modes take absolute ownership of headlights, RGB, and buzzer. Manual accessory switches are locked until returning to Idle or Manual mode.

---

### 9. LDR Ambient Lighting Hysteresis
- **Symptom**: Headlights flickering rapidly at threshold lighting.
- **Root Cause**: No time delay or deadband between light and dark ADC thresholds.
- **Solution**: Added temporal hysteresis: Dark (`ADC <= 100`) for 3 consecutive seconds turns lights ON; Bright (`ADC >= 250`) for 1 consecutive second turns them OFF.

---

### 10. ESP32-CAM Re-flashing & Freeze Strategy
- **Symptom**: Re-flashing camera firmware frequently caused frame buffer instability and connection drops.
- **Root Cause**: Camera sensor GC2145 is sensitive to clock timing and memory fragmentation.
- **Solution**: Froze the working ESP32-CAM firmware at static IP `192.168.4.200`. Kept photo capture, video recording, zoom, and HUD overlay on the Flutter client side.

---

### 11. Phone Motion Neutral Calibration
- **Symptom**: Rover drove immediately upon activating Motion mode due to natural handheld tilt.
- **Root Cause**: Lack of initial tare calibration.
- **Solution**: The ESP32-S3 averages the first 50 incoming UDP accelerometer packets to compute neutral $X_0, Y_0$ offsets. Movement triggers only when tilt exceeds the calibrated deadband. Added a 700 ms packet timeout failsafe.

---

### 12. Mecanum FAST Strafe Yaw
- **Symptom**: Pure lateral strafing caused slight rotational drift.
- **Root Cause**: Mechanical weight distribution and TT motor RPM variance.
- **Solution**: Verified kinematics (`- + + -` for Left, `+ - - +` for Right). Added software motor compensation for rear wheel RPM.

---

### 13. Android Cleartext HTTP & Local Wi-Fi Integration
- **Symptom**: Android blocked HTTP requests to `192.168.4.1` with `ERR_CLEARTEXT_NOT_PERMITTED` and dropped connection because Wi-Fi had no internet.
- **Root Cause**: Android 9+ enforces HTTPS and network switching by default.
- **Solution**: Configured `network_security_config.xml` to permit cleartext traffic to `192.168.4.*` and bound network sockets to the active Wi-Fi interface.

---

### 14. Phone-Side MP4 Recording from MJPEG
- **Symptom**: ESP32-CAM cannot encode MP4 files or store them on local flash.
- **Root Cause**: Lack of onboard H.264 encoder hardware on ESP32-CAM.
- **Solution**: Integrated `ffmpeg_kit_flutter_new` in Flutter to capture incoming JPEG frames and transcode them locally into standard 1080p H.264 MP4 videos saved to the Android photo gallery.

---

### 15. Independent Multi-Node Health Monitoring
- **Symptom**: Camera stream disconnected, causing the entire UI to report "Rover Offline".
- **Root Cause**: Conflating main controller health with camera node health.
- **Solution**: Decoupled network health in Flutter: `RoverStatusNotifier` monitors `192.168.4.1` while `CameraNotifier` independently monitors `192.168.4.200/stream` with dedicated auto-reconnect timers.
