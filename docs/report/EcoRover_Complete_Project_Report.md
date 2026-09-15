# ECOROVER: Comprehensive Engineering Project Report & System Architecture

**Sub-title**: ESP32-S3 Smart Rover with Wi-Fi Control, Autonomous Navigation, Phone Motion Control, ESP32-CAM Live Video, Sensor Dashboard and Flutter Application  
**Project Base**: EcoRover Master v1.0.0 (V6 Architecture)  
**Main Controller**: ESP32-S3 N16R8  
**Camera Node**: ESP32-CAM (Static IP: 192.168.4.200)  
**Control Network**: EcoRover Wi-Fi AP (192.168.4.1)  
**Authors & Contributors**:
- **Member 1**: M M Faysal Iqbal (Lead System Integration, Firmware & Mobile Architecture)
- **Member 2**: Ishraq Alam Khan (Power, Drivetrain, Kinematics & Manual Controls)
- **Member 3**: Nahid Hasan Nafi (Sensors, Display, Smart Systems & Documentation)

---

## 1. Project Summary and Objectives
EcoRover is a four-wheel smart mobile robot designed around an ESP32-S3 main controller. The rover combines manual Wi-Fi driving, mecanum-style movement, autonomous obstacle avoidance, phone motion control, camera pan/tilt, live video streaming, environmental sensing, automatic lighting, audible/visual warnings, and a Flutter mobile application. The final firmware acts as the central control layer while the ESP32-CAM operates as a separate wireless video node.

The project was developed iteratively: each subsystem was tested independently, stable GPIO and PWM assignments were locked, and only then were the systems merged.

### Main Project Objectives
1. Create a mobile rover that can be driven from a phone over a local Wi-Fi network without requiring internet access.
2. Provide multiple motion types: forward, backward, gentle left/right curves, spin, lateral FAST left/right, and four diagonal movements.
3. Provide pan and tilt camera control using two servos.
4. Provide front and rear ultrasonic sensing, right-side IR sensing, and ambient light sensing.
5. Implement autonomous free-space navigation using the available obstacle sensors.
6. Implement phone-tilt motion control using UDP accelerometer data with calibration and failsafe behavior.
7. Provide automatic obstacle warning using RGB and buzzer, plus LDR-based automatic headlights.
8. Expose all major control and status functions through a web API and a polished mobile dashboard.
9. Build a Flutter application that reproduces the dashboard experience and communicates with the same API.

---

## 2. System Architecture
The ESP32-S3 creates the local Wi-Fi access point named `EcoRover` and uses `192.168.4.1` as its fixed controller address. The ESP32-CAM joins the same network using the fixed address `192.168.4.200`. The phone communicates with the main controller by HTTP for commands and status, and by UDP port 2055 for motion-control accelerometer data. The camera stream is consumed independently from the ESP32-CAM MJPEG endpoint.

```
+-------------------------------------------------------------------+
|               Phone Client (Flutter Mobile Application)           |
+-------------------------------------------------------------------+
      | (HTTP Commands & Status)   | (UDP 2055 Accel)   | (MJPEG Stream)
      v                            v                    v
+-----------------------------+                  +------------------+
|   ESP32-S3 Main Controller  |                  |    ESP32-CAM     |
|   IP: 192.168.4.1           |                  |  IP: 192.168.4.200|
+-----------------------------+                  +------------------+
      |               |
      v               v
  [2x L298N]     [Sensors & Actuators]
  FL, RL, FR, RR  HC-SR04, IR, LDR, OLED, Servos, Buzzer, Headlights
```

---

## 3. Hardware & Power Architecture
- **12V High-Current Rail**: Supplies the 4x TT DC geared motors through 2x L298N dual H-bridge motor drivers.
- **5V Logic Rail**: Regulated by an LM2596 high-efficiency buck converter, delivering clean 5.0V to the ESP32-S3 `VIN`, ESP32-CAM, SG90 pan/tilt servos, and HC-SR04 ultrasonic sensors.
- **Common Ground**: Rigorously connects battery negative, buck converter ground, ESP32 ground, motor driver grounds, and sensor grounds.
- **5V to 3.3V Logic Protection**: 1kΩ / 2kΩ resistor voltage dividers protect ESP32 GPIO7 and GPIO11 from 5V ultrasonic ECHO pulses.

---

## 4. Drivetrain & Kinematics
Four mecanum wheels mounted with diagonal roller orientations allow 12 distinct locomotion movements:
- **Forward / Backward**: All wheels forward / reverse
- **Gentle Curves**: Left or right wheels scaled to 55% base speed
- **FAST Strafe Left**: `FL(-) RL(+) FR(+) RR(-)`
- **FAST Strafe Right**: `FL(+) RL(-) FR(-) RR(+)`
- **Spin Left / Spin Right**: Counter-rotation in place
- **Diagonals**: Single diagonal wheel pairs active

---

## 5. Development Roadmap & Team Contributions

### Overview Distribution Matrix
| Member | Primary Responsibility | Commits | Code Share |
|:---|:---|:---:|:---:|
| **M M Faysal Iqbal** | Lead System Integration, Mobile Shell, MJPEG & UDP | 18 | ~33.3% |
| **Ishraq Alam Khan** | Drivetrain, Kinematics, Power & Manual Locomotion | 18 | ~33.3% |
| **Nahid Hasan Nafi** | Autonomy, Sensor Fusion, Telemetry & Accessories | 18 | ~33.3% |
| **Total** | Full Multi-Subsystem Platform | **54** | **100.0%** |

### Five-Day Implementation Timeline
- **Day 1**: System architecture, power distribution, chassis mounting, and continuity verification.
- **Day 2**: Motor driver bring-up, explicit LEDC PWM allocation, pan/tilt servos, and sensor calibration.
- **Day 3**: Autonomous decision logic, ESP32-CAM static streaming, and responsive web dashboard.
- **Day 4**: Flutter mobile application, Riverpod state architecture, and UDP accelerometer streaming.
- **Day 5**: Regression testing, 44 unit tests, road tests, and full engineering documentation.
