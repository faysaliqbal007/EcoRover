<div align="center">

<img src="assets/images/ecorover_logo.png" alt="EcoRover Logo" width="180"/>

# 🤖 EcoRover

### Mecanum Wheel Robot Rover Controller

**EXPLORE • BUILD • DISCOVER**

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
[![ESP32](https://img.shields.io/badge/Hardware-ESP32-E7352C?logo=espressif&logoColor=white)](https://www.espressif.com)
[![License](https://img.shields.io/badge/License-Academic-blue)]()

---

*A feature-rich Android application for controlling an ESP32-powered mecanum-wheel robot rover with real-time camera streaming, autonomous navigation, phone-tilt motion control, and telemetry monitoring.*

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Screenshots](#-screenshots)
- [System Architecture](#-system-architecture)
- [Project Structure](#-project-structure)
- [Tech Stack](#-tech-stack)
- [Hardware Requirements](#-hardware-requirements)
- [Getting Started](#-getting-started)
- [Configuration](#-configuration)
- [API Reference](#-api-reference)
- [Testing](#-testing)
- [Contributors](#-contributors)

---

## 🔍 Overview

EcoRover is a **Flutter-based Android controller application** designed for a 4-wheel mecanum robot rover built on the **ESP32 microcontroller** platform. The robot features omnidirectional movement, an onboard ESP32-CAM for live video streaming, ultrasonic and IR sensors for obstacle detection, and servo-controlled camera pan/tilt turret.

The app communicates with the rover over a **Wi-Fi Access Point** hosted by the ESP32, using:
- **HTTP REST API** — for drive commands, servo control, and sensor status
- **UDP Datagrams** — for real-time phone accelerometer tilt data (33Hz)
- **MJPEG Stream** — for live camera feed from the ESP32-CAM module

---

## ✨ Features

### 🕹️ Manual Drive Control
- **3×3 Mecanum D-Pad** with latched directional buttons (tap once to drive, tap again to stop)
- **12 movement directions** — forward, backward, curve, strafe, spin, and all 4 diagonals
- **FAST Strafe** buttons for rapid lateral movement
- **Adjustable speed slider** with live percentage readout
- **Emergency Stop** floating action button with pulsing red gradient

### 🧭 Autonomous Navigation
- **One-tap autonomous mode** with obstacle avoidance
- **Independent auto-speed slider** separate from manual speed
- Automatic switching between IDLE, MANUAL, AUTO, and MOTION modes

### 📱 Phone Tilt Motion Control
- **Accelerometer-based driving** — tilt your phone to steer the rover
- **3-second tare calibration** with countdown animation
- **Adjustable sensitivity slider** with over-steer protection
- **High-speed UDP streaming** at 33Hz for responsive control

### 📷 Live Camera & Media
- **Real-time MJPEG stream** with custom byte-level SOI/EOI parser
- **LIVE badge indicator** with auto-reconnect on stream failure
- **Interactive zoom** (1.0x – 3.0x) with Fit/Fill toggle
- **Landscape fullscreen mode** with telemetry HUD overlay
- **Photo capture** — instant JPEG snapshot saved to gallery
- **Video recording** — FFmpeg H.264 encoding pipeline (MJPEG → MP4)
- **Recording timer** and file size indicator

### 📊 Live Sensor Telemetry
- **5-sensor dashboard** — Front Ultrasonic, Rear Ultrasonic, Right IR, LDR, Obstacle Status
- **Color-coded proximity alerts** — values turn red within danger threshold
- Real-time data refreshed via 650ms heartbeat polling

### 💡 Accessory Control
- **RGB LED** panel with 5 color presets (Red, Green, Blue, Yellow, White) and power toggle
- **Headlight** toggle with auto-mode (LDR-controlled)
- **Buzzer** toggle with confirmation beep feedback
- **Accessory auto-lock** during autonomous mode

### 🎨 Camera Servo Turret
- **Horizontal Pan** slider (0° – 180°) with ±5° nudge buttons
- **Vertical Tilt** slider (0° – 180°) with step controls

### ⚙️ Settings & Diagnostics
- **Configurable IP addresses** for controller and camera modules
- **Configurable UDP port** for motion data
- **Live UDP packet counter** for network diagnostics
- **Persistent settings** via SharedPreferences

---

## 🏛️ System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        ANDROID DEVICE                               │
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────────┐ │
│  │  Manual Page  │  │  Smart Page   │  │      Camera View          │ │
│  │  (Drive Pad)  │  │ (Auto/Motion) │  │   (MJPEG + Record)       │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────────┘ │
│         │                 │                       │                 │
│  ┌──────┴─────────────────┴───────────────────────┴───────────────┐ │
│  │                  Riverpod State Management                      │ │
│  │  ┌────────────┐ ┌────────────┐ ┌──────────┐ ┌──────────────┐  │ │
│  │  │RoverProvider│ │MotionProv. │ │CameraProv│ │SettingsProv. │  │ │
│  │  └─────┬──────┘ └─────┬──────┘ └────┬─────┘ └──────────────┘  │ │
│  └────────┼──────────────┼─────────────┼──────────────────────────┘ │
│           │              │             │                            │
│  ┌────────┴──────┐ ┌─────┴─────┐ ┌────┴──────────┐                │
│  │ HTTP API Svc  │ │ UDP Svc   │ │ MJPEG Parser  │                │
│  │ (Drive,Servo) │ │ (x,y,z)  │ │ (SOI/EOI)     │                │
│  └────────┬──────┘ └─────┬─────┘ └────┬──────────┘                │
└───────────┼──────────────┼─────────────┼────────────────────────────┘
            │   Wi-Fi AP   │             │
            │  Connection  │             │
┌───────────┼──────────────┼─────────────┼────────────────────────────┐
│           ▼              ▼             ▼            ESP32 ROVER     │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │              EcoRover V6 Firmware (Arduino C++)                │ │
│  │                                                                │ │
│  │  HTTP Server ◄──────  UDP Listener ◄──────  ESP32-CAM         │ │
│  │  (Port 80)            (Port 2055)            (MJPEG Stream)   │ │
│  │       │                    │                       │           │ │
│  │  ┌────┴────┐  ┌───────────┴──────┐  ┌────────────┴────────┐  │ │
│  │  │ Motors  │  │   Sensors        │  │    Accessories       │  │ │
│  │  │ 4x DC   │  │ 2x Ultrasonic   │  │ RGB LED, Buzzer     │  │ │
│  │  │ Mecanum │  │ 1x IR, 1x LDR   │  │ Headlight, Servos   │  │ │
│  │  └─────────┘  └──────────────────┘  └─────────────────────┘  │ │
│  └────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Project Structure

```
ecorover_app/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── app/
│   │   ├── ecorover_app.dart              # MaterialApp with Riverpod
│   │   ├── theme.dart                     # Color palette, typography, shadows
│   │   └── constants.dart                 # IPs, ports, intervals, defaults
│   ├── models/
│   │   ├── rover_mode.dart                # RoverMode & DriveCommand enums
│   │   └── rover_status.dart              # JSON model with sensor parsing
│   ├── services/
│   │   ├── rover_api_service.dart         # HTTP REST client (drive, servo, accessories)
│   │   ├── mjpeg_stream_service.dart      # MJPEG byte-stream parser (SOI/EOI)
│   │   ├── motion_sensor_service.dart     # Phone accelerometer listener
│   │   ├── motion_udp_service.dart        # UDP socket for tilt data (33Hz)
│   │   ├── media_capture_service.dart     # Photo snapshot to gallery
│   │   └── media_recording_service.dart   # FFmpeg MJPEG→MP4 encoder
│   ├── providers/
│   │   ├── rover_provider.dart            # Status heartbeat polling (650ms)
│   │   ├── camera_provider.dart           # Stream state & auto-reconnect
│   │   ├── motion_provider.dart           # Tilt calibration & sensitivity
│   │   └── settings_provider.dart         # Persistent IP/port config
│   ├── screens/
│   │   ├── splash_screen.dart             # Animated launch screen
│   │   ├── controller_screen.dart         # Main tab controller (Manual/Smart)
│   │   ├── fullscreen_camera_screen.dart  # Landscape camera + HUD overlay
│   │   └── settings_screen.dart           # IP config & packet diagnostics
│   └── widgets/
│       ├── ecorover_header.dart           # Branded logo header
│       ├── camera_card.dart               # Live stream viewport + controls
│       ├── control_header.dart            # Mode selector & status badge
│       ├── common/
│       │   ├── emergency_stop_button.dart # Red gradient E-Stop FAB
│       │   └── offline_panel.dart         # Connection retry panel
│       ├── manual/
│       │   ├── drive_pad.dart             # 3×3 mecanum D-pad with latch
│       │   ├── pan_control.dart           # Horizontal servo slider
│       │   └── tilt_control.dart          # Vertical servo + speed slider
│       └── smart/
│           ├── autonomous_card.dart       # Auto-nav toggle + speed
│           ├── sensor_dashboard.dart      # 5-sensor live telemetry
│           ├── motion_card.dart           # Tilt control + tare calibration
│           ├── rgb_card.dart              # 5-color LED swatch picker
│           └── additional_options.dart    # Buzzer, headlight, clients
├── assets/
│   └── images/
│       ├── ecorover_logo.png              # App branding logo
│       ├── ecorover_brand.png             # Splash screen image
│       └── ecorover_app_icon.png          # Launcher icon source
├── android/                               # Android native config
├── test/
│   └── widget_test.dart                   # 44 unit tests
├── docs/
│   ├── API.md                             # V6 REST API specification
│   └── TESTING.md                         # 55-step hardware test checklist
├── pubspec.yaml                           # Dependencies & assets
├── CONTRIBUTIONS.txt                      # Team commit breakdown
└── README.md                              # This file
```

---

## 🛠️ Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Framework** | Flutter 3.47.5 | Cross-platform UI toolkit |
| **Language** | Dart 3.3+ | App logic and data models |
| **State Management** | Riverpod 2.5 | Reactive state with providers |
| **Networking** | `http` package | HTTP REST API calls |
| **Streaming** | Raw `HttpClient` | MJPEG byte-stream parsing |
| **UDP** | `dart:io RawDatagramSocket` | Motion tilt data at 33Hz |
| **Video Encoding** | FFmpeg Kit | MJPEG → H.264 MP4 conversion |
| **Sensors** | `sensors_plus` | Phone accelerometer access |
| **Persistence** | SharedPreferences | IP/port settings storage |
| **Gallery** | `gal` | Save photos & videos to gallery |
| **Permissions** | `permission_handler` | Storage & sensor permissions |
| **Screen** | `wakelock_plus` | Keep screen awake during control |

---

## 🔧 Hardware Requirements

| Component | Specification |
|-----------|--------------|
| **Microcontroller** | ESP32 (Wi-Fi AP mode) |
| **Camera** | ESP32-CAM module (MJPEG streaming) |
| **Drive Motors** | 4× DC motors with mecanum wheels |
| **Motor Driver** | L298N or equivalent H-bridge |
| **Ultrasonic Sensors** | 2× HC-SR04 (Front + Rear) |
| **IR Sensor** | 1× Right-side obstacle detection |
| **LDR Sensor** | 1× Ambient light detection |
| **Servos** | 2× SG90 (Pan + Tilt turret) |
| **RGB LED** | 1× Common cathode RGB LED |
| **Buzzer** | 1× Active buzzer |
| **Headlight** | 1× White LED |
| **Power** | 7.4V – 12V LiPo battery pack |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.47.5 or later ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Android SDK** API 24+ (Android 7.0 Nougat or higher)
- **Android Studio** or **VS Code** with Flutter extension
- An Android phone or emulator (physical device recommended for Wi-Fi + sensors)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<YOUR_USERNAME>/ecorover.git
   cd ecorover
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on a connected device:**
   ```bash
   flutter run
   ```

4. **Build a release APK:**
   ```bash
   flutter build apk --release
   ```
   The APK will be at `build/app/outputs/flutter-apk/app-release.apk`

### Connecting to the Rover

1. Power on the EcoRover hardware
2. On your Android phone, go to **Wi-Fi Settings**
3. Connect to the `EcoRover` Wi-Fi network (password set in ESP32 firmware)
4. Open the EcoRover app — it will auto-connect to `192.168.4.1`

---

## ⚙️ Configuration

Default network settings (configurable in the app's Settings screen):

| Parameter | Default Value | Description |
|-----------|--------------|-------------|
| Controller IP | `192.168.4.1` | ESP32 main controller |
| Camera IP | `192.168.4.200` | ESP32-CAM module |
| UDP Port | `2055` | Motion tilt data port |
| Status Poll | `650ms` | Heartbeat interval |
| Motion Rate | `33Hz` | Accelerometer UDP rate |

> These defaults match the EcoRover V6 firmware configuration. If you modify the firmware, update the corresponding values in the app's Settings screen.

---

## 📖 API Reference

Full REST API documentation is available at **[docs/API.md](docs/API.md)**.

Quick reference of key endpoints:

| Category | Endpoint | Description |
|----------|----------|-------------|
| Status | `GET /api/status` | Full rover state JSON |
| Drive | `GET /api/manual/forward` | Latched forward drive |
| Auto | `GET /api/auto/start` | Start autonomous mode |
| Servo | `GET /api/pan?angle=90` | Set camera pan angle |
| RGB | `GET /api/rgb/color?name=blue` | Set LED color |
| Emergency | `GET /api/emergency` | Full emergency stop |

---

## 🧪 Testing

### Unit Tests

```bash
flutter test
```

The test suite contains **44 unit tests** covering:
- `RoverStatus` JSON parsing and null-safety fallbacks
- `DriveCommand` and `RoverMode` enum mappings
- Ultrasonic no-echo edge cases
- Obstacle danger threshold calculations
- API URL construction for all 12 drive directions
- UDP packet format validation
- Motion calibration sample counting

### Hardware Testing

A comprehensive **55-step hardware verification checklist** is available at **[docs/TESTING.md](docs/TESTING.md)** covering:
- Wi-Fi connectivity and network discovery
- All 12 mecanum movement directions
- Servo pan/tilt range verification
- Camera stream stability and reconnection
- Photo capture and video recording
- Sensor reading accuracy
- Accessory toggle verification

---

## 👥 Contributors

| Member | Role | Domain |
|--------|------|--------|
| **Member A** | Manual Locomotion & Design System | Drive controls, servos, theme, API docs |
| **Member B** | Autonomy, Motion & Telemetry | Sensors, UDP, accelerometer, tests |
| **Member C** | Camera, Media & Android Native | MJPEG streaming, video recording, app shell |

See [CONTRIBUTIONS.txt](CONTRIBUTIONS.txt) for detailed per-member file assignments and commit breakdown.

---

## 📄 License

This project is developed as an academic group project. All rights reserved by the contributors.

---

<div align="center">

**Built with ❤️ using Flutter & ESP32**

*EcoRover — EXPLORE • BUILD • DISCOVER*

</div>
