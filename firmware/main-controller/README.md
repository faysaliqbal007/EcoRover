# EcoRover ESP32-S3 Main Controller Firmware

## Architecture Overview
The main controller firmware runs on an **ESP32-S3 N16R8** dual-core microcontroller. It acts as the brain and network hub of the EcoRover, serving:
1. **Wi-Fi SoftAP**: Broadcasts the `EcoRover` network (`192.168.4.1`).
2. **Web Server & REST API**: Handles HTTP locomotion, pan/tilt servo angles, autonomous toggles, and sensor telemetry endpoints on Port 80.
3. **UDP Datagram Receiver**: Streams 3-axis accelerometer packets for phone-tilt motion driving on Port 2055.
4. **Mecanum Kinematics & LEDC PWM Engine**: 4 independent motor channels at 1500 Hz (8-bit) and 2 servo channels at 50 Hz (14-bit) without library conflicts.
5. **Sensor Acquisition Loop**: Front & rear HC-SR04 ultrasonics, right IR sensor, LDR ambient light, and SH1106 OLED status display.
6. **Embedded Web Dashboard**: Embedded compressed GZIP byte stream (`dashboard_gz.h`) served directly to any connected browser.

## File Manifest
- `EcoRover_V6.ino` : Core production Arduino sketch (Production Release v1.0.0 / V6 architecture).
- `dashboard_gz.h` : Pre-compiled gzip binary of the web dashboard interface.

## Arduino IDE Configuration
- **Board**: `ESP32S3 Dev Module`
- **CPU Frequency**: `240MHz (WiFi)`
- **Flash Mode**: `QIO 80MHz`
- **Flash Size**: `16MB (128Mb)`
- **Partition Scheme**: `16M Flash (3MB APP/9.9MB FATFS)` or `Default 4MB with spiffs`
- **PSRAM**: `OPI PSRAM`
- **USB Mode**: `Hardware CDC and JTAG`
- **Upload Mode**: `UART0 / Hardware CDC`

## Required Arduino Libraries
- `WiFi.h` (Built-in ESP32 core)
- `WebServer.h` (Built-in ESP32 core)
- `WiFiUdp.h` (Built-in ESP32 core)
- `Wire.h` (Built-in ESP32 core)
- `U8g2lib` (by olikraus - for SH1106 I2C OLED display)
- `esp32-hal-rgb-led.h` (Built-in ESP32 core - for on-board GPIO48 WS2812 RGB LED)

## Motor & Sensor Pin Configuration
```cpp
// Sensors & Actuators
#define LDR_PIN         4
#define HEADLIGHT_PIN   5
#define FRONT_TRIG      6
#define FRONT_ECHO      7
#define SDA_PIN         8
#define SCL_PIN         9
#define REAR_TRIG       10
#define REAR_ECHO       11
#define PAN_SERVO_PIN   12
#define TILT_SERVO_PIN  13
#define BUZZER_PIN      14
#define RIGHT_IR_PIN    15
#define RGB_PIN         48

// Verified Motors (L298N)
#define FL_IN1 17; #define FL_IN2 16; #define FL_EN 39
#define RL_IN1 18; #define RL_IN2 21; #define RL_EN 38
#define FR_IN1  1; #define FR_IN2  2; #define FR_EN 42
#define RR_IN1 41; #define RR_IN2 40; #define RR_EN 47
```
